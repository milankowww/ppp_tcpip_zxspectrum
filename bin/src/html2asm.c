#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>

int main(int argc, char * argv[])
{
	FILE * f1, * f2 = NULL;
	struct stat st;
	char buf[8];
	int i, j;

	if (argc == 5)
		argc++, f2 = stdout;
	if (argc != 6) {
		fprintf (stdout, "%s in_file label mimetype response [out_file]\n", argv?*argv:"html2asm");
		return -1;
	}

	if (stat(argv[1], &st)) {
		fprintf (stdout, "Cannot stat()\n");
		return -1;
	}
	f1 = fopen(argv[1], "rb");
	if (!f2)
		f2 = fopen(argv[5], "w+b");
	if (!f1 || !f2) {
		fprintf (stdout, "Cannot open %sput file\n", f1?"out":"in");
		return -1;
	}
	fprintf (f2, "%s::\n", argv[2]);
	fprintf (f2,
			"\t.ascii 'HTTP/1.0 %s'\n"		"\t.db 13, 10\n"
			"\t.ascii 'Server: Spectrum/48+'\n"	"\t.db 13, 10\n"
			"\t.ascii 'Connection: close'\n"	"\t.db 13, 10\n"
			"\t.ascii 'Content-Length: %d'\n"	"\t.db 13, 10\n"
			"\t.ascii 'Content-Type: %s'\n"		"\t.db 13, 10\n"
			"\t.db 13, 10\n",
		argv[4], (int)st.st_size, argv[3]
	);

	while ((i=fread(buf, 1, sizeof(buf), f1))>0) {
		fprintf (f2, "\t.db ");
		for (j=0; j<i; j++)
			fprintf (f2, "%s0x%.2x", j?", ":"", (int)((unsigned char *)buf)[j]);
		fprintf (f2, "\n");
	}
	fprintf (f2, "%sSIZ == . - %s", argv[2], argv[2]);
	fclose(f2);
	return 0;
}
