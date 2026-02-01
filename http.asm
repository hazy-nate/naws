
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
global mime_type_image_jpeg
global mime_type_image_png
global mime_type_image_xicon
global mime_table_ext

%include "http.inc"

section .rodata:
	h_line_delim		db 13, 10
	h_hdr_delim			db ": "

	h_ver		db "HTTP/1.1 "

	h_200		db "200 OK"
	h_400		db "400 Bad Request"
	h_404		db "404 Not Found"

	h_hdr_conn				db "Connection"
	h_hdr_conn_close		db "close"

	h_hdr_cont_len			db "Content-Length"

	h_hdr_cont_type			db "Content-Type"

	mime_type_text_css			db "text/css"
	mime_type_text_html			db "text/html"
	mime_type_text_js			db "text/javascript"
	mime_type_image_jpeg		db "image/jpeg"
	mime_type_image_png			db "image/png"
	mime_type_image_xicon		db "image/x-icon"

