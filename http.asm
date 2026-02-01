
; http.asm

default rel

global h_line_delim
global h_hdr_delim
global h_ver
global h_200
global h_400
global h_404
global h_hdr_conn
global h_hdr_cont_len
global h_hdr_cont_type
global mime_type_text_css
global mime_type_text_html
global mime_type_text_js
global mime_type_text_plain
global mime_type_image_jpeg
global mime_type_image_png
global mime_type_image_xicon
global mime_type_table

%include "http.inc"

section .rodata:
	h_line_delim		db 13, 10
	h_hdr_delim			db ": "

	h_ver		db "HTTP/1.1 "

	h_200		db "200 OK", 13, 10
	h_400		db "400 Bad Request", 13, 10
	h_404		db "404 Not Found", 13, 10

	h_hdr_conn				db "Connection: "
	h_hdr_conn_close		db "close", 13, 10

	h_hdr_cont_len			db "Content-Length: "

	h_hdr_cont_type			db "Content-Type: "

	mime_type_text_css			db "text/css", 13, 10
	mime_type_text_html			db "text/html", 13, 10
	mime_type_text_js			db "text/javascript", 13, 10
	mime_type_text_plain		db "text/plain", 13, 10
	mime_type_image_jpeg		db "image/jpeg", 13, 10
	mime_type_image_png			db "image/png", 13, 10
	mime_type_image_xicon		db "image/x-icon", 13, 10

	align 16
	mime_type_table:
		dq 'html',	mime_type_text_html,	MIME_TYPE_TEXT_HTML_SIZE
		dq 'css',	mime_type_text_css,		MIME_TYPE_TEXT_CSS_SIZE
		dq 'js',	mime_type_text_js,		MIME_TYPE_TEXT_JS_SIZE
		dq 'png',	mime_type_image_png,	MIME_TYPE_IMAGE_PNG_SIZE
		dq 'ico',	mime_type_image_xicon,	MIME_TYPE_IMAGE_XICON_SIZE

