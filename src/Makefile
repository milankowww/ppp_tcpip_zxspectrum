# Makefile for Sinclair ZX Spectrum TCP/IP networking routines.

RM	=	/bin/rm
MV	=	/bin/mv
RMOPTS	=	-f
AS	=	../bin/asz80
ASOPTS	=	-g
LD	=	../bin/aslink
#LDOPTS	=	-i -b MAIN=24500 -m
LDOPTS	=	-i -b MAIN=32768 -m
HEX2TAP	=	../bin/hex2tap
INSTALL	=	../bin/save
MAP2H	=	../bin/map2h.pl

LOADER	=	../bin/loader.tap
OBJS	=	tcpip.o library.o tools.o serial.o ip.o lcp.o ipcp.o icmp.o udp.o tcp.o trash.o application.o

all:	tcpip.tap tcpip.h

install:	all
	$(INSTALL) tcpip.tap


tcpip.h:	tcpip.hex

tcpip.hex:	$(OBJS)
		$(LD) $(LDOPTS) -o tcpip $(OBJS)
		$(MV) tcpip.ihx tcpip.hex
#		$(MAP2H) < tcpip.map > tcpip.h
		-@echo ''
		-@echo 'Area                               Addr   Size   Decimal Bytes (Attributes)'
		-@(grep bytes tcpip.map | grep -v '0000   0000')
		-@echo ''

%.tap:	%.hex
	$(HEX2TAP) $< $@ $(LOADER)

%.o:	%.asm
	$(AS) $(ASOPTS) -o $@ $<

clean:
	$(RM) $(RMOPTS) core *.o *.hex *.tap *~ *.bak *.tmp *.map

count:
	-(find . -name '*.asm';find . -name '*.h') | xargs wc 2>/dev/null

console:
	-@(cd .. ; bin/console)
