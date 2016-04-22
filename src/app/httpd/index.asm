; this file contains directory of httpd and it's included by httpd.asm.

directory::
	.asciz	"/"
	.dw	h_index
	.dw	h_indexSIZ

	.asciz	"/index.html"
	.dw	h_index
	.dw	h_indexSIZ

	.asciz	"/error.gif"
	.dw	h_errg
	.dw	h_errgSIZ

	.asciz	"/bg1.gif"
	.dw	h_bg1
	.dw	h_bg1SIZ

	.asciz	"/bg2.gif"
	.dw	h_bg2
	.dw	h_bg2SIZ

	.db	0
	.dw	h_error
	.dw	h_errorSIZ

.include "app/httpd/index_html.inc"
.include "app/httpd/error_gif.inc"
.include "app/httpd/bg1_gif.inc"
.include "app/httpd/bg2_gif.inc"
.include "app/httpd/error_html.inc"

