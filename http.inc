
; http.inc

%ifndef HTTP_INC
%define HTTP_INC

; === Lengths === ;

H_LINE_DELIM_SIZE   equ 2
H_HDR_DELIM_SIZE    equ 2

H_VER_SIZE              equ 9
H_200_SIZE              equ 8
H_400_SIZE              equ 17
H_404_SIZE              equ 15
H_HDR_CONN_SIZE         equ 12
H_HDR_CONT_LEN_SIZE     equ 16
H_HDR_CONT_TYPE_SIZE    equ 14

MIME_TYPE_TEXT_CSS_SIZE     equ 10
MIME_TYPE_TEXT_HTML_SIZE    equ 11
MIME_TYPE_TEXT_JS_SIZE      equ 17
MIME_TYPE_TEXT_PLAIN_SIZE   equ 12
MIME_TYPE_IMAGE_JPEG_SIZE   equ 12
MIME_TYPE_IMAGE_PNG_SIZE    equ 11
MIME_TYPE_IMAGE_XICON_SIZE  equ 14
MIME_TYPE_TABLE_CNT         equ 5

; === Magic bytes. === ;

MAGIC_PNG   equ 0x474E5089
MAGIC_JPG   equ 0xE0FFD8FF
MAGIC_GIF   equ 0x38464947

%endif

