;
;;
;; UDP
;;
;;
	.area 	UDP (REL)
	.radix d

.include "config.h"

; hl -> ip, de -> udp paket, bc=iphsiz

udp_parser::
.if CONF_UDP
	push hl
	ld bc, #12
	add hl, bc
	ld bc, #UDP_SOCKS
udp_next:
	ld a,(bc)
	rrca 		;Je to socket ? 0. bit
	jr c, sock_ok
	ld a, c
udp_end:
	add #16
	ld c, a
	jr nc, udp_next
;Presli sme vsetko a nic nesedelo - posli icmp port unreachable
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

sock_ok:
	push hl
	inc bc
	rrca
	jp nc,active_sock

.if CONFIG_PASSIVE_UDP
;Testovanie na pasivny socket
;hl -> source IP
;bc -> source port
;de -> udp packet 
;Stack:
;-> source IP
;-> IP packet
	push de
	inc de
	inc de	;DE -> DEST PORT
	ex de,hl
	call test_ip2
	jr z,pass
	ex de,hl
	pop de
	jp notfound_ip

pass:
	inc bc
	push de ;->source IP
	inc hl
	ld d,(hl)
	inc hl
	ld e,(hl)  ;de - dlzka packetu
	dec de
	dec de
	dec de
	dec de
	dec de
	dec de
	dec de
	dec de
	push de
;Zasobnik
;dlzka packetu
;->Source IP
;->zaciatok udp
;-> source IP
;-> IP packet
	ld a,(bc)
	ld l,a
	inc bc
	ld a, (bc)
	ld h,a
	ld de,#18
	sbc hl,de
	pop de
	jr c,ToSmalb
;Zasobnik
;->Source IP
;->zaciatok udp
;-> source IP
;-> IP packet
	sbc hl,de
	jr c,ToSmalb2
	dec bc
	ld a,l
	ld (bc),a
	ld a,h
	inc bc
	ld (bc),a
	inc bc
	ld hl,#18
	add hl,de
	push de		;dlzka 
;Zasobnik
;dlzka packetu
;->Source IP
;->zaciatok udp
;-> source IP
;-> IP packet
	ld a,(bc)
	ld e,a
	inc bc
	ld a,(bc)
	ld d,a
	ld a,l
	ld (de),a
	inc de
	ld a,h
	ld (de),a ;
	inc de		;de -> zapisanie socketua  dat
	ld a, #1
	ld (de),a
	ld a,c
	pop bc
	pop hl
;Zasobnik
;->zaciatok udp
;-> source IP
;-> IP packet
	inc de
	push bc
	ld bc, #4
	ldir
	pop bc
	pop hl
	push bc
	ld bc, #4
	ldir
	ld bc, #4
	add hl,bc
	inc de
	inc de
	inc de
	inc de
	inc de
	inc de
	inc de
	pop bc
	ldir
;Zasobnik
;-> source IP
;-> IP packet
	ld l,a
	ld h,#UDP_SOCKSHI
	ld (hl),d
	dec hl
	ld (hl),e
	and #0xf0
	ld l,a
	set 6,(hl)
	ld hl,#nr_fds
	inc (hl)
	pop hl
	pop hl
	jp ppp_discard
	
;Nezmesti sa ani udaj pre vytvorenie socketu
ToSmalb:
;
;	pop hl
;	pop hl
;	pop hl
;	pop hl
;	jp ppp_discard

ToSmalb2::
;Nezmesti sa cely packet
;Zasobnik
;->Source IP
;->zaciatok udp+1
;-> source IP
;-> IP packet
	pop hl
	pop hl
	pop hl
	pop hl
	jp ppp_discard

.endif

active_sock:
	call test_ip
	;jr nz,notfound_ip
	jp nz,notfound_ip
	push de
	ex de,hl
	inc bc
	call test_ip
	jr z,acts1
	ex de,hl
	pop de
	jr notfound_ip
acts1:
	inc sp
	inc sp
;bc - > dest port+1 v sock tbl
;hl - > dest port+1 v udp hlavicke
;de - > my ip -1 v ip hl.
;Vsetko sedi v packete a na zasobniku je zaciatok ip hlavicky
.if 0
	push hl
	ld h, b
	ld l, c
	pop bc
.endif
.if 0
	inc bc
	ld a,(bc)
	inc bc
	ld d,a
	ld a,(bc)
	dec bc
	ld e,a 		;de = dlzka packetu	ALEBO 2 ci kolko
.else
	inc hl
	ld a,(hl)
	inc hl
	ld d,a
	ld a,(hl)
	dec hl
	ld e,a

	dec hl	; bonus
	inc bc	; bonus 2

.endif
	inc de
	inc de
	inc hl
	ld a,(hl)
	push hl
	inc hl
;zasobnik z vrvhu 
;*dlzka udp
;ip hdrer ip addr+3
;ip headr
	ld h,(hl)
	ld l,a		;hl = max dlzka
	sbc hl,de
	jr c,toobig
	ld a,l
	ld (bc),a
	inc bc
	ld a,h
	ld (bc),a
	inc bc
	pop hl
	push bc		;na zasobnik adresu do sock tb na adr buf
;de = dlzka packetu+2
;bc ->adresa s adresou bufru 
;hl -> udp len
	push de
	ld de,#4
	add hl,de	;HL - >UDP data
	ld a,(bc)
	ld e,a
	inc bc
	ld a,(bc)
	ld d,a
	pop bc

;potrebujem - 	de ->kam
;		bc = dlzka+2
;		hl ->udpdata
	dec bc
	dec bc

.if 1
	dec bc
	dec bc
	dec bc
	dec bc
	dec bc
	dec bc
.endif

movedata:
	ld a,c
	ld (de),a
	inc de
	ld a,b
	ld (de),a
	inc de
	or c
	jr z,no_data
with_data:
	ldir
no_data:
	pop bc
	ld a,l
	ld (bc),a
	inc bc
	ld a,h
	ld (bc),a
	ld hl,#nr_fds
	inc (hl)
	pop hl		;hl -> adresa  na source ip
	pop hl		;hl adresa packetu
	ld a,c
	and #0xf0
	ld c,a
	ld a,(bc)
	or #0x40	;Zapis ze tam daco je
	ld (bc),a
	jp ppp_discard

	
toobig:
;zasobnik:
;*dlzka udp
;ip hdrer ip addr+3
;ip headr
;bc ->dlzka v sock tb

	pop hl		;hl -> v udp len
	ld de,#4
	add hl,de
	ld a,(bc)
	ld e,a
	xor a
	ld (bc),a
	inc bc
	ld a,(bc)
	ld d,a
	push bc		;adressa v sock tb limit+1
	dec de
	dec de
	push de		;dlzka
	xor a
	ld (bc),a
	inc bc
	ld a,(bc)
	ld e,a
	inc bc
	ld a,(bc)
	ld d,a
	pop bc
.if 0
	ld a,c
	ld (de),a
	inc de
	ld a,b
	ld (de),a
	inc de
	or c
	jr nz,with_data
	jr no_data
.else
	jr movedata
.endif
	

notfound_ip::
	pop hl
	ld a, c
	and #0xf0
	jp udp_end
	
.else
;;;;;;;;;;;;;;;;
;; no udp now ;;
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


;hl -> udp socket
;de -> data
;bc =  size
udp_hdr::
udh_srcport::	.dw	#0x0000
udh_dstport::	.dw	#0x0000
udh_len::	.dw	#0x0000
udh_chksm::	.dw	#0x0000

UDPHLEN == . - udp_hdr

; toto su vstupne params nasej rutiny
; a = socket
; hl -> data
; de = dlzka

; toto je format filedesc entry
; flags
; ip
; src port
; dst port

snd_udp::
.if 0	;DEBUG>1
	call debug
.endif
	push hl
	push de
	ld hl, #UDPHLEN
	add hl, de

	ld d, #UDP_SOCKSHI
	ld e, a

	ld a, h
	ld (udh_len), a
	ld a, l
	ld (udh_len+1), a

	ld b, h
	ld c, l

	inc de

	; bc = sizeof (ippaket)
	; de -> ip addr
	ld a, #IP_UDP
	push de
	call prep_ip	; fyzicky posle von IP hlavicku
	pop de
	inc de
	inc de
	inc de
	inc de
	ld hl, #udh_dstport
	ld a, (de)	; Toto tu cele je picowina na kolieskax (Glip)
			; ale len na takych malych (WWW)
	ld (hl), a
	inc hl
	inc de
	ld a, (de)
	ld (hl), a
	inc de
	dec hl
	dec hl
	dec hl
	ld a, (de)
	ld (hl), a
	inc hl
	inc de
	ld a, (de)
	ld (hl), a
	ld a, #0b0000011	; nenapis uvod ani zaver
	ld hl, #udp_hdr
	ld de, #UDPHLEN
	call bufput
	ld a, #0b0000010	; nevypise uvod
	pop de
	pop hl
.if 0	;DEBUG>1
	call bufput
	call debug
	ret
.else
	jp bufput
.endif

udp_idle::
	ret

; konstanta pre konektnuty UDP socket
UDP_MAGIC1 == 0b00000001
; konstanta pre cakajuci UDP socket
UDP_MAGIC2 == 0b00000011

