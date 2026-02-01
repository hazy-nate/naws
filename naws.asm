
; naws.asm

default rel

global _start
extern h_line_delim
extern h_hdr_delim
extern h_ver
extern h_200
extern h_400
extern h_404
extern h_hdr_conn
extern h_hdr_cont_len
extern h_hdr_cont_type
extern mime_type_text_css
extern mime_type_text_html
extern mime_type_text_js
extern mime_type_image_jpeg
extern mime_type_image_png
extern mime_type_image_xicon

%include "naws.inc"
%include "http.inc"
%include "util.inc"

REQ_BUF_SIZE		equ 1024
RES_HDRS_IOVEC_CNT	equ 16
RES_CONT_BUF_SIZE	equ 1024

section .data
	sigint_sigaction: istruc sigaction_t
		at sigaction_t.sa_handler,	dq sigint_handler
		at sigaction_t.sa_flags,	dq SA_NOCLDWAIT | SA_RESTORER
		at sigaction_t.sa_restorer, dq sigint_restorer
		at sigaction_t.sa_mask,		dq 0
	iend
	sigint_flag db 0
	srv_sockaddr_in6: istruc sockaddr_in6_t
		at sockaddr_in6_t.sin6_family,		dw AF_INET6
		at sockaddr_in6_t.sin6_port,		dw htons(PORT)
		at sockaddr_in6_t.sin6_flowinfo,	dd 0
		at sockaddr_in6_t.sin6_addr,		dq 0, 0
		at sockaddr_in6_t.sin6_scope_id,	dd 0
	iend
	srv_sockopt_ipv6only	dd 0
	srv_sockopt_reuseaddr	dd 1

section .bss
	srv_fd				resd 1
	cli_fd				resd 1
	file_fd				resd 1
	file_stat			resb stat_t_size
	file_size_str		resb 10
	req_buf				resb REQ_BUF_SIZE
	res_hdrs_iovec		resb iovec_t_size * RES_HDRS_IOVEC_CNT
	res_cont_buf		resb RES_CONT_BUF_SIZE

section .rodata
	index_fp	db INDEX, 0
	server		db SERVER

section .text
_start:
	SYSCALL_RT_SIGACTION SIGINT, [sigint_sigaction]
	SYSCALL_SOCKET		AF_INET6, SOCK_STREAM, 0, exit_failure, [srv_fd]
	SYSCALL_SETSOCKOPT	[srv_fd], IPPROTO_IPV6, IPV6_V6ONLY, srv_sockopt_ipv6only, 4, exit_failure
	SYSCALL_SETSOCKOPT	[srv_fd], SOL_SOCKET, SO_REUSEADDR, srv_sockopt_reuseaddr, 4, exit_failure
	SYSCALL_BIND		[srv_fd], srv_sockaddr_in6, sockaddr_in6_t_size, exit_failure
	SYSCALL_LISTEN		[srv_fd], 10, exit_failure

srv_handler:
	cmp		byte [sigint_flag], 1	; Exit if SIGINT signal has been received.
	je		.close_and_exit
	SYSCALL_ACCEPT	[srv_fd], srv_handler, [cli_fd]
	SYSCALL_FORK	cli_handler
	SYSCALL_CLOSE	[cli_fd]
	jmp		srv_handler
.close_and_exit:
	SYSCALL_CLOSE	[srv_fd]
	jmp		exit_success

; JUMP:		cli_handler.
; DESC:		When a new client connects to the server, the process is forked and
;			the child begins execution here.
cli_handler:
	SYSCALL_CLOSE	[srv_fd]
.loop:
	cmp		byte [sigint_flag], 1	; Exit if SIGINT signal has been received.
	je		.close_and_exit
	SYSCALL_READ	[cli_fd], [req_buf], REQ_BUF_SIZE, jle, .close_and_exit
	cmp		dword [rsi], 'GET '
	je		.get_req
	jmp		.loop
.get_req:
	lodsd
	mov		rdi, rsi
	mov		rcx, REQ_BUF_SIZE
	mov		al, ' '
	repne scasb
	jne		.close_and_exit
	dec		rdi
	mov		byte [rdi], 0
	inc		rsi
	cmp		byte [rsi], 0
	jne		.get_req_file
	lea		rsi, [index_fp]
.get_req_file:
	SYSCALL_OPEN_RDONLY	[rsi], .close_and_exit, [file_fd]
	SYSCALL_FSTAT		[file_fd], file_stat, .close_and_exit

	lea		r13, [res_hdrs_iovec]
	xor		r12, r12

	mov		rsi, h_ver
	mov		rdx, H_VER_SIZE
	call	append_iovec

	mov		rsi, h_200
	mov		rdx, H_200_SIZE
	call	append_iovec

	mov		rsi, h_line_delim
	mov		rdx, H_LINE_DELIM_SIZE
	call	append_iovec

	mov		rsi, h_hdr_cont_len
	mov		rdx, H_HDR_CONT_LEN_SIZE
	call	append_iovec

	mov		rsi, h_hdr_delim
	mov		rdx, H_HDR_DELIM_SIZE
	call	append_iovec

	mov		rax, [file_stat + stat_t.st_size]
	mov		rdi, file_size_str
	call	append_uint
	mov     rsi, file_size_str
    lea     rdx, [file_size_str]
    neg     rdx
    add     rdx, rdi
    call    append_iovec

	mov		rsi, h_line_delim
	mov		rdx, H_LINE_DELIM_SIZE
	call	append_iovec

	mov		rsi, h_hdr_cont_type
	mov		rdx, H_HDR_CONT_TYPE_SIZE
	call	append_iovec

	mov		rsi, h_hdr_delim
	mov		rdx, H_HDR_DELIM_SIZE
	call	append_iovec

	; TODO: Determine the correct mime type to use.

	mov		rsi, mime_type_text_html
	mov		rdx, MIME_TYPE_TEXT_HTML_SIZE
	call	append_iovec

	mov		rsi, h_line_delim
	mov		rdx, H_LINE_DELIM_SIZE
	call	append_iovec

	mov		rsi, h_line_delim
	mov		rdx, H_LINE_DELIM_SIZE
	call	append_iovec

	SYSCALL_WRITEV		[cli_fd], res_hdrs_iovec, r12, .close_and_exit
	SYSCALL_SENDFILE	[cli_fd], [file_fd], .close_and_exit
	SYSCALL_CLOSE		[file_fd]
	jmp		.loop
.close_and_exit:
	SYSCALL_CLOSE	[cli_fd]
	jmp		exit_success

; FUNCTION:	append_uint.
; DESC:		Writes an unsigned integer as a string to a buffer.
; ARGS:
;	RAX	->	Integer to convert.
;	RDI	->	Pointer to start within buffer.
; RETURNS:
;	RDI	->	Pointer to byte after the last digit within the buffer.
append_uint:
    push    rbx
    push    rcx
    push    rdx
    mov     rbx, 10
    xor     rcx, rcx
.div_loop:
    xor     rdx, rdx
    div     rbx
    push    rdx
    inc     rcx
    test    rax, rax
    jnz     .div_loop
.write_loop:
    pop     rax
    add     al, '0'
    stosb
    loop    .write_loop
    pop     rdx
    pop     rcx
    pop     rbx
    ret

; FUNCTION:	append_iovec.
; DESC:		Inserts a new entry into an iovec array and increments the counter.
; ARGS:
;	R13 ->	Pointer to start of iovec array.
;	RSI	->	Pointer to start within buffer.
;	RDX ->	Length of buffer.
;	R12 ->	Current number of segments.
; RETURNS:
;	R12 ->	Incremented number of segments.
append_iovec:
	mov		rax, r12
	shl		rax, 4
	mov		[r13 + rax + iovec_t.iov_base], rsi
	mov		[r13 + rax + iovec_t.iov_len], rdx
	inc		r12
	ret

; JUMP:		sigint_restorer.
; DESC:		Makes a SYS_RT_SIGRETURN syscall.
; NOTES:	This procedure is stored as the .sa_restorer for the
;			sigint_sigaction struct.
sigint_restorer:
	SYSCALL_RT_SIGRETURN

; FUNCTION: sigint_handler.
; DESC:		Turns on the sigint_flag.
; NOTES:	Once the sigint_flag is set, the server and child loops terminate.
sigint_handler:
	mov		byte [sigint_flag], 1
	ret

; JUMP:		exit_success.
; DESC:		Makes a SYS_EXIT syscall with a status of 0.
exit_success:
	SYSCALL_EXIT_SUCCESS

; JUMP:		exit_failure.
; DESC:		Makes a SYS_EXIT syscall with a status of 1.
exit_failure:
	SYSCALL_EXIT_FAILURE

