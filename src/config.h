;;
;; Global Configuration File
;;
;; !!! DO NOT PUT ANY DATA HERE !!! Only definitions are allowed.
;;
;

;; if you have compile errors on ".include config.h", look at the end of
;; this file.

;; Debug... Isn't it clear?
DEBUG		= 1
DEBUGTCP	= 1
DEBUGSER	= 0
UDP_CONSOLE	= 0

;; write all incomming PPP frames
DBGRCV		= 0

;; write all outgoing IP packets
DBGSEND		= 0

;;;;; [ SERIAL DEVICE ] ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; this enables use of the hardware flow control (RTS/CTS)
;; in serial line drivers.
FLOWCONTROL	= 1
;; this is the default port for IO
SER_IOPORT	= 0x5b

;; 512b buffer for FCS (checksum of PPP frames). Have to be padded
;; to 512 bytes
FCSTAB		= 0xEE00
FCSTABHI	= >FCSTAB / 2

;; 3k buffer for PPP input
RCVBUFF		= 0xF100
RCVENDHI	= >RCVBUFF + 0x0C

;;;;; [ IP LAYER OPTIONS ] ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; define this to 1, if the other side sends not only IPv4 packets
;; over "IPLAYER" PPP frame
CHECK_IPv4_TYPE	= 1

;; write 1 here, if you want to have UDP sockets, able to listen on
;; given port for connects
CONFIG_PASSIVE_UDP = 1

IP_ICMP = 1
IP_TCP = 6
IP_UDP = 17



;;;;; [ ICMP LAYER OPTIONS ] ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; define TTL for ICMP packets
ICMP_TTL = 64

ICMP_ECHOREPLY		= 0
ICMP_DEST_UNREACH	= 3
ICMP_SOURCE_QUENCH	= 4
ICMP_REDIRECT		= 5
ICMP_ECHO		= 8
ICMP_TIME_EXCEEDED	= 11
ICMP_PARAMETERPROB	= 12
ICMP_TIMESTAMP		= 13
ICMP_TIMESTAMPREPLY	= 14
ICMP_INFO_REQUEST	= 15
ICMP_INFO_REPLY		= 16
ICMP_ADRESS		= 17
ICMP_ADDRESSREPLY	= 18

ICMP_NET_UNREACH	= 0
ICMP_HOST_UNREACH	= 1
ICMP_PROT_UNREACH	= 2
ICMP_PORT_UNREACH	= 3
ICMP_FRAG_NEEDED	= 4
ICMP_SR_FAILED		= 5
ICMP_NET_UNKNOWN	= 6
ICMP_HOST_UNKNOWN	= 7
ICMP_HOST_ISOLATED	= 8
ICMP_NET_ANO		= 9
ICMP_HOST_ANO		= 10
ICMP_NET_UNR_TOS	= 11
ICMP_HOST_UNR_TOS	= 12
ICMP_PKT_FILTERED	= 13
ICMP_PREC_VIOLATION	= 14
ICMP_PREC_CUTOFF	= 15

;;;;; [ UDP LAYER OPTIONS ] ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CONF_UDP	=	1
CONF_TCP	=	1
UDP_SOCKS	=	0xED00
UDP_SOCKSHI	=	>UDP_SOCKS
TCP_SOCKS	=	0xEB00
TCP_SOCKSHI	=	>TCP_SOCKS

.if 0
tcpmux		1/tcp		# TCP port service multiplexer
echo		7/tcp
echo		7/udp
discard		9/tcp		sink null
discard		9/udp		sink null
systat		11/tcp		users
daytime		13/tcp
daytime		13/udp
netstat		15/tcp
qotd		17/tcp		quote
msp		18/tcp		# message send protocol
msp		18/udp		# message send protocol
chargen		19/tcp		ttytst source
chargen		19/udp		ttytst source
ftp		21/tcp
telnet		23/tcp
smtp		25/tcp		mail
time		37/tcp		timserver
time		37/udp		timserver
rlp		39/udp		resource	# resource location
nameserver	42/tcp		name		# IEN 116
whois		43/tcp		nicname
domain		53/tcp		nameserver	# name-domain server
domain		53/udp		nameserver
mtp		57/tcp				# deprecated
bootps		67/tcp		# BOOTP server
bootps		67/udp
bootpc		68/tcp		# BOOTP client
bootpc		68/udp
tftp		69/udp
gopher		70/tcp		# Internet Gopher
gopher		70/udp
rje		77/tcp		netrjs
finger		79/tcp
www		80/tcp		http	# WorldWideWeb HTTP
www		80/udp			# HyperText Transfer Protocol
link		87/tcp		ttylink
kerberos	88/tcp		krb5	# Kerberos v5
kerberos	88/udp
supdup		95/tcp
hostnames	101/tcp		hostname	# usually from sri-nic
iso-tsap	102/tcp		tsap		# part of ISODE.
csnet-ns	105/tcp		cso-ns	# also used by CSO name server
csnet-ns	105/udp		cso-ns
rtelnet		107/tcp		# Remote Telnet
rtelnet		107/udp
pop2		109/tcp		postoffice	# POP version 2
pop2		109/udp
pop3		110/tcp		# POP version 3
pop3		110/udp
sunrpc		111/tcp
sunrpc		111/udp
auth		113/tcp		tap ident authentication
sftp		115/tcp
uucp-path	117/tcp
nntp		119/tcp		readnews untp	# USENET News Transfer Protocol
ntp		123/tcp
ntp		123/udp				# Network Time Protocol
netbios-ns	137/tcp				# NETBIOS Name Service
netbios-ns	137/udp
netbios-dgm	138/tcp				# NETBIOS Datagram Service
netbios-dgm	138/udp
netbios-ssn	139/tcp				# NETBIOS session service
netbios-ssn	139/udp
imap2		143/tcp				# Interim Mail Access Proto v2
imap2		143/udp
snmp		161/udp				# Simple Net Mgmt Proto
snmp-trap	162/udp		snmptrap	# Traps for SNMP
cmip-man	163/tcp				# ISO mgmt over IP (CMOT)
cmip-man	163/udp
cmip-agent	164/tcp
cmip-agent	164/udp
xdmcp		177/tcp				# X Display Mgr. Control Proto
xdmcp		177/udp
nextstep	178/tcp		NeXTStep NextStep	# NeXTStep window
nextstep	178/udp		NeXTStep NextStep	# server
bgp		179/tcp				# Border Gateway Proto.
bgp		179/udp
prospero	191/tcp				# Cliff Neuman's Prospero
prospero	191/udp
irc		194/tcp				# Internet Relay Chat
irc		194/udp
smux		199/tcp				# SNMP Unix Multiplexer
smux		199/udp
at-rtmp		201/tcp				# AppleTalk routing
at-rtmp		201/udp
at-nbp		202/tcp				# AppleTalk name binding
at-nbp		202/udp
at-echo		204/tcp				# AppleTalk echo
at-echo		204/udp
at-zis		206/tcp				# AppleTalk zone information
at-zis		206/udp
z3950		210/tcp		wais		# NISO Z39.50 database
z3950		210/udp		wais
ipx		213/tcp				# IPX
ipx		213/udp
imap3		220/tcp				# Interactive Mail Access
imap3		220/udp				# Protocol v3
ulistserv	372/tcp				# UNIX Listserv
ulistserv	372/udp
exec		512/tcp
biff		512/udp		comsat
login		513/tcp
who		513/udp		whod
shell		514/tcp		cmd		# no passwords used
syslog		514/udp
printer		515/tcp		spooler		# line printer spooler
talk		517/udp
ntalk		518/udp
route		520/udp		router routed	# RIP
timed		525/udp		timeserver
tempo		526/tcp		newdate
courier		530/tcp		rpc
conference	531/tcp		chat
netnews		532/tcp		readnews
netwall		533/udp				# -for emergency broadcasts
uucp		540/tcp		uucpd		# uucp daemon
remotefs	556/tcp		rfs_server rfs	# Brunhoff remote filesystem
klogin		543/tcp				# Kerberized `rlogin' (v5)
kshell		544/tcp				# Kerberized `rsh' (v5)
kerberos-adm	749/tcp				# Kerberos `kadmin' (v5)
webster		765/tcp				# Network dictionary
webster		765/udp
ingreslock	1524/tcp
ingreslock	1524/udp
prospero-np	1525/tcp		# Prospero non-privileged
prospero-np	1525/udp
rfe		5002/tcp		# Radio Free Ethernet
rfe		5002/udp		# Actually uses UDP only
krbupdate	760/tcp		kreg	# Kerberos registration
kpasswd		761/tcp		kpwd	# Kerberos "passwd"
eklogin		2105/tcp		# Kerberos encrypted rlogin
supfilesrv	871/tcp			# SUP server
supfiledbg	1127/tcp		# SUP debugging
.endif

.if UDP_CONSOLE
.if DBGSEND
CHYBA	CHYBA		DBGSEND nesmie byt zapnuty pri UDP_CONSOLE
.endif
.endif

