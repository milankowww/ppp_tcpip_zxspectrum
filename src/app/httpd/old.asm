;
;;
;; prva ukazkova aplikacia, zatial pisana s tym nespravnym h-ckom.
;; to vsetko treba este doriesit.
;;
	.area 	APPLICATION (REL)
	.radix d

.include "config.h"

bufforaccept:		;Nekorektne
mojbuf:
	.ds	1024 + 1024

tcp_acc:
	.ds 	1024
soktcp:
	.db	#0
sndbuf:
	.ascii 'Pokus '

SNDBUF_LEN	= . - sndbuf
	
tcp_in:
	.db	#TCP_MAGIC2	;socket for akcept
	.dw	#0x0700
	.dw	#1024
	.dw	#tcp_acc
	.dw	#0,0,0
	.dw	#tcp_in
	.db	#0

datulienka:
	.db #'A, #'B, #'C, #'D

soket0:
	.db	#0
soket1:
	.db	#0
soketidle:
	.db	#0
initstr:
	.asciz 	'PPP was succesfuly initialized'

appmain::
	exx
	push hl
	exx

	call select	; to wait for network init
	ld hl,#initstr
	call WriteStr

	ld hl, #tabulka
	call udp_socket
	jp c, finish
	ld (soket0), a

	call udp_listen
	jp c, finish
	ld (soket1), a

	call trash_idle_open
	ld (soketidle), a
.if CONF_TCP
	ld hl,#tcp_in
	call tcp_listen
	jp c, finish
	ld (soktcp),a
.endif

loadnext:
	xor a
	in a, (#254)
	or #0b11100000
	inc a
	jp nz, finish

	call udp_fdzero
.if CONF_TCP
	call tcp_fdzero
	
.endif
	call trash_fdzero

	ld a, (soket1)
	call udp_fdset

	ld a, (soketidle)
	call trash_fdset

	ld a, (soket0)
	call udp_fdset

	ld hl, #datulienka
	ld de, #4
	;call snd_udp
.if CONF_TCP
	ld a,(soktcp)
	call tcp_fdset
.endif

	call select
.if 0
	ld hl, #mojbuf
	ld de, #10
	call hex_dump
.endif

	ld a, (soket0)
	call udp_fdisset
	jr z, pozrinext1

	ld hl, #mojbuf
	ld c, (hl)
	inc hl
	ld b, (hl)
	inc hl
	ld a, b
	or c
	jr z, loadnext
	dec bc
	dec bc
lp1:
	ld a, (hl)
	push hl
	push bc
	call print64
	pop bc
	pop hl
	inc hl
	dec bc
	ld a, b
	or c
	jr nz, lp1

	ld a, (soket0)
	call udp_fdreset

pozrinext1:
	ld a, (soket1)
	call udp_fdisset
	jr z, pozrinext2
.if 0

	call udp_data_first
pozrinxtlp:
	push de
	ld de,#dataforaccept
	call udp_accept
	pop de
	push af
	ld bc,#16
	add hl,bc
	ex de,hl
	sbc hl,bc
	ex de,hl
	call snd_udp
	pop af
	call udp_close
	ld a,#'J
	call print64
	call udp_data_next
	jr nz,pozrinxtlp
	ld a, (soket1)
	call udp_fdreset
.else
	ld hl,#mojbuf+1024+2
	ld de,#dataforaccept
	call udp_accept
	push af
	ld hl,(mojbuf+1024)
	ld de,#18
	sbc hl,de
	ex de,hl
	ld hl,#mojbuf+1024+18
	call snd_udp
	pop af
	call udp_close
	ld a, (soket1)
	call udp_fdreset
.endif

pozrinext2:
	ld a, (soketidle)
	call trash_fdisset
	jr z, pozrinext3
	ld a, #'I
	call print64
	ld a, (soketidle)
	call trash_fdreset

pozrinext3:
.if CONF_TCP
	ld a,(soktcp)
	call tcp_fdisset
	jr z,pozrinext4
.if 0
	call tcp_data_first
pozrinxttcp:
	ld a,#'L
	call print64
	ld de,#0
	ld bc,#1024
	call tcp_accept

	call tcp_data_next
	jr nz,pozrinxttcp

	call tcp_fdreset
.else
	ld hl,#tcp_acc+2
	ld de,#0
	ld bc,#1024
	call tcp_accept
	ld hl,#sndbuf
	ld de,#SNDBUF_LEN
	xor a
	call snd_tcp
	
	ld a,(soktcp)
	call tcp_fdreset
.endif
pozrinext4:
.endif
	ld a, #'*
	call print64
	jp loadnext

finish:
	exx
	pop hl
	exx

        ret

ret

