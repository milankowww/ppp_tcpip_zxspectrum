#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <string.h>
#include <netdb.h>
#include <asm/byteorder.h>

int pos = 0;

struct dbg_s {
	__u8	type;
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
};

void charin(char c)
{
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
}

void dumpregs (struct set_s * set)
{
	printf ("F: sign:%s, zero:%s, %s, %s, %s, %s, %s, %s\n",
			set->f.sign ? "M" : "p",
			set->f.zero ? "Z": "nz",
			set->f.uu1 ? "UU1" : "uu1",
			set->f.axcy ? "AXCY" : "naxcy",
			set->f.uu2 ? "UU2" : "uu2",
			set->f.parity ? "PE" : "po",
			set->f.uu3 ? "UU3" : "uu3",
			set->f.carry ? "CY" : "nc"
	);
	printf ("A: %d(0x%.2x)  BC: %d(0x%.4x)  "
		"DE: %d(0x%.4x)  HL: %d(0x%.4x)\n",
		set -> a,
		set -> a,
		set -> bc,
		set -> bc,
		set -> de,
		set -> de,
		set -> hl,
		set -> hl
	);
}

void debug(struct dbg_s * dbg)
{
	printf ("\nDEBUG at PC=%d(0x%.4x), SP=%d(0x%.4x)\n",
			dbg->pc - 3, dbg -> pc - 3,
			dbg->sp, dbg->sp
	);
	dumpregs(&(dbg->set1));
	dumpregs(&(dbg->set2));
}
	
void main(void)
{
	struct sockaddr_in sin, syn;
	int sock;
	unsigned char buf[4096];

	int size, i;

	syn.sin_family = AF_INET;
	syn.sin_port   = htons(0x12);
	syn.sin_addr.s_addr = inet_addr("194.1.133.125");
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
		if (buf[0] == (unsigned char)31)
			debug((struct dbg_s *)buf);
		else
			for (i=0; i < size; i++)
				charin(buf[i]);
	}
}

