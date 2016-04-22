	.area bla (ABS)
	.radix d	
	.org	#0x9000		; 09 "rs232" mode com1:9600,e,8,2
p:	jp	bytput
		
demo2:	call	#0xf5ac
	call	#0xd945
	call	bytput
	jr	demo2
		
bytput:	ld	e,a
	xor	a
	out	(#0x5b),a		; start bit
	ld	b,#23
	djnz	#.
	ld	c,#0x08
bbpp1:	rrc	e
	sbc	a,a
	and	#0x08
	out	(#0x5b),a		; bity bajtu
	ld	b,#24
	djnz	#.
	dec	c
	jr	nz,bbpp1
	xor	a		; parita
	xor	e
	ld	a,#0x08
	jp	pe,bbpp2
	xor	a
bbpp2:	out	(#0x5b),a
	ld	b,#25
	djnz	#.
	ld	a,#0x08		; stop bity
	out	(#0x5b),a
	ld	b,#51
	djnz	#.
	djnz	#.
	djnz	#.
	djnz	#.
	ret	
		
demo1:	call	#0xf5ac		; ukazka prijimania znakov
	call	bytget
	ret	nc
	call	#0xdba2
	jr	demo1
		
bytget:	di	
tstwww:	ld	a,#0x7f		; Prijatie jedneho bajtu
	in	a,(#0xfe)		; Vystup: cy=1 ok
	rra			;         ak ok tak a=bajt
	ret	nc
	in	a,(#0x5b)		; cakanie na
	add	a,a		; zaciatocnu
	jr	c,tstwww		; hranu startu
		
	ex	(sp),hl		; cakanie proti zakmitom
	ex	(sp),hl
		
	ld	b,#3		; test polovice startu
tstbeg:	in	a,(#0x5b)		; /
	add	a,a
	ccf	
	ret	nc
	djnz	tstbeg		; \36
		
	ld	e,#0x00
	ld	c,#0x09
		
rotbit:	ld	b,#25		; /
	djnz	#.
	nop			; \331
	rr	e		; /
	in	a,(#0x5b)
	add	a,a
	dec	c
	jr	nz,rotbit		; \38
	ccf	
	sbc	a,a		; parita
	ld	d,a
		
	ld	b,#22
	djnz	#.
	in	a,(#0x5b)		; stop bit
	add	a,a
	ret	nc
		
	xor	a
	xor	e
	push	af
	pop	bc
	ld	a,c
	xor	d
	and	#0x04
	cp	#0x01
	ld	a,e
	ret	
