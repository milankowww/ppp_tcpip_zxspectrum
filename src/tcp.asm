;
;;
;; TCP
;;
;;
	.area 	TCP (REL)
	.radix d

; konstanta pre konektnuty TCP socket
TCP_MAGIC1 == 0b00000001
; konstanta pre cakajuci TCP socket
TCP_MAGIC2 == 0b00000011

.include "config.h"

; hl -> ip, de -> tcp paket, bc=iphsiz
iphsiz:
	.dw 0
ippktip:
	.dw 0

tcp_parser::
.if CONF_TCP
	ld (ippktip),hl
	push hl
	push de
	pop ix
	ld (iphsiz),bc
	ld bc, #12
	add hl, bc
	ld bc, #TCP_SOCKS
tcp_next:
	ld a,(bc)
	rrca 		;Je to socket ? 0. bit
	jr c, tcp_sock_ok
	ld a, c
tcp_end:
	add #16
	ld c, a
	jr nc, tcp_next
;Presli sme vsetko a nic nesedelo - posli icmp port unreachable
; SEM TREBA VRAZIT CELY TEN KOD NA TEST "FIN"u !!! WWW
	pop hl
	push hl
.if 0
	ld de, #2
	ex de, hl
	add hl, de
.else
	ld d, h
	ld e, l
	inc hl
	inc hl
.endif
	ld b, (hl)
	inc hl
	ld c, (hl)

	ld hl, #12
	add hl, de
	ex de, hl

	ld a, #ICMP_DEST_UNREACH
	ex af, af'
	ld a, #ICMP_PORT_UNREACH

	call snd_icmp
	pop hl
	jp ppp_discard

tcp_sock_ok:
	push hl 
	inc c
	rrca
	jp nc,conect_sock	; skok, ak sa jedna o otvoreny socket
	bit 1,13(ix) 		; SYN flag
	jr z,notfound_tcpip
.if DEBUGTCP
	push af
	push bc
	push de
	push hl
	ld h,#TCP_SOCKSHI
	ld a,c
	and #0xf0
	ld l,a
	ld de,#16
	call hex_dump
	inc h
	ld de,#16
	call hex_dump
	pop hl
	pop de
	pop bc
	pop af
.endif
	push de
	inc de
	inc de	;DE -> DEST PORT
	ex de,hl
	call test_ip2
.if 0
	jr z,port_pass
	ex de,hl
	pop de
	jp notfound_tcpip
.else
	ex de,hl
	pop de
	jp nz,notfound_tcpip
.endif
;; tato rutinka musi pripravit data pre neskorsi connect()
port_pass::
;de -> tcp packet
;hl -> ip hfr ip adr
;bc -> sock+2
;zasobnik:
;->ip hdr ip adr
;->ip hdr
	inc bc		; bc -> limit for buffer
	ld a,(bc)
	ld e,a
	inc bc
	ld a,(bc)
	ld d,a
	push bc
.if 0
	ld bc,#15	; test ci sa don zmesti 15 bytes (chyba? WWW)
.else
	ld bc,#17	; test ci sa don zmesti 15 bytes + 2 bytes dlzky
.endif
	ex de,hl
	sbc hl,bc
	pop bc
	jr c,connflood 
	ld a,h		; ulozime novy limit buffra
	ld (bc),a
	dec bc
	ld a,l
	ld (bc),a
	inc bc
	inc bc
	ld a,(bc)
	ld l,a
	inc bc
	ld a,(bc)
	ld h,a		; hl -> buffer
.if 0
	ld (hl),#1
	inc hl
.endif
	ld (hl),#15	; dlzka dat, ktore tam ukladame (17 bajtov?! WWW)
	inc hl
	xor a
	ld (hl),a
	inc hl

	ld (hl),#TCP_MAGIC1 ; prvy ukladany bajt buduceho socketu.
	inc hl
	ex de,hl
	push bc
	ldi		; toto by mala byt remote IP
	ldi
	ldi
	ldi
	push ix		; toto by mali byt porty
	pop hl
	ld bc,#8	; ale tomuto NEROZUMIEM (WWW)
	ldir
	ld (de),a	; strnasty
	inc de
	ld (de),a
	inc de
	ld (de),a
	inc de
	ld (de),a
.if 1			; FIX toho, comu nerozumiem vyssie.
	dec de
	dec de
.endif

.if 0
	push bc
	push de
	push hl

	push de
	pop hl
	ld de,#16
	sbc hl,de
	call hex_dump

	pop hl
	pop de
	pop bc
.endif
	pop hl	; byvale BC, ukazuje do socketu, z ktoreho sme acceptli,
		; na pointer na buffer
	ld (hl),d
	dec hl
	ld (hl),e	; posunieme ho
	ld a,l
	and #0xf0
	ld l,a
	set 6,(hl)	; nastavime "na socket prisiel paket"
	ld hl,#nr_fds
	inc (hl)
connflood: ;bufer prilis maly na connecty
	pop hl
	pop hl
	jp ppp_discard

notfound_tcpip2:
	ex de,hl
	pop de
notfound_tcpip::
	pop hl
	ld a,c
	and #0xf0
	jp tcp_end

; tato rutinka musi ulozit data pre uz otvorene spojenie
conect_sock:
;de -> tcp packet
;hl -> ip hfr ip adr
;bc -> sock+1
;zasobnik:
;->ip adr in ip hdr
;-> ip hdr
	push de
	call test_ip 
	ex de,hl
	jr nz,notfound_tcpip2
	inc bc
	call test_ip
	jr nz, notfound_tcpip2 ;Po testoch na adr a porty. 
	inc hl
	ld a,c
	and #0xf0
	ld c,a
	inc b
;hl -> tcp packet+4
;de -> ip hfr ip adr+3
;bc -> sock banka 2 (mozno zle)
;zasobnik:
;->tcp packet
;->ip adr in ip hdr
;-> ip hdr
;RECEIVE - Ak SEQ = ako v sockete, prijmeme data, posunieme zaciatok a zmensime limit
;	 - Ak ACK = ako v sockete, nastavime bit v sockete
	push hl
	push bc
	call test_ip 	;Test SEQ.
	jr nz,badseq
	ld hl,(ippktip)
	inc hl
	inc hl
	ld a,(hl)
	inc hl
	ld l,(hl)
	ld h,a		;hl ->dlzka packetu
	ld de,(iphsiz)	
	sbc hl,de
	ld a,12(ix)
	and #0xf0
	rrca
	rrca
	ld e,a
	ld d,#0
	sbc hl,de	;hl dlzka dat v packete
	jr z,badseq
	push ix 
	pop de
	ex de,hl
	add hl,de	;hl data v tcp packete
			;de dlzka dat
	push hl
	push de
	inc bc
	inc bc
	inc bc
	inc bc
	inc bc
	inc bc
	dec b		; prechod do banky 1
	ld a,(bc)
	ld l,a
	inc bc
	ld a,(bc)
	ld h,a
	sbc hl,de
	ld a,h
	ld (bc),a
	dec bc
	ld a,l
	ld (bc),a
	inc bc
	inc bc
	ld a,(bc)
	ld e,a
	inc bc
	ld a,(bc)
	ld d,a
	ld a,c
	pop bc
	pop hl
	push bc
	ldir
	ld l,a
	ld h,#TCP_SOCKSHI
	ld (hl),d
	dec hl
	ld (hl),e
	and #0xf0
	ld l,a
	set 6,(hl)
	inc h
	pop bc
	inc l
	inc l
	ld d,(hl)
	inc hl
	ld e,(hl)
	ex de,hl
	add hl,bc
	ex de,hl
	ld (hl),e
	dec hl
	ld (hl),d
	dec hl
	ld a,(hl)
	adc a,#0
	ld (hl),a
	inc hl
	ld a,(hl)
	adc a,#0
	ld (hl),a

	ld hl,#nr_fds
	inc (hl)
; poslanie ACK po prijati dat
.if 0
	ld a,l
	and #0xf0
	ld de,#0
	call snd_tcp
.endif


badseq:
	pop hl
	pop bc


	bit 4,13(ix) 	;Test na to, ci je platny ACK
	jr z,badack

	inc bc
	inc bc
	inc bc
	inc bc
	inc hl
	inc hl
	inc hl
	inc hl
.if 1	;Vypise ocakavane a prijate ACK
	call debug

	push de
	push hl
	push bc
	ld de,#4
	call hex_dump
	pop hl
	push hl
	ld de,#4
	call hex_dump
	pop bc
	pop hl
	pop de
.endif
	call test_ip
	jr nz,badack
;	dec h	; do prvej banky
	ld h,#TCP_SOCKSHI
	ld a,l
	and #0xf0
	ld l,a
	set 3,(hl)	;Nastav, ze ack je spravne
	bit 5,(hl)	;Test ci sa ma vratit select pri spravnom ACK
	jr z,noincnrfds
	res 5,(hl)
	ld hl,#nr_fds
	inc (hl)
noincnrfds:
badack:
	bit 0,13(ix)	;Je tam FIN ???
;XX
.if 1
	jr z,tcp_nofin
	ld l,a
	ld h,#TCP_SOCKSHI
	push hl
	inc hl
	inc hl
	inc hl

	inc (hl)
	jr nc,snd_fin_ack
	dec hl
	inc (hl)
	jr nc,snd_fin_ack
	dec hl
	inc (hl)
	jr nc,snd_fin_ack
	dec hl
	inc (hl)
snd_fin_ack:
	ld de,#0
	call snd_tcp

	push af
	ld a, #1
	out (254), a
	pop af

	pop hl
	set 2,(hl)	;Error on socket
	ld hl,#nr_fds
	inc (hl)
.endif
tcp_nofin:
	pop hl
	pop hl

	pop hl ; !!! masiarska praca, nevieme o com !!!

	jp ppp_discard

.else

;Testy na spojene sockety
;;;;;;;;;;;;;;;;
;; no tcp now ;;
;;;;;;;;;;;;;;;;
	push hl
.if 0
	ld de, #2
	ex de, hl
	add hl, de
.else
	ld d, h
	ld e, l
	inc hl
	inc hl
.endif
	ld b, (hl)
	inc hl
	ld c, (hl)

	ld hl, #12
	add hl, de
	ex de, hl

	ld a, #ICMP_DEST_UNREACH
	ex af, af'
	ld a, #ICMP_PORT_UNREACH

	call snd_icmp
	pop hl
	jp ppp_discard
.endif

idle_sock:	.db	#0
tcp_sock:	.db	#0

tcp_hdr::
tch_srcport::	.dw	#0x0000
tch_dstport::	.dw	#0x0000
tch_seq::	.dw	#0x0000, #0x0000
tch_ack::	.dw	#0x0000, #0x0000
tch_hdrsz::	.db	#0x50
tch_flags::	.db	#0b00010000	; ACK
tch_window::	.dw	#0x0000
tch_chksm::	.dw	#0x0000
tch_urgptr::	.dw	#0x0000
TCPHLEN	== . - tcp_hdr

pseudo:
	.dw	#0, #0, #0, #0, #0, #0
PSEUDOLEN	= . - pseudo
pseudo2:
	.dw	#0
PSEUDO2LEN	= . - pseudo

; hl -> data
; de = size
; a =? tcp socket
snd_tcp::
	ld (tcp_sock), a
	push bc
	push de
	push hl
	
	ld b, d
	inc b
	ld d, #0

	ld a, e
	and a
	jr nz, frg_lp1
	ld a, b
	dec a
	jr z, frg_lp1
	inc d
	dec b

frg_lp1:
	push bc
	push de
	push hl
	call snd_tcp_fragment
	pop hl
	pop de
	add hl, de
.if 1	;Ak bola chyba, dalej nic neposielame
	ld a,(tcp_sock)
	ld e,a
	ld d,#TCP_SOCKSHI
	ld a,(de)
	bit 2,a
	jr z,frg_lp1_cnt
	pop bc
	jr frg_lp1_end
.endif
frg_lp1_cnt:
	ld de, #256
	pop bc
	djnz frg_lp1
frg_lp1_end:
	pop hl
	pop de
	pop bc
	ret

stor1:	.dw	#0x0000	; adresa tcp dat na poslanie
stor2:	.dw	#0x0000	; dlzka dat
chksm_storage:
	.dw	#0x0000
fcs_storage:
	.dw	#0x0000
	
snd_tcp_fragment:
	ld (stor1), hl
	ld (stor2), de
	call trash_idle_open
resend:
	ld a,(tch_flags)
	bit 1,a
	jr z,nodec
	ld a,(tcp_sock)
	add #7
	ld l,a
	ld h,#TCP_SOCKSHI+1
	dec (hl)
	
nodec:
	ld hl, (stor1)
	ld de, (stor2)
	call snd_tcp_packet
	ld a, (tcp_sock)
	add #7
	ld h, #TCP_SOCKSHI+1
	ld l, a
	ld a, (stor2)
	add (hl)
	ld (hl), a
	dec hl
	ld a, (stor2 + 1)
	adc a, (hl)
	ld (hl), a
	dec hl
	ld a, #0
	adc a, (hl)
	ld (hl), a
	dec hl
	ld a, #0
	adc a, (hl)
	ld (hl), a
	ld a,(tch_flags)
	and #3
	jr z,noinc
	ld a,(tcp_sock)
	add #7
	ld l,a
	inc (hl)
	jr nc,noinc
	dec hl
	inc (hl)
	jr nc,noinc
	dec hl
	inc (hl)
	jr nc,noinc
	dec hl
	inc (hl)
noinc:	
wait:
	ld a, (idle_sock)
	call trash_fdset
	ld a, (tcp_sock)
	ld l,a
	ld h,#TCP_SOCKSHI
	set 5,(hl)
	call tcp_fdset
	call select
	ld a, (idle_sock)
	call trash_fdisset
	jr nz, resend
       	ld a, (tcp_sock)
	ld h, #TCP_SOCKSHI
	ld l, a
.if 1	;ak prislo FIN, alebo ina chyba, dalej nic neposielaj
	bit 2, (hl)
	jr nz, back
.endif
	bit 3, (hl)
	jr nz, back
	ld a, (tcp_sock)
	add #7
	ld h, #TCP_SOCKS+1
	ld l, a
	ld a, (stor2)
	and a
	sbc (hl)
	ld (hl), a
	dec hl
	ld a, (stor2 + 1)
	sbc a, (hl)
	ld (hl), a
	dec hl
	ld a, #0
	sbc a, (hl)
	ld (hl), a
	dec hl
	ld a, #0
	sbc a, (hl)
	ld (hl), a
	jp resend
back:
	ret

snd_tcp_packet:			; dlzka moze byt 0
	push hl	; adresa
	push de	; dlzka dat

;; informacia "WWW" pri odoslani TCP fragmentu
.if 0
	push de
	push af
	ld a, #'W
	call print64
	ld a, #'W
	call print64
	ld a, #'W
	call print64
	pop af
	pop de
.endif

	ld hl, #TCPHLEN
	add hl, de
	; v hl mame celkovu dlzku aj s tcp hlavickou, treba ju niekam nieco
	ld a, h
	ld (pseudo2), a
	ld a, l
	ld (pseudo2+1), a

	push hl	; celkova dlzka aj s tcp hlavickou
	ld h, #TCP_SOCKSHI
	ld a,(tcp_sock)
	add #5+2
	ld l, a	; hl->"remote" port
	ld de, #tch_srcport

	ldi
	ldi
	dec hl
	dec hl
	dec hl
	dec hl	; hl->"source" port
	ldi
	ldi
	; len pre Tvoju informaciu: de -> tch_seq
	inc h
	ld a, (tcp_sock)
	add #4
	ld l, a
	ldi
	ldi
	ldi
	ldi
	ld a, (tcp_sock)
	ld l, a
	ldi
	ldi
	ldi
	ldi

	; preskocime dlzku tcp hlavicky
	inc de
	; a flagy
	inc de

	dec h
	ld a, (tcp_sock)
	add #10
	ld l, a; hl -> koniec limitu pre buffer v host order
	ld a, (hl)
	ld (de), a
	dec hl
	inc de
	ld a, (hl)
	ld (de),a
	inc de

	xor a
	ld (de), a	; checksum na 0
	inc de
	ld (de), a
	ld d, #TCP_SOCKSHI
	ld a, (tcp_sock)
	inc a
	ld e, a		; de -> ip addr, kam posielame

	ld a, #IP_TCP
	pop bc		; dlzka dat aj s tcp hlavickou
	call prep_ip		; fyzicky posle IP hlavicku, ba co viac,
				; spravi nam to v nej POLOZKY na pseudohdr :)

	ld (fcs_storage), bc	; PPP checksum

	ld hl, #ih_ttl
	ld de, #pseudo
	ld bc, #PSEUDOLEN
	ldir

	ld hl, #pseudo
	xor a
	ld (hl), a
	inc hl
	inc hl
	ld (hl), a
	inc hl
	ld (hl), a
	ld de, #tcp_hdr
	ld hl, #tch_chksm
	ld bc, #TCPHLEN + PSEUDO2LEN
	call chksm

	ld (chksm_storage), de

	pop de		; dlzka dat
	pop hl		; adresa dat
	push hl
	push de
	ld a, d
	or e
	ld a, #2
	jr z, wokolo1
	inc a	; nevypise ani zaver
	push af

	; teraz potrebujeme zapocitat aj data
	ld b, d
	ld c, e
	ld d, h
	ld e, l
	ld hl, #0 ; miesto pre vysledok
	call chksm

	and a
	ld hl, (chksm_storage)
	adc hl, de
	jr c, skip3
	ld a, l
	inc a
	jr nz, skip4
	ld a, h
	inc a
	jr nz, skip4
skip3:
	inc hl
skip4:
	ld a, l
	ld (tch_chksm), a
	ld a, h
	ld (tch_chksm + 1), a
	pop af
wokolo1:
	push af
	ld hl, #tcp_hdr
	ld de, #TCPHLEN
	ld bc, (fcs_storage)
	call bufput
	pop af
	pop de
	pop hl
	rrca
	ret nc
	ccf
	rla
	call bufput
	ret

; vypis TCP hlavicky v tvare &DATA&
.if 0
kwak::
	push bc
	push de
	push hl
	push af
	ld a, #'&
	call print64
	ld hl, #tcp_hdr
	ld de, #TCPHLEN
	call hex_dump
	ld a, #'&
	call print64
	pop af
	pop hl
	pop de
	pop bc
	ret
; vypis socketu na ktory posielam v tvare SDATAS
kwak2::
	push bc
	push de
	push hl
	push af
	ld a, #'S
	call print64
	ld h, #TCP_SOCKSHI+1
	ld a,(tcp_sock)
	ld l, a
	ld de, #16
	call hex_dump
	ld a, #'S
	call print64
	pop af
	pop hl
	pop de
	pop bc
	ret
.endif
