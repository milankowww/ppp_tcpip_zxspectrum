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
;	0x0010 nevypise uvod

; Nici vsetko co moze a ani nic nevrati ;] (prasa)

bufput::

;call debug
;call hex_dump

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
.if FLOWCONTROL
	ld a, #1
.else
	xor  a
.endif
	di
	out  (#SER_IOPORT),a
	ld   b,#23
	djnz #.
	ld   c,#8
bbpp1:
	rrc  e
	sbc  a,a
.if FLOWCONTROL
;	and  #0x09
; WWW
	or	#0x01
.else
	and  #0x08
.endif
	out  (#SER_IOPORT),a
	ld   b,#24
	djnz #.
	dec  c
	jr   nz,bbpp1
.if FLOWCONTROL
	ld   a,#0x09               ; stop bity (druha strana nemoze)
.else
	ld   a, #0x08	; stop bity + CTS (druha strana moze)
.endif
	out  (#SER_IOPORT),a
	ei
	ld   b,#50
	djnz #.
	pop  de
	pop  bc
	ret
 
offset::
	.dw   #RCVBUFF
flage:	.db   #0
toss:	.db   #0
 

cleanup2:
	exx
	ret

bufget::
	ld   (offset),hl
	ld   a,#0
	ld   (toss),a
.if 1-FLOWCONTROL
	exx
	ld   hl,#0
	exx
.endif
callb1:
	xor  a
	ld   (#flage),a
	ld   hl,(offset)
callb5:
	exx
.if FLOWCONTROL
	;ld bc, #1600
	ld bc, #4096
.else
	ld   bc,#16384
.endif
	exx
callb3:
	exx
callb4:
	xor  a
.if 1-FLOWCONTROL
	dec  hl
	cp   h
	jr  z, cleanup2
.endif
	dec  bc
	cp   b
	jr  z, cleanup2
	in   a,(#SER_IOPORT)
	add  a,a
	jr   c,callb4
 
	exx
	bit  #3,7(ix)
	and  (hl)
	or   (hl)
 
	ld   b,#128
	in   a,(#SER_IOPORT)
	add  a,a
	ccf
	jp   nc,callb3
	nop
	nop
	in   a,(#SER_IOPORT)
	add  a,a
	ccf
	jp   nc,callb3
	nop
	nop
	in   a,(#SER_IOPORT)
	and  b
	jr   nz,callb3
	add  a,#128
	add  a,#128
 
	ld   e,#0
	ld   c,#8
ldbn:
	ld   b,#25
	djnz #.
	nop
	rr   e
	in   a,(#SER_IOPORT)
	add  a,a
	dec  c
	jr   nz,ldbn
	rr   e
 
	ld   a,e

	cp   #0x7d                 ; escape
	jr   nz,skipf2
	ld   a,#32
	ld   (#flage),a
	ld   b,#20
	jp   callrs
skipf2:
	cp   #0x7e                 ; flag
	jr   nz,skipf1
	xor  a
	ld   (toss),a
	ld   a,(flage)
	and  a
	jp   nz,callb1
 
	ld   de,(offset)
	ld   b,h
	ld   c,l
	and  a
	sbc  hl,de
	ex   de,hl
	ld   a,d
	or   e
	jp   z,callb1
 
	ld   a,(hl)
	cp   #255
	jp   nz,callb1
	ld   (hl),e
	inc  hl
	ld   a,(hl)
	cp   #3
	jp   nz,callb1
	ld   (hl),d
 
	inc  hl
	ld   a,(hl)
	and  #0b00111111
	jp   nz,callb1
 
	inc  hl
	ld   a,(hl)
	cp   #0x21
	jp   nz,callb1
	ld   h,b
	ld   l,c
	ld   (offset),hl
	jr   chksiz
 
callrs:
	djnz #.
	in   a,(#SER_IOPORT)
	add  a,a
	jp   nc,callb1
	jp   callb5
 
skipf1:
	ld   e,a
	ld   a,(toss)
	and  a
	ld   b,#18
	jp   nz,callb1
	ld   a,(#flage)
	xor  e
	ld   (hl),a
	inc  hl
        ld   b,#15
        djnz #.
chksiz:
	xor  a
	ld   (#flage),a
	in   a,(#SER_IOPORT)
	add  a,a
	jp   nc,callb1
	ld   a,h
	cp   #RCVENDHI		; hard coded, zmenit ak sa presunie rcvbuff
	jp   nz,callb5
	ret
 


.include "config.h"

