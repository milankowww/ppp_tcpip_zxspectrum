
; Odpadkove sockety a tak
;
	.area TRASH (REL)
	.radix d

.include "config.h"

sock_opened:	.db	#0b00000000
sock_action:	.db	#0b00000000
		; bit 0	- idle socket
		; bit 1 - kbd socket

trash_idle::
	ld hl, #sock_action
	set 0, (hl)
	dec hl
	bit 0, (hl)
	ret z
	ld hl, #nr_fds
	inc (hl)
	ret
trash_idle_open::
	push af
	push hl
	ld hl, #sock_opened
	set 0, (hl)
	pop hl
	pop af
	ld a, #0
	ret
trash_idle_close::
	push hl
	ld hl, #sock_opened
	res 0, (hl)
	pop hl
	ret

; fdzero rusi vsetky sockety, ze na nich nepocuvam
trash_fdzero::
	push af
	xor a
	ld (#sock_opened), a
	pop af
	ret

; reinicializuje jeden socket po precitani dat
trash_fdreset::
	push bc
	push hl
	and #7
	inc a
	ld b, a
	ld a, #0b01111111
mult1:	rlca
	djnz mult1
	ld hl, #sock_action
	and (hl)
	ld (#sock_action), a
	pop hl
	pop bc
	ret

trash_fdset::
	push bc
	push hl
	and #7
	inc a
	ld b, a
	ld a, #0b10000000
mult3:	rlca
	djnz mult3
	ld hl, #sock_opened
	or (hl)
	ld (#sock_opened), a
	pop hl
	pop bc
	ret

trash_fdisset::
	push bc
	push hl
	ld c, a
	and #7
	inc a
	ld b, a
	ld a, #0b10000000
mult4:	rlca
	djnz mult4
	ld hl, #sock_action
	and (hl)
	ld a, c
	pop hl
	pop bc
	ret

trash_close::
	push bc
	push hl
	push af
	and #7
	inc a
	ld b, a
	ld a, #0b01111111
mult5:	rlca
	djnz mult5
	ld hl, #sock_action
	and (hl)
	ld (#sock_action), a
	pop af
	pop hl
	pop bc
	ret

