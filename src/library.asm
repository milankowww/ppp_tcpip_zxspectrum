;;
;; library.asm
;;
;; set of utilities.
;;
;

	.area LIBRARY (REL)
	.radix d

.include "config.h"

libinit::
.if UDP_CONSOLE
	xor a
	ld (isin), a
.endif
	ret

hitkey::
	push af
loop:
	xor a
	in a,(#254)
	or #0b11100000
	inc a
	jr z,loop
	
	pop af
	ret
; generates FCS for PPP frames

generate_fcs::
	ld   hl, #FCSTAB
	ld   de,#0
gfc1:
	ld   b,d
	ld   c,e
 
	ld   a,#8
gfc2:
	srl  b
	rr   c
	jr   nc,gfcob
	push af
	ld   a,b
	xor  #0x84
	ld   b,a
	ld   a,c
	xor  #0x08
	ld   c,a
	pop  af
gfcob:
	dec  a
	jr   nz,gfc2
 
	ld   (hl),c
	inc  hl
	ld   (hl),b
	inc  hl
	inc  de
	ld   a,d
	and  a
	jr   z,gfc1
	ret
 
.if 0	; viz. poznamka nizsie
chkttxt:
	.db #'C,#'h,#'k,#'s,#'m,#':
.endif
chksm::
;Vyrata checksum pre danu oblast a zapise ju na miesto.
;vstup  : DE - zaciatok
;	  HL - miesto pre chksm
;	  BC - dlzka
;vystup : DE - checksum
;meni   : DE,(HL)
;ostatne nemeni.
.if 0	; toto tu zostava z historickych dovodov - vypisuje pakety,
	; ktorym to pocita IP checksum
	; treba odpoznamkovat aj chkttxt tesne nad rutinou.
	push hl
	push af
	push bc
	push de
	ld hl,#chkttxt
	call WriteStr
	pop hl
	pop de
	push de
	push hl
	call hex_dump
	pop de
	pop bc
	pop af
	pop hl
	call debug
.endif
	push hl
	push bc
	push af
	xor a
	ld (hl),a
	inc hl
	ld (hl),a
	push hl
	ex de,hl	; hl -> zaciatok
	ld d,a		; de = 0
	ld e,a
	rl b
lp1:
	rr b
	ld a,(hl)
	adc a,e
	ld e,a
	inc hl
	dec bc
	ld a,b
	rl b
	or c
	jr z,end1
	rr b
	ld a,(hl)
	adc a,d
	ld d,a
	inc hl
	dec bc
	ld a,b
	rl b
	or c
	jr nz,lp1
end2:
	rr b
	ld a,e
	adc a,#0
	rl b
	cpl
	rr b
	ld e,a
	ld a,d
	adc a,#0
	cpl
	ld d,a
	pop hl
	ld (hl),d
	dec hl
	ld (hl),e
	pop af
	pop bc
	pop hl
	ret

end1:	rr b
	ld a,d
	adc a,#0
	ld d, a	; WWW
	jr end2

; vypis hexa cisla

p4h:: 
;Vypise 1 word hexa
;vstup  : HL - vypisovany word
;vystup : -
;meni   : HL,AF
	ld   a,h
	push hl
	call p2h
	pop  hl
	ld   a,l
p2h::
;Vypis 1 bytu ako hexa
;vstup  : A - vypisovany byte 
;vystup : -
;meni   : HL,AF
	push af
	srl  a
	srl  a
	srl  a
	srl  a
	call p1h
	pop  af
	and  #15
p1h:
	ld   hl,#hextab
	add  a,l
	ld   l,a
	ld   a,#0
	adc  a,h
	ld   h,a
	ld   a,(hl)
	call print64
	ret
hextab:
	.ascii '0123456789ABCDEF'



.if UDP_CONSOLE

isin:	.db	#0
onein:
	push af
	ld a, (isin)
	and a
	jr nz, oneisin
	inc a
	ld (isin), a
	pop af
	ret
oneisin:
	pop af
	inc sp
	inc sp
	ret
oneout:
	push af
	ld a, (isin)
	dec a
	ld (isin), a
	pop af
	ret

dbgout:	.dw	#31
oldsp:	.dw	#0
oldhl:	.dw	#0
oldde:	.dw	#0
oldbc:	.dw	#0
oldaf:	.dw	#0

oldchl:	.dw	#0
oldcde:	.dw	#0
oldcbc:	.dw	#0
oldcaf:	.dw	#0

oldpc:	.dw	#0
oldix:	.dw	#0
oldiy:	.dw	#0

DBGSZ	=	. - dbgout

debug::
;Vypise obsah registrov
;vstup  : -
;vystup : -
;meni   : -
	call onein
	di
	ld (oldsp), sp
	ld (oldhl), hl
	ld (oldde), de
	ld (oldbc), bc
	push af
	pop hl
	ld (oldaf), hl
	exx
	ex af, af'
	ld (oldchl), hl
	ld (oldcde), de
	ld (oldcbc), bc
	push hl
	pop af
	ld (oldcaf), hl
	pop hl
	push hl
	ld (oldpc), hl
	ld (oldix), ix
	ld (oldiy), iy

	ld a, #0x70
	ld hl, #dbgout
	ld de, #DBGSZ
	call snd_udp

	ld bc, (oldcbc)
	ld de, (oldcde)
	ld hl, (oldcaf)
	push hl
	pop af
	ld hl, (oldchl)

	exx
	ex af,af'

	ld bc, (oldbc)
	ld de, (oldde)
	ld hl, (oldaf)
	push hl
	pop af
	ld hl, (oldhl)
	ei
	call oneout
	ret

znakout:
	.db	#0
print64::
	call onein
	push af
	ld (znakout), a
	push bc
	push de
	push hl
	push ix
	exx
	ex af, af'
	push af
	push bc
	push de
	push hl


	ld a, #0x70
	ld hl, #znakout
	ld de, #1
	call snd_udp

	pop hl
	pop de
	pop bc
	pop af
	exx
	ex af, af'
	pop ix
	pop hl
	pop de
	pop bc
	pop af
	call oneout
	ret

WriteStr::
;Vypis retazca ukonceneho 0, alebo nastavenym 7. bitom.
;Vstup: HL -> String
;Meni : -
	call onein
	push af
	push bc
	push de
	push hl
	ld de, #0
writestrlp:
	ld a, (hl)
	inc hl
	and a
	jr z, endfnd
	inc de
	bit 7, a
	jr z, writestrlp
endfnd:
	ld a, d
	or e
	jr z, dontsend
	ld a, #0x70
	pop hl
	push hl
	call snd_udp
dontsend:
	pop hl
	pop de
	pop bc
	pop af
	call oneout
	ret
; hexa vypis od DE bajtov od HL

hex_pre_header:
	.dw	#30
	.dw	#0x0000
HPHSIZ	=	. - hex_pre_header

hex_dump::
;vstup  : HL - zaciatok bloku
;	  DE - dlzka bloku

	call onein
	ld (hex_pre_header+2), hl
	push af
	push bc
	push de
	push hl

	ld a, #0x70
	ld hl, #hex_pre_header
	ld de, #HPHSIZ
	call snd_udp

	pop hl
	pop de
	push de
	push hl

	ld a, #0x70
	call snd_udp

	pop hl
	pop de
	pop bc
	pop af
	call oneout
	ret

.else

oldsp:	.dw	#0
oldhl:	.dw	#0
oldde:	.dw	#0
oldbc:	.dw	#0
oldaf:	.dw	#0
retaddr:	.dw	#0

debug::
;Vypise obsah registrov
;vstup  : -
;vystup : -
;meni   : -
	di
	ld (oldsp), sp
	ld (oldhl), hl
	ld (oldde), de
	ld (oldbc), bc
	pop hl
	ld (retaddr), hl
	push hl
	push af
	push af
	pop hl
	ld (oldaf), hl

	ld a, #'<
	call print64
	ld hl, (retaddr)
	call p4h
	ld a, #':
	call print64
	ld hl, (oldsp)
	call p4h
	ld a, #32
	call print64
	ld hl, (oldaf)
	call p4h
	ld a, #32
	call print64
	ld hl, (oldbc)
	call p4h
	ld a, #32
	call print64
	ld hl, (oldde)
	call p4h
	ld a, #32
	call print64
	ld hl, (oldhl)
	call p4h
	ld a, #'>
	call print64

	ld bc, (oldbc)
	ld de, (oldde)
	ld hl, (oldhl)
	pop af
	ei
	ret
; Blok 1
printdat:
	.dw	0
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
d828:	ld	hl,(printdat)
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

; Blok 3
d98e:	ld	a,#0x17
	push	hl
	push	de
	ld	hl,#0x00
	ld	(printdat),hl
	ld	hl,(printdat)
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
	pop	de
	pop	hl
	ld	(printdat),hl
	ret	
		
; Blok 4
print64::
;Vypise znak 
;vstup  : A - Vypisovany znak
;vystup : -
;meni   : DE
dba2:	cp	#0x0a
	ret	z
	cp	#0x0c
	ret	z
	push	hl
	ld	hl,(printdat)
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
dbc6:	ld	(printdat),hl
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


WriteStr::
;Vypis retazca ukonceneho 0, alebo nastavenym 7. bitom.
;Vstup: HL -> String
;Meni : -
	push af
	push hl
	push de
writestrlp:
	ld a,(hl)
	ld e,a
	and #0x7f
	jr z,writestrend
	call print64
	inc hl
	rl e
	jr nc,writestrlp
writestrend:
	pop de
	pop hl
	pop af
	ret

; hexa vypis od DE bajtov od HL

hex_dump::
;Vypise blok pamate v hexa kodoch
;vstup  : HL - zaciatok bloku
;	  DE - dlzka bloku
;vystup : -
;meni   : -
	push af
	push de
	push hl
	ld a,#13
	call print64
hex_du_loop:
	ld a,d
	or e
	jr z,hex_du_end
	push hl
	ld a,(hl)
	call p2h
	pop hl
	inc hl
	dec de
	jr hex_du_loop
hex_du_end:
	pop hl
	pop de
	pop af
	ret

.endif

WriteNr16::
;Vypis 16 bitoveho cisla
;Vstup : HL = Cislo
;Meni  : HL,BC,AF
	ld bc,#10000
	call WriteDigit
	ld bc,#1000
	call WriteDigit
WriteNr168:
	ld bc,#100
	call WriteDigit
	ld e,#10
	call WriteDigit
	ld e,#1
WriteDigit:
	ld a,#'0-1
WriteDigitLp:
	inc a
	sbc hl,bc
	jr nc,WriteDigitLp
	add hl,bc
	jp print64

WriteNr8::
;Vypis 8 bitoveho cisla
;Vstup : A - Cislo
;Meni  : AF
	push hl
	push bc
	ld l,a
	ld h,#0
	call WriteNr168
	pop bc
	pop hl
	ret

WriteIP::
;Vypis IP adresy
;Vstup : HL -> IP adresa
;Meni  : -
	push af
	push bc
	push hl
	ld b,#3
writeiplp:
	ld a,(hl)
	call WriteNr8
	ld a, #'.
	call print64
	inc hl
	djnz writeiplp
	ld a,(hl)
	call WriteNr8
	pop hl
	pop bc
	pop af
	ret

GetString::
;Nacitanie retazca z klavesnice
;Vstup : B = Pocet znakov bez CR
;	 DE -> textovy bufer
;Vystup : C = Pocet nacitanych znakov bez CR
;Meni : DE
	ld c,#0
GSLp:
	call inkey
	cp #13
	ret z
	cp #9
	jr z,GSDelete
	ex af,af
	ld b,a
	cp c
	jr z,GSLp
	ex af,af
	ld (de),a
	inc de
	call print64
	jr GSLp

Printcoor:
	.dw	#0

GSDelete:
	ld c,a
	or a
	jr z,GSDelete
	dec de
	push hl
	ld a,#32
	ld hl,(#Printcoor)
	dec h
	ld (#Printcoor),hl
.if 0
	call CharOut
.else
	call print64
.endif
	pop hl
	jr GSLp
	
Str2Ip::
;Konvertovanie textovej ip adresy do binarnej
;Vstup : DE -> Adresa s tetovou IP adresou ukonecna '.' a 0
;	 HL -> Adresa s bufrom na binarnu IP adresu
;Meni  : AF,HL,DE,BC
	ld b,#4
str2iplp:
	ld c,#0
str2iplp2:
	ld a,(de)
	inc de
	or a
	ccf
	ret z
	cp #'.
	jr z,str2ipsk
	sub #'0
	ret c
	cp #10
	ccf
	ret c
	ex af,af
	ld a,c
	add a,a
	ret c
	ld c,a
	add a,a
	ret c
	add a,a
	ret c
	add a,c
	ret c
	ld c,a
	ex af,af
	add a,c
	ret c
	ld c,a
	jr str2iplp2
	
str2ipsk:
	ld (hl),c
	inc hl
	djnz str2iplp
	or a
	ret

inkey::
	ret


