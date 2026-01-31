
; naws.asm

default rel
global _start

%include "naws.inc"
%include "util.inc"

REQUEST_BUF_SIZE equ 1024

section .data

	received_sigint db 0

	srv_sockaddr_in6:
		dw AF_INET6	; sin6_family:		AF_INET.
		dw PORT		; sin6_port:		8080.
		dd 0		; sin6_flowinfo:	0.
		dq 0, 0		; sin6_addr:		0.
		dd 0		; sin6_scope_id:	0.

	srv_sockopt_ipv6only dd 0
	srv_sockopt_reuseaddr dd 1

section .bss
	sigint_act	resb sigaction_t_size
	srv_fd		resd 1
	cli_fd		resd 1
	request_buf resb REQUEST_BUF_SIZE

section .text
align 16
_start:
	; Set up signal actions.
	lea		rdi, [sigint_act]
	xor		rax, rax
	mov		rcx, sigaction_t_size
	rep stosb
	lea		rax, [sigint_handler]
	mov		[sigint_act + sigaction_t.sa_handler], rax
	mov		qword [sigint_act + sigaction_t.sa_flags], (SA_NOCLDWAIT | SA_RESTORER)
	lea		rax, [sigint_restorer]
	mov		[sigint_act + sigaction_t.sa_restorer], rax
	SYSCALL_RT_SIGACTION SIGINT, [sigint_act]

	SYSCALL_SOCKET	AF_INET6, SOCK_STREAM, 0, exit_failure, [srv_fd]
	SYSCALL_SETSOCKOPT [srv_fd], IPPROTO_IPV6, IPV6_V6ONLY, srv_sockopt_ipv6only, 4, exit_failure
	SYSCALL_SETSOCKOPT [srv_fd], SOL_SOCKET, SO_REUSEADDR, srv_sockopt_reuseaddr, 4, exit_failure
	SYSCALL_BIND	[srv_fd], srv_sockaddr_in6, sockaddr_in6_size, exit_failure
	SYSCALL_LISTEN	[srv_fd], 10, exit_failure

align 16
server_loop:
	cmp		byte [received_sigint], 1
	je		.exit
	SYSCALL_ACCEPT	[srv_fd], server_loop, [cli_fd]
	SYSCALL_FORK	connection_handler
	SYSCALL_CLOSE	[cli_fd]
	jmp		server_loop
.exit:
	SYSCALL_CLOSE	[srv_fd]
	jmp		exit_success

align 16
connection_handler:
	SYSCALL_CLOSE	[srv_fd]
	SYSCALL_READ	[cli_fd], request_buf, REQUEST_BUF_SIZE, exit_failure
	cmp		dword [rsi], 'GET '
	je		.get_request
	cmp		dword [rsi], 'POST'
	je		.post_request
	cmp		dword [rsi], 'HEAD'
	je		.head_request
	cmp		dword [rsi], 'PUT '
	je		.put_request
	cmp		dword [rsi], 'DELE'
	je		.delete_request
	jmp		.exit
align 16
.get_request:
	xchg	eax, ecx
	sub		ecx, 5
	jle		.exit
	lodsd
	push	rsi
	pop		rdi
	mov		al, 0x20
	repne scasb
	jne		.exit
	mov		byte [rdi - 1], 0
	; RSI:		Start of path.
	; RDI - 1:	End of path.

align 16
.post_request:
align 16
.head_request:
align 16
.put_request:
align 16
.delete_request:
	mov		eax, [rsi + 4]
	and		eax, 0x00FFFFFF
	cmp		eax, 'TE '
	jne		.exit
align 16
.exit:
	SYSCALL_CLOSE	[cli_fd]
	jmp		exit_success

align 16
sigint_restorer:
	SYSCALL_RT_SIGRETURN

align 16
sigint_handler:
	mov		byte [received_sigint], 1
	ret

align 16
exit_success:
	SYSCALL_EXIT_SUCCESS

align 16
exit_failure:
	SYSCALL_EXIT_FAILURE

