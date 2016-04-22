
; LCP layer
;
	.area LCPLAYER (REL)
	.radix d

.include "config.h"

rcv_lcp::
	ld   a,(hl)
	cp   #1				; lcp conf request
	jp   z,rcv_lcp_conf_request
	cp   #5				; lcp term request
	jp   z,rcv_lcp_term_request
	cp   #9				; lcp echo request
	jp   z,rcv_lcp_echo_request
        jp   main_ppp_loop
rcv_lcp_conf_request:
        push hl
        push de
	ex   af,af'
	ld   a,#2			; lcp ack
	ex   af,af'
	inc  hl
	inc  hl
	inc  hl
	inc  hl
	dec  de
	dec  de
	dec  de
	dec  de
	push hl
lcp_param_loop::
	ld   a,d
	or   e
	jr   z,lcp_send_acknak
	push hl
	inc  hl
	ld   b,#0
	ld   c,(hl)
	dec  hl
	ld   a,(hl)
	add  hl,bc
	ex   de,hl
	sbc  hl,bc
	ex   de,hl
	jp   c,main_ppp_loop			; error
	cp   #1
	jr   z,lcp_param_ok
	cp   #2
	jr   z,lcp_param_ok
	cp   #5
	jr   z,lcp_param_ok
	cp   #6
	jr   z,lcp_param_ok
lcp_nak:
	ld   a,c
	exx
	pop  hl
	ld   b,#0
	ld   c,a
	pop  de
	ldir
	pop  bc
	pop  hl
	ld   b,d
	ld   c,e
	ex   de,hl
	and  a
	sbc  hl,de
	push de
	push hl
	push bc
	exx
	ex   af,af'
	ld   a,#3			; lcp nak
	ex   af,af'
	jr   lcp_param_loop
lcp_param_ok:
	pop  bc
	jr   lcp_param_loop
lcp_send_acknak:
	pop  hl				; blbe hlko ;]
	pop  de
	pop  hl
	push hl
	push de
	push hl
	inc  hl
	inc  hl
	ld   (hl),d
	inc  hl
	ld   (hl),e
	pop  hl
	ex   af,af'
        ld   (hl),a			; lcp ack / nak
	ex   af,af'
        ld   a,#0xc0			; lcp proto
        call bufput
	ex   af,af'
	ld   h,a
	ex   af,af'
	ld   a,#2
	cp   h
        pop  de
        pop  hl
	jp   nz,main_ppp_loop
        ld   (hl),#1			; lcp req (neskor sa bude robit v send bufri)
        push hl
        inc  hl
        ld   (hl),#1
        inc  hl
        ld   (hl),#0
        inc  hl
        ld   (hl),#4
        pop  hl
        ld   a,#0xc0			; lcp proto
        call bufput
        jp   main_ppp_loop
rcv_lcp_term_request:
        ld   (hl),#6			; lcp echo reply
        ld   a,#0xc0			; lcp proto
        call bufput
        jp   main_ppp_loop
rcv_lcp_echo_request:
        ld   (hl),#10			; lcp echo reply
        ld   a,#0xc0			; lcp proto
        call bufput
        jp   main_ppp_loop

