	.area MAIN (REL)
	.radix d
.include "config.h"

	ld   a,#136
	out  (#127),a
	call generate_fcs	; generate FCS
	ld   hl,#1200
	ld   (line_idle),hl


	ld hl, #UDP_SOCKS
	ld (hl), #0
	ld de, #UDP_SOCKS + 1
	ld bc, #255
	ldir

	ld hl, #TCP_SOCKS
	ld (hl), #0
	ld de, #TCP_SOCKS + 1
	ld bc, #511
	ldir


	call libinit


.if UDP_CONSOLE
	ld de, #UDP_SOCKS + 0x70
	ld hl, #p64sock
	ld bc, #16
	ldir
	jp appmain
p64sock:
	.db	#UDP_MAGIC1
	.db	#194, #1, #132, #6
	.dw	#0x1200
	.dw	#0x5757
	.dw	#0000
	.dw	#0000
	.dw	#p64sock
	.db	#0
.else
	jp appmain
.endif

line_idle:	.dw	#0
idle_state:	.db	#0

nr_fds::	.db	#0

select_nodata:
	ld   a,(nr_fds)
	and  a,a
	ret  nz

select::
	xor  a
	ld   (nr_fds),a 
	ld   a,#127
	in   a,(#254)
	rra
	ret  nc

; Idle counter - pozor, likwiduje hl ;]

	ld hl,(line_idle)
	dec hl
	ld (line_idle),hl
	ld a,h
	or l
	call z,idle_action

; Tuna mozno niekedy bude vyhaLdzovanie mrtwyx paketow

        ld   hl,#RCVBUFF    ; Tu bude ld na skutocny zaciatok volneho buffra
	di
	.if FLOWCONTROL
	ld   a, #0x08	; stop bity + nase CTS
	out (#SER_IOPORT), a
	.endif
	call bufget
	.if FLOWCONTROL
;ld   a, #0x0c	; stop bity bez CTS - PC2
	ld   a, #0x09	; stop bity bez CTS - PC2
	out (#SER_IOPORT), a
	.endif
	ei
	or a

	call ppp_parser_init

main_ppp_loop::

	call ppp_parser
        jr   c,select_nodata

.if 	DBGRCV
	push af
	push hl
	push de
	dec hl
	dec hl
	dec hl
	dec hl
	inc de
	inc de
	inc de
	inc de
	inc de
	inc de
	call hex_dump 
	ld a,#'G
	call print64
	pop de
	pop hl
	pop af
.endif			; DEBUG

	push hl		; Reset idle
	ld   hl,#1200
	ld   (line_idle),hl
	pop  hl

        cp   #0xc0
        jp   z,rcv_lcp
        cp   #0x80
        jp   z,rcv_ipcp
        cp   #0x00
        jr   z,main_ip
        call ppp_discard          ; discard unknown packet
        jr   main_ppp_loop
main_ip:
        ; ld   de,(parsad)
        ; push de
        call rcv_ip
        ; pop  de
        ; ld   (parsad),de
	jr   main_ppp_loop

idle_action:
	ld a,#'.
	call print64
	ld a,(idle_state)
	cp #0
	; atd, to sa dorobi ;]
	call udp_idle
	call trash_idle
	ret

ppp_discard::
        dec  hl
        ld   (hl),#1               ; set wtl for discard packet
        ret
 
parsad:
	.dw   #0
ppp_parser_init::
	ld   hl,#RCVBUFF
	ld   (parsad),hl
	ret

; OUT: a = typ (LCP, NCP, IP)
; OUT: hl = adresa, de = dlzka, CY, alebo NC
; NICI: ak CY, tak hl, bc

ppp_parser::
	ld   de,(parsad)
	ld   hl,(offset)
	and  a
	sbc  hl,de
	ex   de,hl
        scf
	ret  z
	ld   e,(hl)
	inc  hl
	ld   d,(hl)
	push hl
	dec  hl
	add  hl,de
	ld   (parsad),hl
	pop  hl
	inc  hl

	inc  hl
	ld   a,(hl)
	cp   #2
        jr   c,ppp_parser
	dec  hl
	ld   a,(hl)
	inc  hl

	inc  hl
	dec  de
	dec  de
	dec  de
	dec  de
	dec  de
	dec  de
        and  a
	ret
 
;lcpreq:                ; debug
;	.db   #0x01
;	.db   #0x01,0x00,0x14,0x01,0x04
; 
;	.db   #0x05,0xdc,0x02,0x06,0x00
; 
;	.db   #0x00,0x00,0x00,0x05,0x06
; 
;	.db   #0x17,0x60,0xdd,0x0c
;lcpend:
;
;lcpsiz =    lcpend-lcpreq


