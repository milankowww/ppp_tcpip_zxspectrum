;
;;
;; ICMP layer
;;
;;
	.area 	ICMPLAYER (REL)
	.radix d

.include "config.h"

; vstup: hl -> ip header
icmp_reply::
	; hl zaciatok IP
	; de zaciatok dat
	; bc dlzka hlavicky (naco?)

	ld a, (de)
	cp #ICMP_ECHO
	jr z, icmp_echo_reply

	jp ppp_discard

icmp_echo_reply:
	push de
	ex de, hl
	ld (hl), #ICMP_ECHOREPLY
.if 0
	inc hl
	inc hl
	ld b, (hl)
	inc hl
	ld c, (hl)
	push hl
	ld hl, #0x800
	add hl, bc
	ld b, h
	ld c, l
	pop hl
	ld (hl), c
	dec hl
	ld (hl), b

.else
	push de
	ld d, h
	ld e, l
	inc hl
	inc hl
	ld bc, (in_ip_datalen)
	call chksm
	pop de
.endif
	pop hl
	push de ; ip header
	push hl ; icmp header
	ld hl, #12
	add hl, de ; -> src ip prijateho
	ex de, hl
	pop hl ; icmp header
	ld bc, (in_ip_datalen)
	ld a, #IP_ICMP
; de -> ip kam poslat
; hl -> icmp_header
; bc = in_ip_datalen
; a = typ paketu (1)
	call snd_ip
	pop hl
	jp ppp_discard

icmp_hdr::
ich_type::	.db	#0x00
ich_code::	.db	#0x00
ich_chksm::	.dw	#0x0000
ich_param::	.dw	#0x0000, #0x0000

ICMPHLEN = . - icmp_hdr

snd_pushed1:	.dw	#0x0000
snd_pushed2:	.dw	#0x0000


; A = typ ICMP spravy
; A' = code
; BC = dlzka dat za ICMP hlavickou
; DE -> ip_addr
; HL -> data
; ich_param, ak ho aplikacia potrebuje, sa nastavuje a
;            maze rucne

snd_icmp::
	ld (ich_code), a
	ex af, af'
	ld (ich_type), a
	ld a, b
	or c
.if 1
	dec a
	sbc a, a
	and #1
.else
	ld a, #0
	jr z, skip1
	inc a
skip1:
.endif
	ld (#snd_pushed1),bc
	push bc
	push af
	push hl
	ld a, #IP_ICMP
	ld hl, #ICMPHLEN
	add hl, bc
	ld b, h
	ld c, l
	push af
	call prep_ip	; toto fyzicky posle len IP hlavis~ku
	pop af
	push bc
	ld de, #icmp_hdr
	ld hl, #ich_chksm
	ld bc, #ICMPHLEN
	call chksm
	pop bc
	jr nz,skip2 
	pop hl
	push hl
	push de
	push bc
	ex de,hl
	ld hl,#0
	ld bc,(#snd_pushed1)
	call chksm
	pop bc
	pop hl
	and a
	adc hl,de
	jr c,skip3
	ld a,l
	inc a
	jr nz,skip4
	ld a,h
	inc a
	jr nz,skip4
skip3:
	inc hl
skip4:
	ld a,l
	ld (#ich_chksm),a
	ld a,h
	ld (#ich_chksm+1),a
skip2:
	pop hl
	pop af
	push af
	push hl
	xor #3
	ld hl, #icmp_hdr
	ld de, #ICMPHLEN
	call bufput

	pop hl
	pop af
	pop de
	ret nz
	or #2
	jp bufput

