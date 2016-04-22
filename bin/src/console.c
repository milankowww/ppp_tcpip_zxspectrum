#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <string.h>
#include <netdb.h>
#include <asm/byteorder.h>
#include <fcntl.h>
#include <sys/ioctl.h>

int pos = 0;
int sock;
FILE * fdebug;
size_t limit;

struct dbg_s {
	__u16	type;
	__u16	sp;
	struct set_s {
		__u16	hl;
		__u16	de;
		__u16	bc;
	struct f_s {
#if defined(__LITTLE_ENDIAN_BITFIELD)
		__u8	sign:1,
			zero:1,
			uu1:1,
			axcy:1,
			uu2:1,
			parity:1,
			uu3:1,
			carry:1;
#elif defined(__BIG_ENDIAN_BITFIELD)
		__u8	carry:1,
			uu3:1,
			parity:1,
			uu2:1,
			axcy:1,
			uu1:1,
			zero:1,
			sign:1;
#else
#error "Please fix <asm/byteorder.h>"
#endif
		} f;
		__u8	a;
	} set1, set2;
	__u16	pc;
	__u16	ix;
	__u16	iy;
};

void charin(char c)
{
	c &= 127;
	if (c < 31) switch (c) {
		case 13:
			pos = 0;
			puts("");
			break;
		default:
	} else {
		printf ("%c", c);
		pos = (pos+1)%64;
		if (!pos)
			puts("");
	}
	fflush(stdout);
}

void hexdump(struct dbg_s * hex)
{
	int size, i;
	unsigned char buf[16384];

	size = recv(sock, buf, sizeof(buf), MSG_OOB);
	if (size == -1) {
		fprintf (stderr, "ERR\n");
		return;
	}
	fprintf (fdebug, "\n--= HEXDUMP ==-\nAddr: %5d 0x%.4x\t\t"
		"Size: %5d 0x%.4x",
		hex->sp, hex->sp,
		size, size
	);
	for (i = 0; i < size; i++) {
		fprintf(fdebug, "%s%.2x",
			(i%16)?" ":"\n",
			buf[i]
		);
	}
	fprintf(fdebug, "\n");
	fflush(fdebug);
}

void dumpregs (struct set_s * set)
{
	fprintf (fdebug,
		"A: %3d 0x%.2x\n"
		"BC: %5d 0x%.4x\t"
		"DE: %5d 0x%.4x\t"
		"HL: %5d 0x%.4x\n",
		set -> a,
		set -> a,
		set -> bc,
		set -> bc,
		set -> de,
		set -> de,
		set -> hl,
		set -> hl
	);
	fprintf (fdebug,"F:\tSIGN %s\t\tZERO %s\n\tUNUSED %s\t\tAUXCARRY %s\n"
		"\tUNUSED %s\t\tPARITY %s\n\tUNUSED %s\t\tCARRY %s\n",
			set->f.sign ? "1=M" : "0=P",
			set->f.zero ? "1=Z": "0=NZ",
			set->f.uu1 ? "1=UU" : "0=UU",
			set->f.axcy ? "1=AXCY" : "0=NAXCY",
			set->f.uu2 ? "1=UU2" : "0=UU",
			set->f.parity ? "1=PE" : "0=PO",
			set->f.uu3 ? "1=UU3" : "0=UU",
			set->f.carry ? "1=CY" : "0=NC"
	);
}

void debug(struct dbg_s * dbg)
{
	fprintf (fdebug,"\n--= DEBUG ==-\nPC: %5d(0x%.4x)\t\tSP: %5d(0x%.4x)\n",
			dbg->pc - 3, dbg -> pc - 3,
			dbg->sp, dbg->sp
	);
	dumpregs(&(dbg->set1));
	dumpregs(&(dbg->set2));
	fprintf (fdebug,"IX: %5d(0x%.4x), IY: %5d(0x%.4x)\n\n",
			dbg->ix, dbg->ix,
			dbg->iy, dbg->iy
			);
	fflush(fdebug);
}
	
void main(void)
{
	struct sockaddr_in sin, syn;
	unsigned char buf[4096];

	int size, i;

	fdebug = fopen("console.debug", "ab");
	if (!fdebug)
		fdebug = stdout;

	syn.sin_family = AF_INET;
	syn.sin_port   = htons(0x12);
	syn.sin_addr.s_addr = inet_addr("194.1.132.6");
	sin.sin_family = AF_INET;
	sin.sin_port   = htons(0x5757);
	sin.sin_addr.s_addr = inet_addr("194.1.133.126");
	sock = socket (PF_INET, SOCK_DGRAM, 0);
	if (sock == -1) {
		fprintf (stderr, "Cannot create socket\n");
		return;
	}
	printf ("%d\n", bind(sock, (struct sockaddr *)&syn, sizeof(struct sockaddr_in)));
	printf ("%d\n", connect(sock, (struct sockaddr *)&sin, sizeof(struct sockaddr_in)));
	while (1) {
		size = recv(sock, buf, sizeof(buf), MSG_OOB);
		if (size == -1) {
			fprintf (stderr, "ERR\n");
			return;
		}
		switch (buf[0]) {
		case 31:
			debug((struct dbg_s *)buf);
			break;
		case 30:
			hexdump((struct dbg_s *)buf);
		default:
			for (i=0; i < size; i++)
				charin(buf[i]);
		}
	}
}

