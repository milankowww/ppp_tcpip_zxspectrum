;
;;
;; TOOLS
;;
;;
	.area 	TOOLS (REL)
	.radix d

.include "config.h"

test_ip::
	ld a, (bc)
	cp (hl)
	ret nz
	inc hl
	inc bc
	ld a, (bc)
	cp (hl)
	ret nz
	inc hl
	inc bc
test_ip2::
	ld a, (bc)
	cp (hl)
	ret nz
	inc hl
	inc bc
	ld a, (bc)
	cp (hl)
	ret

; a = filedescr
; vystup : HL -> data packetu
;	   DE = dlzka
udp_d_adr:
	.dw	0
udp_d_lim:
	.dw	0
tcp_data_first::	
	push af
	ld h,#TCP_SOCKSHI
	jr data_f2
udp_data_first::	
	push af
	ld h,#UDP_SOCKSHI
data_f2:
	ld l,a
	bit 1,(hl)
	jr z,data_f1
.if 1 ; TU BOLA VELKA CHYBA (snad). WWW.

	sub #6
data_f1:
	add #9
	
.else
	add #9
data_f1:
	sub #6
.endif

data_first:
	ld l,a		; hl nam teraz ukazuje na {UDP,TCP} limit for buffer
	ld e,(hl)
	inc hl
	ld d,(hl)
	inc hl
	ld (#udp_d_lim),de
	
	ld a,(hl)	; hl nam ukazuje na {UDP,TCP} pointer to buffer
	inc hl
	ld h,(hl)
	add #11
	ld l,a		; hl = buffer+11
	ld a,(hl)
	inc hl
	ld h,(hl)
	ld l,a		; hl = pointer to future buffer?
	ld (#udp_d_adr),hl
	ld e,(hl)
	inc hl
	ld d,(hl)
	inc hl
	dec de
	dec de
	pop af
	ret

tcp_data_next::
udp_data_next::
; vystup : HL -> data packetu
;	   DE = dlzka
;	   ZF Ak uz nie su data
	ld hl,(#udp_d_adr)
	ld e,(hl)
	inc hl
	ld d,(hl)
	add hl,de
	dec hl
	push hl
	ld de,(#udp_d_lim)
	sbc hl,de
	pop hl
	ret z
	ld e,(hl)
	inc hl
	ld d,(hl)
	inc hl
	dec de
	dec de
	ret
; findfreesock
; vstup: nastavene H
; vracia L cislo volneho socketu, CY ak chyba
; ine nemeni
ffsock:
	push af
	xor a
ffsock_next:
	ld l, a
	bit 0, (hl)
	jr z, ffsock_found
	add #16
	jr nc, ffsock_next
	pop af
	scf
	ret
ffsock_found:
	pop af
	and a
	ret
flsock:
	push af
	ld a, #0xf0
flsock_next:
	ld l, a
	bit 0, (hl)
	jr z, ffsock_found
	sub #16
	jr nc, flsock_next
	pop af
	scf
	ret

; vstup: hl -> data o sockete, 16 bytes. Prvy byte moze byt UDP_MAGIC1
; vystup: hl += 16, CY ak chyba
udp_socket::
	push bc
	push de
	ex de,hl
	ld h,#UDP_SOCKSHI
	call ffsock
	jr c, udp_s_end
	ld a, l
	ex de,hl
	ld bc, #16
	ldir
udp_s_end:
	pop de
	pop bc
	ret

; vstup: hl -> data v pasivnom sockete o sockete
;	 de -> data pre socket, ktore sa doplnia, kde je uz vyplnena adresa bufru, limit, a adresa pre reinicializaciu
; vystup: CY ak chyba
udp_accept::
	push bc
	push hl
	push de
	ld bc,#9
	ldir
	ld h,#UDP_SOCKSHI
	call ffsock
	jr c, udp_a_end
	pop de
	push de
	ld a, l
	ex de,hl
	ld bc, #16
	ldir
udp_a_end:
	pop de
	pop hl
	pop bc
	ret

; vstup: hl -> pripraveny socket, prvy byte moze byt UDP_MAGIC2
; vystup: hl += 16, up: hl += 16, carry ak chyba
tcp_listen::
	push bc
	push de
	ex de, hl
	ld h, #TCP_SOCKSHI
	jr listen
	
; vstup: hl -> pripraveny socket, prvy byte moze byt UDP_MAGIC2
; vystup: hl += 16, up: hl += 16, carry ak chyba
udp_listen::
	push bc
	push de
	ex de, hl
	ld h, #UDP_SOCKSHI
listen:
	call flsock
	jr c, udp_l_end
	ld a, l
	ex de, hl
	ld bc, #16
	ldir
udp_l_end:
	pop de
	pop bc
	ret



; vystup: none
tcp_fdzero::
	push af
	push hl
	ld h, #TCP_SOCKSHI
	jr fdzero

; a = filedescr
; vystup: none
udp_fdzero::
	push af
	push hl
	ld h, #UDP_SOCKSHI
	ld l, a
fdzero:
	xor a
udp_fdz_loop:
	ld l, a
	res 7, (hl)
	add #16
	jr nz, udp_fdz_loop
	pop hl
	pop af
	ret

; a = filedescr
; vystup: none
tcp_fdset::
	push hl
	ld h, #TCP_SOCKSHI
	jr fdset
; a = filedescr
; vystup: none
udp_fdset::
	push hl
	ld h, #UDP_SOCKSHI
fdset:
	ld l, a
	set 7, (hl)
	pop hl
	ret

; a = filedescr
; vystup: ZERO ak nic, NZ ak nejake data su
tcp_fdisset::
	push hl
	ld h, #TCP_SOCKSHI
	jr isset
; a = filedescr
; vystup: ZERO ak nic, NZ ak nejake data su
udp_fdisset::
	push hl
	ld h, #UDP_SOCKSHI
isset:
	ld l, a
	bit 6, (hl)
	pop hl
	ret


; a = filedescr
; vystup: none
tcp_fdreset::
	push hl
	push de
	push bc
	push af
	ld l,a
	ld h,#TCP_SOCKSHI
	bit 1,(hl)
	ld d,h
	jr nz,fdreset
	add #9
	ld l,a
	ld c,(hl)
	inc l
	ld b,(hl)
	inc l
	ld e,(hl)
	inc l
	ld d,(hl)
	inc h
	ld (hl),d
	dec l
	ld (hl),e
	dec l
	ld (hl),b
	dec l
	ld (hl),c
	pop af
	pop bc
	pop de
	pop hl
	ret
udp_fdreset::
	push hl
	push de
	push bc
	push af
	ld d, #UDP_SOCKSHI
fdreset:
	add #13
	ld e, a
	ld a,(de)
	ld l,a
	inc de
	ld a,(de)
	ld h,a

	ld a,e
	and #0xf0
	ld e,a

	ld bc, #16

	ldir

	pop af
	pop bc
	pop de
	pop hl
	ret

; a = filedescr
; vystup: none
tcp_close::
	push af
	push hl
	ld hl,#tch_flags
	set 0,(hl)
	ld de,#0
	call snd_tcp
		ld a,#'A
		call print64
	ld hl,#tch_flags
	res 0,(hl)
	pop af
	ld h, #TCP_SOCKSHI
	jr close
; a = filedescr
; vystup: none
udp_close::
	push hl
	ld h, #UDP_SOCKSHI
close:
	ld l, a
	ld (hl), #0
	pop hl
	ret

; vstup: hl -> data v pasivnom sockete o sockete
;	 de -> buffer for data
;	 bc -> limit for data
; vystup: CY ak chyba
;	  Vsetko meni
.if DEBUGTCP
tcp_accept_txt:
	.asciz "TCP_ACCPET OK"
.endif

tcp_accept::
	push de
	push bc
	push hl
	ld h,#TCP_SOCKSHI
	call ffsock
	jr c, tcp_a_end
	ex de,hl
	pop hl
	ld bc,#9

.if DEBUGTCP
	push hl
	push de
	push bc
	ld hl,#tcp_accept_txt
	call WriteStr
	pop bc
	pop de
	pop hl
	call debug
.endif

	ldir
	ex de,hl
	pop bc
	ld (hl),c
	inc h
	ld (hl),c
	inc l
	ld (hl),b
	dec h
	ld (hl),b
	pop bc
	inc l
	ld (hl),c
	inc h
	ld (hl),c
	inc l
	ld (hl),b
	dec h
	ld (hl),b
	inc h
	dec hl
	dec hl
	dec hl
	dec hl
	dec hl
	ld a,#1
	ld (hl),a
	dec hl
	xor a
	ld (hl),a
	dec hl
	ld (hl),a
	dec hl
	ld (hl),a
	dec hl
	inc de
	inc de
	inc de
	ld a,(de)
	dec de
	inc a
	ld (hl),a
	dec hl
	ld a,(de)
	dec de
	adc a,#0
	ld (hl),a
	dec hl
	ld a,(de)
	dec de
	adc a,#0
	ld (hl),a
	dec hl
	ld a,(de)
	adc a,#0
	ld (hl),a
	dec h
	ld a,l
	and #0xf0
	push af
	ld hl,#tch_flags
	set 1,(hl)
	ld de,#0
	call snd_tcp
	ld hl,#tch_flags
	res 1,(hl)
	pop af
	jr tcp_a_end2

tcp_a_end:
	pop de
	pop hl
	pop bc
tcp_a_end2:
	ret
