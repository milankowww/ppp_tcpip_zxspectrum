	.area IPCP (REL)
	.radix d
.include "config.h"

ipcp_req::

ipcp_req_type::
	.db	#0x01
ipcp_req_id::
	.db	#0x01
ipcp_req_len::
	.db	#0x00,#0x0A
ipcp_req_code::
	.db	#0x03
ipcp_req_paramlen::
	.db	#0x06
ipcp_req_ip::
	.db	#0x00,#0x00,#0x00,#0x00

rcv_ipcp::
	ld   a,(hl)
	cp   #1				; conf request
	jp   z,rcv_ipcp_request
	cp   #2				; conf ack
	ret  z
	cp   #3				; conf nak
	jp   z,rcv_ipcp_nak
        jp   main_ppp_loop
rcv_ipcp_request:
	push hl
	push de
	ex   af,af'
	ld   a,#2			; ipcp ack
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
ipcp_param_loop:
	ld   a,d
	or   e
	jr   z,ipcp_send_acknak
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
	jp   c,main_ppp_loop		; error
	cp   #3
	jr   ipcp_param_ok
ipcp_nak:
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
	ld   a,#3			; ipcp nak
	ex   af,af'
	jp   lcp_param_loop
ipcp_param_ok:
	pop  bc
	jr   ipcp_param_loop
ipcp_send_acknak:
	pop  hl				; blbe hlko ;]
	pop  de
	pop  hl
	push hl
	push de
	push hl
	inc  hl
	ld   a,(hl)
	ld   (ipcp_req_id),a
	inc  hl
	ld   (hl),d
	inc  hl
	ld   (hl),e
	pop  hl
	ex   af,af'
	ld   (hl),a
	ex   af,af'
	ld   a,#0x80			; ipcp proto
	call bufput
	ex   af,af'
	ld   h,a
	ex   af,af'
	ld   a,#2
	cp   h
	pop  de
	pop  hl
	jp   nz,main_ppp_loop
	ld   hl,#ipcp_req
	ld   a,(ipcp_req_len)
	ld   d,a
	ld   a,(ipcp_req_len+1)
	ld   e,a
	ld   a,#0x80			; ipcp proto
	call bufput
	ld   hl,#ipcp_req_id
	inc  (hl)
	jp   main_ppp_loop
rcv_ipcp_ack:

	call debug
	call debug
	call debug
	call debug
	call debug
	call debug
	call debug

	ld   bc,#0x06
	add  hl,bc
	ld   de,#ih_ourip
	ld   bc,#0x04
	ldir
	ret
rcv_ipcp_nak:
	ld   bc,#0x04
	add  hl,bc
	ld   a,(hl)
	cp   #3
	jp   nz,main_ppp_loop		; error
	inc  hl
	ld   a,(hl)
	cp   #6
	inc  hl
	jp   nz,main_ppp_loop		; error
	ld   de,#ipcp_req_ip
	ld   bc,#0x04
	ldir
	ld   hl,#ipcp_req
	ld   a,(ipcp_req_len)
	ld   d,a
	ld   a,(ipcp_req_len+1)
	ld   e,a
	ld   a,#0x80			; ipcp proto
	call bufput
	ld   hl,#ipcp_req_id
	inc  (hl)
	jp   main_ppp_loop

