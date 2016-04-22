;;
;; serial-conv1.asm
;;
;; IO routines of rs232 emulator for pure level-convertor on parallel port
;; additional support for hardware flow control can be use.
;;
;

	.area SERIAL (REL)
	.radix d

; IN hl = adresa, de = dlzka
; a = typ: 0xc0, 0x80 ... standardne
;	0x00 ... ip paket

; moje rozkosne nizsie bity (www):
;	0b0001 nevypise zaver
;	0b0010 nevypise uvod

; Nici vsetko co moze a ani nic nevrati ;] (prasa)

bufput::
.if 1-DEBUG
	ex af, af'
	push af
	ex af, af'
	push af
	push bc
	push de
	push hl
	ld a, #13
	call print64
	ld a, #'*
	call print64
	pop hl
	pop de	
	pop bc
	pop af
	ex af, af'
	pop af
	ex af, af'
.endif

	push af
	and #0b0010
	jr nz, putn
	ld   bc,#0xffff
	ld   a,#0x7e
	call bytput
	ld   a,#0x7e
	call bytput
	ld   a,#0xff
	call escput
	ld   a,#0x03
	call escput
	pop  af
	push af
	and #0b11110000
	call escput
	ld   a,#0x21
	call escput
putn:
	ld   a,(hl)
	call escput
	inc  hl
	dec  de
	ld   a,d
	or   e
	jr   nz,putn

	pop af
	and #0b0001
	ret nz

	push bc
	ld   a,c
	xor  #255
	call escput
	pop  bc
	ld   a,b
	xor  #255
	call escput
	ld   a,#0x7e
	jp   bytput

escput:

.if 1-DEBUG
	ex af, af'
	push af
	ex af, af'
	push af
	push bc
	push de
	push hl
	call p2h
	pop hl
	pop de
	pop bc
	pop af
	ex af, af'
	pop af
	ex af, af'
.endif

	push af
	push af
	push hl
	xor  c
	ld   h, #FCSTABHI	; fcstab/#2
	ld   l,a
	ld   a,b
	add  hl,hl
	xor  (hl)
	ld   c,a
	inc  hl
	ld   b,(hl)
	pop  hl
	pop  af
	cp   #32
	jr   c,escp
	cp   #0x7d
	jr   z,escp
	cp   #0x7e
	jr   nz,esco
escp:
	ld   a,#0x7d
	call bytput
	pop  af
	xor  #0x20
	jr   bytput
esco:
	pop  af
bytput::
	push bc
	push de
	ld   e,a
	ld a, #1
	di

	out  (#SER_IOPORT),a	;	11 t

	ld   b,#4		;	 7 t
	djnz #.			;	13 t / 8 t

	ld   c,#8		;	 7 t
bbpp1:
	rrc  e			;	 8 t
	sbc  a,a		;	 4 t
	or   #0x01		;	 7 t

	out  (#SER_IOPORT),a	;	11 t

	ld   b,#3		;	 7 t
	djnz #.			;	13 t / 8 t

	nop			;	 4 t

	dec  c			;	 4 t
	jr   nz,bbpp1		;	12 t / 7 t

	ld   a,#0x09		;	 7 t ; stop bity (druha strana nemoze)

	ld   e,#0		;	 7 t
	inc  de			;	 6 t
	cp   e			;	 4 t

	out  (#SER_IOPORT),a	;	11 t

	ei

	ld   b,#8		;	 7 t
	djnz #.			;	13 t / 8 t

	pop  de
	pop  bc
	ret
 
offset::
	.dw   #RCVBUFF
old_offset:
	.dw   #0
esc:	.db   #0
 

bufget::
	ld   (offset),hl
	ld   (old_offset),hl
	ld   de,#edge
	push de			;	podraz na ret ;] ryxlejsie jak jr
discard:
	ld   e,#0
	ld   hl,(old_offset)
next:
	ld   b,#0		;	 7 t
wait:
	in   a,(#SER_IOPORT)	;	11 t
	add  a,a		;	 4 t
	ret  nc			;	 5 t / 11 t
	in   a,(#SER_IOPORT)	;	11 t
	add  a,a		;	 4 t
	ret  nc			;	 5 t / 11 t
	in   a,(#SER_IOPORT)	;	11 t
	add  a,a		;	 4 t
	ret  nc			;	 5 t / 11 t
	in   a,(#SER_IOPORT)	;	11 t
	add  a,a		;	 4 t
	ret  nc			;	 5 t / 11 t
	in   a,(#SER_IOPORT)	;	11 t
	add  a,a		;	 4 t
	ret  nc			;	 5 t / 11 t
	in   a,(#SER_IOPORT)	;	11 t
	add  a,a		;	 4 t
	ret  nc			;	 5 t / 11 t
	djnz wait		;	13 t / 8 t
	pop  de			;	10 t - smolka, odjeb sa nepouzil ;]
	ret  			;	10 t
edge: 
	in   a,(#SER_IOPORT)	;	11 t
 	add  a,a		;	 4 t
	ret  c			;	 5 t / 11 t - yebly zakmit

	ld   a,e		;	 4 t
	ld   (esc),a		;	13 t

	ld   a,h		;	 4 t
	cp   #RCVENDHI		;	 7 t
	ret  z			;	 5 t / 11 t

	ld   de,(offset)	;	20 t

;	ld   a,r		;	 9 t
	bit  6,(hl)		;	12 t
;	nop
;	nop

	in   a,(#SER_IOPORT)	;	11 t - bit 0

	and  a			;	 4 t
	push hl			;	11 t
	sbc  hl,de		;	15 t
	ex   de,hl		;	 4 t
	ld   (hl),e		;	 7 t
	inc  hl			;	 6 t
	ld   (hl),d		;	 7 t
	pop  hl			;	10 t
	nop			;	 4 t

	add  a,a		;	 4 t
	rr   d			;	 8 t

	in   a,(#SER_IOPORT)	;	11 t - bit 1

	add  a,a		;	 4 t
	rr   d			;	 8 t

	bit  3,7(ix)		;	20 t
	bit  3,7(ix)		;	20 t
	ld   bc,#edge		;	10 t
	push bc			;	11 t - dalsi odyeb na ret ;]
	ld   a,#0		;	 7 t

	in   a,(#SER_IOPORT)	;	11 t - bit 2

	add  a,a		;	 4 t
	rr   d			;	 8 t

	bit  3,7(ix)		;	20 t
	bit  3,7(ix)		;	20 t
	bit  3,7(ix)		;	20 t
	nop			;	 4 t
	nop			;	 4 t

	in   a,(#SER_IOPORT)	;	11 t - bit 3

	add  a,a		;	 4 t
	rr   d			;	 8 t

	ld   bc,(offset)	;	20 t
	ld   (old_offset),bc	;	20 t
	bit  3,7(ix)		;	20 t
	nop			;	 4 t
	nop			;	 4 t

	in   a,(#SER_IOPORT)	;	11 t - bit 4

	add  a,a		;	 4 t
	rr   d			;	 8 t

	ld   bc,(offset)	;	20 t

	ld   a,h		;	 4 t
	sub  b			;	 4 t
	rlca			;	 4 t
	rlca			;	 4 t
	ld   b,a		;	 4 t

	ld   a,l		;	 4 t
	sub  c			;	 4 t
	or   b			;	 4 t
	ld   c,a		;	 4 t

	xor  a			;	 4 t
	ld   b,a		;	 4 t
	nop			;	 4 t

	in   a,(#SER_IOPORT)	;	11 t - bit 5

	add  a,a		;	 4 t
	rr   d			;	 8 t

	ld   e,#0xff		;	 7 t
	ld   a,#0		;	 7 t
	cp   c			;	 4 t
	jr   nz,skipb0		;	 7 t / 12 t
	ld   b,e		;	 4 t
skipb0:

	ld   e,#0x03		;	 7 t
	ld   a,#1		;	 7 t
	cp   c			;	 4 t
	jr   nz,skipb1		;	 7 t / 12 t
	ld   b,e		;	 4 t
skipb1:

	bit  4,d		;	 8 t

	in   a,(#SER_IOPORT)	;	11 t - bit 6

	add  a,a		;	 4 t
	rr   d			;	 8 t

	ld   e,#0x21		;	 7 t
	ld   a,#3		;	 7 t
	cp   c			;	 4 t
	jr   nz,skipb3		;	 7 t / 12 t
	ld   b,e		;	 4 t
skipb3:

	ld   c,b		;	 4 t

	ld   a,(esc)		;	13 t
	ld   e,a		;	 4 t

	bit  4,d		;	 8 t
	ld   a,r		;	 9 t

	in   a,(#SER_IOPORT)	;	11 t - bit 7

	add  a,a		;	 4 t
	ld   a,d		;	 4 t
	rra			;	 4 t

	cp   #0x7e		;	 7 t
	jr   z,flag		;	 7 t /12 t

	cp   #0x7d		;	 7 t
	jr   z,escape		;	 7 t / 12 t

;	call debug
	xor  e			;	 4 t

	rr   c			;	 8 t
	jr   nc,skip		;	 7 t / 12 t

	cp   b			;	 4 t
	jr   nz,discard1	;	 7 t / 12 t

skip:
	ld   (hl),a		;	 7 t
	inc  hl			;	 6 t

	in   a,(#SER_IOPORT)	;	11 t

	add  a,a		;	 4 t
	jr   nc,discard2	;	 7 t /12 t

	ld   e,#0		;	 7 t

	jp   next		;	10 t

flag:
	and  e			;	 4 t
	jr   nz,discard3	;	 7 t / 12 t

	ld   (offset),hl	;	16 t

	ld   e,#0		;	 7 t

	bit  6,(hl)		;	12 t

	in   a,(#SER_IOPORT)	;	11 t

	add  a,a		;	 4 t
	jr   nc,discard4	;	 7 t / 12 t

	jp   next		;	10 t

escape:
	ld   e,#32		;	 7 t
	ld   (esc),a		;	13 t

	ld   b,#1		;	 7 t
	djnz #.			;	 8 t / 13 t ;]]]

	in   a,(#SER_IOPORT)	;	11 t

	add  a,a		;	 4 t
	jr   nc,discard5	;	 7 t /12 t

	jp   next		;	10 t

discard1::
;	call debug
	jp discard

discard2::
;	call debug
	jp discard

discard3::
;	call debug
	jp discard

discard4::
;	call debug
	jp discard

discard5::
;	call debug
	jp discard



.include "config.h"

