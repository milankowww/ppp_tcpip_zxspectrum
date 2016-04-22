#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <string.h>
#include <netdb.h>

int main(int argc, char * argv[])
{
	int sock, i, size, addrsz;
	struct sockaddr_in sin;
	char buf[16384];
	struct hostent * he;
	struct servent * se;

	if (argc == 3)
		strcpy (buf, "bla :)\n");
	else if (argc == 4) {
		strncpy (buf, argv[3], sizeof(buf));
		buf[sizeof(buf) - 1] = '\0';
	} else {
		fprintf (stderr, "Usage: chargentst addr port\n");
		return -1;
	}
	size = strlen (buf);

	sin.sin_family = AF_INET;
	he = gethostbyname (argv[1]);
	if (he)
		sin.sin_addr.s_addr = *(__u32 *)he->h_addr;
	else
		sin.sin_addr.s_addr = inet_addr(argv[1]);
	se = getservbyname (argv[2], "udp");
	if (se)
		sin.sin_port = se->s_port;
	else
		sin.sin_port = htons(atoi(argv[2]));

	sock = socket (PF_INET, SOCK_DGRAM, 0);
	if (sock == -1) {
		fprintf (stderr, "Cannot create socket\n");
		return -1;
	}
	addrsz = sizeof (struct sockaddr_in);
	//while (1) i = sendto (sock, buf, size, 0, (struct sockaddr *)&sin, addrsz);
	i = sendto (sock, buf, size, 0, (struct sockaddr *)&sin, addrsz);
	printf ("SendTo: %d\n", i);
	while (1) {
		addrsz = sizeof (struct sockaddr_in);
		size = recvfrom (sock, buf, sizeof(buf), 0,
			(struct sockaddr *)&sin, &addrsz);
		printf ("recvfrom = %d\n%d.%d.%d.%d\n",
			size,
			((char *)&sin.sin_addr.s_addr)[0],
			((char *)&sin.sin_addr.s_addr)[1],
			((char *)&sin.sin_addr.s_addr)[2],
			((char *)&sin.sin_addr.s_addr)[3]
		);
		for (i = 0; i < size; i++)
			printf ("%s%.2x", i&15 ? " " : "\n", buf[i]);
		for (i = 0; i < size; i++)
			printf ("%s%c", i&15 ? " " : "\n",
				(buf[i] > 31) && (buf[i] < 127) ? buf[i] : '.'
			);
		puts ("");
	}
}
