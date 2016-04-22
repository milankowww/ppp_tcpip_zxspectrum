;
;;
;; print64 routine
;;
;;
	.area 	PRINT64 (REL)
	.radix d

.include "config.h"

; Blok 1
d814:	ld	a,h
	rrca	
	rrca	
	rrca	
	and	#0xe0
	rr	l
	push	af
	or	l
	ld	l,a
	ld	a,h
	and	#0x18
	or	#0x40
	ld	h,a
	pop	af
	ex	af,af
	ret	
d828:	ld	hl,(#0xfde6)
	push	af
	call	d814
	pop	af
	push	hl
	push	de
	push	bc
	ex	de,hl
	ld	l,a
	ld	h,#0x00
	add	hl,hl
	add	hl,hl
	ld	bc,#chars-#128
	add	hl,bc
	ex	de,hl
	ld	b,#0x08
	ld	c,#0xf0
	ex	af,af
	jr	nc,d847
	ld	c,#0x0f
d847:	ex	af,af
d848:	ld	a,c
	cpl	
	and	(hl)
	ld	(hl),a
	ld	a,(de)
	bit	#0,b
	jr	z,d864
	inc	de
	ex	af,af
	jr	c,d867
d855:	ex	af,af
	rrca	
	rrca	
	rrca	
	rrca	
d85a:	and	c
	or	(hl)
	ld	(hl),a
	inc	h
	djnz	d848
	pop	bc
	pop	de
	pop	hl
	ret	
d864:	ex	af,af
	jr	c,d855
d867:	ex	af,af
	jr	d85a
		
; Blok 2
d893:	push	hl
	push	bc
	ld	a,#0x08
d897:	ld	bc,#0x20
	push	de
	push	hl
	ldir	
	pop	hl
	pop	de
	inc	h
	inc	d
	dec	a
	jr	nz,d897
	pop	bc
	pop	hl
	ret	
d8a8:	ld	hl,(#0xfde6)
	sub	h
	ret	z
	ld	b,a
	ld	l,#0x00
	call	d814
d8b3:	ld	d,h
	ld	a,l
	add	a,#0x20
	ld	e,l
	ld	l,a
	jr	nz,d8bf
	ld	a,#0x08
	add	a,h
	ld	h,a
d8bf:	call	d893
	djnz	d8b3
	ret	
		
; Blok 3
d98e:	ld	a,#0x17
	push	hl
	push	de
	ld	hl,#0x00
	ld	(#0xfde6),hl
	call	d8a8
	pop	de
	pop	hl
	ld	(#0xfde6),hl
	ret	
		
; Blok 4
print64::
dba2:	cp	#0x0a
	ret	z
	cp	#0x0c
	ret	z
	push	hl
	ld	hl,(#0xfde6)
	cp	#0x20
	jp	c,dbcb
	push	hl
	call	d828
	pop	hl
	inc	l
	ld	a,#0x40
	sub	l
	jr	nz,dbc6
dbbc:	ld	l,a
	ld	a,h
	sub	#0x16
	adc	a,#0x16
	ld	h,a
	call	nc,d98e
dbc6:	ld	(#0xfde6),hl
	pop	hl
	ret	
dbcb:	sub	#0x0d
	jr	z,dbbc
	ld	de,#dbc6
	push	de
	sub	#0x0c
	jr	z,dbe0
	sub	#0xff
	ret	nz
	ld	a,#0x3e
	cp	l
	ret	c
	inc	l
	ret	
dbe0:	dec	l
	ret	p
	inc	l
	ret	

chars:
	.db	#0x00,#0x00,#0x00,#0x00
	.db	#0x02,#0x22,#0x20,#0x20
	.db	#0x05,#0x50,#0x00,#0x00
	.db	#0x05,#0x75,#0x57,#0x50
	.db	#0x02,#0x74,#0x71,#0x72
	.db	#0x05,#0x12,#0x24,#0x50
	.db	#0x02,#0x52,#0x6b,#0x70
	.db	#0x02,#0x40,#0x00,#0x00

	.db	#0x02,#0x44,#0x44,#0x20
	.db	#0x04,#0x22,#0x22,#0x40
	.db	#0x00,#0x52,#0x72,#0x50
	.db	#0x00,#0x22,#0x72,#0x20
	.db	#0x00,#0x00,#0x02,#0x24
	.db	#0x00,#0x00,#0x70,#0x00
	.db	#0x00,#0x00,#0x06,#0x60
	.db	#0x01,#0x12,#0x24,#0x40

	.db	#0x02,#0x55,#0x55,#0x20
	.db	#0x02,#0x62,#0x22,#0x70
	.db	#0x02,#0x51,#0x24,#0x70
	.db	#0x06,#0x16,#0x11,#0x60
	.db	#0x01,#0x35,#0x57,#0x10
	.db	#0x07,#0x46,#0x11,#0x60
	.db	#0x03,#0x46,#0x55,#0x20
	.db	#0x07,#0x12,#0x24,#0x40

	.db	#0x02,#0x52,#0x55,#0x20
	.db	#0x02,#0x55,#0x31,#0x60
	.db	#0x00,#0x02,#0x00,#0x20
	.db	#0x00,#0x20,#0x02,#0x24
	.db	#0x00,#0x12,#0x42,#0x10
	.db	#0x00,#0x07,#0x07,#0x00
	.db	#0x00,#0x42,#0x12,#0x40
	.db	#0x02,#0x51,#0x20,#0x20


	.db	#0x03,#0x75,#0x74,#0x30
	.db	#0x07,#0x55,#0x75,#0x50
	.db	#0x06,#0x56,#0x55,#0x60
	.db	#0x03,#0x44,#0x44,#0x30
	.db	#0x06,#0x55,#0x55,#0x60
	.db	#0x07,#0x46,#0x44,#0x70
	.db	#0x07,#0x46,#0x44,#0x40
	.db	#0x03,#0x44,#0x75,#0x30

	.db	#0x05,#0x57,#0x55,#0x50
	.db	#0x07,#0x22,#0x22,#0x70
	.db	#0x01,#0x11,#0x55,#0x30
	.db	#0x05,#0x56,#0x65,#0x50
	.db	#0x04,#0x44,#0x44,#0x70
	.db	#0x05,#0x77,#0x75,#0x50
	.db	#0x07,#0x55,#0x55,#0x50
	.db	#0x07,#0x55,#0x55,#0x70

	.db	#0x07,#0x55,#0x74,#0x40
	.db	#0x07,#0x55,#0x57,#0x71
	.db	#0x07,#0x55,#0x66,#0x50
	.db	#0x07,#0x47,#0x11,#0x70
	.db	#0x07,#0x22,#0x22,#0x20
	.db	#0x05,#0x55,#0x55,#0x70
	.db	#0x05,#0x55,#0x55,#0x20
	.db	#0x05,#0x57,#0x77,#0x20

	.db	#0x05,#0x52,#0x25,#0x50
	.db	#0x05,#0x55,#0x22,#0x20
	.db	#0x07,#0x12,#0x24,#0x70
	.db	#0x06,#0x44,#0x44,#0x60
	.db	#0x04,#0x42,#0x21,#0x10
	.db	#0x03,#0x11,#0x11,#0x30
	.db	#0x02,#0x72,#0x22,#0x20
	.db	#0x00,#0x00,#0x00,#0x0f

	.db	#0x02,#0x54,#0xf4,#0xf0
	.db	#0x00,#0x71,#0x75,#0x70
	.db	#0x04,#0x47,#0x55,#0x70
	.db	#0x00,#0x74,#0x44,#0x70
	.db	#0x01,#0x17,#0x55,#0x70
	.db	#0x00,#0x75,#0x74,#0x70
	.db	#0x06,#0x46,#0x44,#0x40
	.db	#0x00,#0x75,#0x57,#0x17

	.db	#0x04,#0x47,#0x55,#0x50
	.db	#0x02,#0x06,#0x22,#0x70
	.db	#0x01,#0x01,#0x11,#0x53
	.db	#0x04,#0x56,#0x55,#0x50
	.db	#0x04,#0x44,#0x44,#0x30
	.db	#0x00,#0x57,#0x77,#0x50
	.db	#0x00,#0x75,#0x55,#0x50
	.db	#0x00,#0x75,#0x55,#0x70

	.db	#0x00,#0x75,#0x57,#0x44
	.db	#0x00,#0x75,#0x57,#0x11
	.db	#0x00,#0x74,#0x44,#0x40
	.db	#0x00,#0x74,#0x71,#0x70
	.db	#0x02,#0x72,#0x22,#0x30
	.db	#0x00,#0x55,#0x55,#0x70
	.db	#0x00,#0x55,#0x55,#0x20
	.db	#0x00,#0x57,#0x77,#0x20

	.db	#0x00,#0x55,#0x25,#0x50
	.db	#0x00,#0x55,#0x57,#0x17
	.db	#0x00,#0x71,#0x24,#0x70
	.db	#0x03,#0x24,#0x22,#0x30
	.db	#0x02,#0x22,#0x22,#0x20
	.db	#0x06,#0x21,#0x22,#0x60
	.db	#0x05,#0xa0,#0x00,#0x00
	.db	#0x0f,#0x9f,#0xdf,#0x9f


