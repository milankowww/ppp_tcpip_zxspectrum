;
;;
;; http daemon 0.1 beta, (c) 1999 WWW
;;
;;
	.area APPLICATION (REL)
	.radix d

.include "config.h"
.include "app/httpd/index.asm"

MULTI=4				; number of simultaneously keeped connections
DEFAULTACTION=closeaction	; default "read event" handler

acceptbuf:
	.ds 17*16		; space for 16 pending connects

readbuf1:
	.ds MULTI*128		; recieve buffers for that connections

connsocknrs:			; for each connection:
	.ds MULTI*3		; recieve socket number, 255 if free
				; word - pointer to the "read event" handler

hangsocknr:
	.db	#0		; listening socket number

hangsock:			; data needed to create listening socket
	.db	#TCP_MAGIC2
	.dw	#0x5000		; port 80
	.dw	#240
	.dw	#acceptbuf
	.dw	#0, #0, #0
	.dw	#hangsock
	.db	#0

str_init:
	.ascii	'HTTPD started.'
	.db #13, #0

appmain::
	call select		; wait for network to initialise

	ld hl, #hangsock	; open listening socket
	call tcp_listen
	ld (hangsocknr), a

	ld hl, #connsocknrs	; free table of connected sockets
	ld de, #connsocknrs+1
	ld bc, #MULTI*3-1
	ld (hl), #255
	ldir

	ld hl, #str_init	; and display a short note
	call WriteStr

mainloop:
	call tcp_fdzero		; to reset all filedescriptors

	ld a, (hangsocknr)
	call tcp_fdset		; we want to be informed about connect requests

	ld hl, #connsocknrs	; mark all active sockets too
	ld b, #MULTI
loop1:	ld a, (hl)
	cp 255
	call nz,tcp_fdset
	inc hl
	inc hl
	inc hl
	djnz loop1

	call select		; wait for data or connect

	ld a, (hangsocknr)	; now check for connect requests
	call tcp_fdisset
	call nz, acceptnew

	ld hl, #connsocknrs	; look at the state of all active connections
	ld b, #multi
loop2:	ld a, (hl)
	cp #255
	jr z, skip3
	call tcp_fdisset
	jr nz, skip3
	push hl
	push bc
	call someaction		; if there is new data, look at it
	pop bc
	pop hl
skip3:	inc hl
	inc hl
	inc hl
	djnz loop2

;; Subroutine acceptnew
;; Accepts incoming TCP request and creates a new socket for it.

acceptnew:
	call tcp_data_first	; prepare HL and DE for parsing

loop4:
	call tcp_data_next	; walk through all connect requests
	ret nz			; end of them

	push hl

	ld hl, #connsocknrs	; first we have to find a free slot
loop5:	ld a, (hl)
	cp 255
	jr z, skip6
	inc hl
	djnz loop5

	; we're sorry, but we cannot handle this connection, so we will
	; accept and close it.

	pop hl

	ld de, #0		; place the recieve buffer in ROM
	ld bc, #1024		; fictive "recieve buffer size"
	call tcp_accept

	jr loop4

skip6:	; we can safely accept and archive a new connection

	pop hl
	
	jr loop4

;; Subroutine someaction
;; Handles incoming data on TCP connections by calling appropriate routine
someaction:
	inc hl
	ld e, (hl)
	inc hl
	ld d, (hl)
	dec hl
	ex de, hl
	jp (hl)

;; Handler closeaction
;; closes handle.
;; input: a = handle, de -> connsocknrs[i].fn
closeaction:
	call tcp_close
	ex de, hl
	dec hl
	ld (hl), #255	; invalidate contents
	ret

