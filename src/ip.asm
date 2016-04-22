;
;;
;; IP layer
;;
;;
	.area 	IPLAYER (REL)
	.radix d

.include "config.h"

other_ip::
	.db	0,0,0,0

; [flag] [addr][control] [proto][wtl=msb proto] [... data ip paketu ...] [fc|fc]
;          ~~~~~~ len	  ^ A			^HL

iphdr:
	.dw	0

;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ifconfig jak hovaaado ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;
ipv4head::

ih_vers::
	.db	#0x45			; version		const
ih_service::
	.db	#0x00			; type of service	const
ih_totlen::
	.dw	#0x0000			; total length
ih_ident::
	.dw	#0x4757			; identification	raz pre 1 paket
ih_fragoff::
	.dw	#0x0000			; flags + frag_offset	const
ih_ttl::
	.db	#255			; TTL			const
ih_proto::
	.db	#0x00			; protocol
ih_chksm::
	.dw	#0x0000			; header checksum

ih_ourip::
;	.db	#194,#1,#133,#126	; source IP addr	v podst const
	.db	#195,#146,#18,#246	; source IP addr	v podst const
ih_dstip::
	.db	#194,#1,#133,#125	; dest IP addr

IPHLEN = . - ipv4head

; rutina: snd_ip
; vstup:
;	hl -> data
;	de -> ip_addr
;	bc = len
;	a = proto
; vystup:
;	zatial len boh vie.. snad puhy reset bez znicenia uly..

snd_ip::
	push hl
	push bc
	call prep_ip
	pop de
	pop hl
	ld a, #2
	jp bufput

prep_ip::
	ld hl, #IPHLEN
	add hl, bc
	ld b, h
	ld c, l
	ld hl, #ih_totlen
	ld (hl), b
	inc hl
	ld (hl), c
	ld hl, #ih_ident+1
	inc (hl)
	inc hl
	inc hl
	inc hl
	inc hl
	ld (hl), a
	ld bc, #7
	add hl, bc
	ex de, hl
	ld bc, #4
	ldir

	ld bc, #IPHLEN
	ld de, #ipv4head
	ld hl, #ih_chksm
	call chksm

	ld de, #IPHLEN
	ld hl, #ipv4head
.if DBGSEND
	call hex_dump
.endif
	ld a, #1
	jp bufput


in_ip_datalen::
	.dw	0

rcv_ip::
;receive ip packetu
;Vstup  : HL - adresa ip packetu
;Vystup : - Ak moze urobi discard packetu
;Meni   : IX,HL,DE,AF

.if	CHECK_IPv4_TYPE
	ld	a, (hl)
	and	#0xf0
	cp	#0x40
	jp	nz, ppp_discard
.endif

	ld a, (hl)
	and #0x0f
	add a
	add a
	ld c, a
	xor a
	ld b,a ; bc = ihl

	push hl	; ip header
	inc hl
	inc hl
	ld a, (hl)
	inc hl
	ld l, (hl)
	ld h, a		; v hl celkova dlzka
	pop de		; v de zac. ip
			; v bc dlzka hlav

	push hl
	sbc hl, bc
	ld (in_ip_datalen), hl
	pop hl	; celk dlzka

	ex de, hl	; hl=zac ip, de=celk dlzka

	push hl
	add hl, bc	; hl = hlavicka subprotokolu
	ex de, hl
	pop hl		; hl = zac ip

	; hl zaciatok IP
	; de zaciatok dat
	; bc dlzka hlavicky (naco? pre ICMPcka!)

	push hl
	push hl
	pop ix
	ld a,9(ix)
	pop hl

	cp #IP_ICMP 
	jp z,icmp_reply
	cp #IP_UDP
	jp z, udp_parser
	cp #IP_TCP
	jp z, tcp_parser
	jp ppp_discard

