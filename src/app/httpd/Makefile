H2A = ../../../bin/html2asm

all:	include


include:	htdocs/index.html htdocs/error.html htdocs/error.gif htdocs/bg1.gif htdocs/bg2.gif
	$(H2A) htdocs/index.html h_index "text/html" "200 OK" index_html.inc
	$(H2A) htdocs/error.html h_error "text/html" "404 File Not Found" error_html.inc
	$(H2A) htdocs/error.gif h_errg "image/gif" "200 OK" error_gif.inc
	$(H2A) htdocs/bg1.gif h_bg1 "image/gif" "200 OK" bg1_gif.inc
	$(H2A) htdocs/bg2.gif h_bg2 "image/gif" "200 OK" bg1_gif.inc

clean:
	rm -f *.inc
