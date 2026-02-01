
; http.inc

%ifndef HTTP_INC
%define HTTP_INC

; === Lengths === ;

H_LINE_DELIM_SIZE   equ 2
H_HDR_DELIM_SIZE    equ 2

H_VER_SIZE              equ 9
H_200_SIZE              equ 6
H_400_SIZE              equ 15
H_404_SIZE              equ 13
H_HDR_CONN_SIZE         equ 10
H_HDR_CONT_LEN_SIZE     equ 14
H_HDR_CONT_TYPE_SIZE    equ 12

MIME_TYPE_TEXT_CSS_SIZE     equ 8
MIME_TYPE_TEXT_HTML_SIZE    equ 9
MIME_TYPE_TEXT_JS_SIZE      equ 15
MIME_TYPE_IMAGE_JPEG_SIZE   equ 10
MIME_TYPE_IMAGE_PNG_SIZE    equ 9
MIME_TYPE_IMAGE_XICON_SIZE  equ 12

; === File extensions. === ;

EXT_CSS     equ 0x2e637373
EXT_HTML    equ 0x68746d6c
EXT_JS      equ 0x2e6a7300

; === Magic bytes. === ;

MAGIC_PNG   equ 0x474E5089
MAGIC_JPG   equ 0xE0FFD8FF
MAGIC_GIF   equ 0x38464947

%endif

