
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
RES_HDRS_BUF_SIZE	equ 1024
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
	req_buf				resb REQ_BUF_SIZE
	res_hdrs_buf		resb RES_HDRS_BUF_SIZE
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
	je		.exit
	SYSCALL_ACCEPT	[srv_fd], srv_handler, [cli_fd]
	SYSCALL_FORK	cli_handler
	SYSCALL_CLOSE	[cli_fd]
	jmp		srv_handler
.exit:
	SYSCALL_CLOSE	[srv_fd]
	jmp		exit_success

cli_handler:
	SYSCALL_CLOSE	[srv_fd]
.loop:
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

	lea		rdi, [res_hdrs_buf]

	mov		rsi, h_ver
	mov		rcx, H_VER_SIZE
	rep movsb

	mov		rsi, h_200
	mov		rcx, H_200_SIZE
	rep movsb

	mov		rsi, h_line_delim
	mov		rcx, H_LINE_DELIM_SIZE
	rep movsb

	mov		rsi, h_hdr_cont_len
	mov		rcx, H_HDR_CONT_LEN_SIZE
	rep movsb

	mov		rsi, h_hdr_delim
	mov		rcx, H_HDR_DELIM_SIZE
	rep movsb

	mov		rax, [file_stat + stat_t.st_size]
	call	append_uint

	mov		rsi, h_line_delim
	mov		rcx, H_LINE_DELIM_SIZE
	rep movsb

	mov		rsi, h_hdr_cont_type
	mov		rcx, H_HDR_CONT_TYPE_SIZE
	rep movsb

	mov		rsi, h_hdr_delim
	mov		rcx, H_HDR_DELIM_SIZE
	rep movsb

	; Determine the correct mime type to use.


	mov		rsi, mime_type_text_html
	mov		rcx, MIME_TYPE_TEXT_HTML_SIZE
	rep movsb

	mov		rsi, h_line_delim
	mov		rcx, H_LINE_DELIM_SIZE
	rep movsb

	mov		rsi, h_line_delim
	mov		rcx, H_LINE_DELIM_SIZE
	rep movsb

	lea		rax, [res_hdrs_buf]
	sub		rdi, rax
	mov		r8, rdi

	SYSCALL_WRITE		[cli_fd], [res_hdrs_buf], r8, .close_and_exit
	SYSCALL_SENDFILE	[cli_fd], [file_fd], .close_and_exit
	SYSCALL_CLOSE		[file_fd]
	jmp		.loop
.close_and_exit:
	SYSCALL_CLOSE	[cli_fd]
	jmp		exit_success

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

copy_string:
	mov		al, [rsi]
	inc		rsi
	test	al, al
	jz		.done
	mov		[rdi], al
	inc		rdi
	jmp		copy_string
.done:
	ret

sigint_restorer:
	SYSCALL_RT_SIGRETURN

sigint_handler:
	mov		byte [sigint_flag], 1
	ret

exit_success:
	SYSCALL_EXIT_SUCCESS

exit_failure:
	SYSCALL_EXIT_FAILURE

