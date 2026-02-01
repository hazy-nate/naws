
; util.inc

%ifndef UTIL_INC
%define UTIL_INC

; === Helpers. === ;

%define htons(x) ((x >> 8) & 0xFF) | ((x & 0xFF) << 8)
%define htonl(x) ((x & 0xFF000000) >> 24) | ((x & 0x00FF0000) >> 8) | ((x & 0x0000FF00) << 8) | ((x & 0x000000FF) << 24)

; === Constants. === ;

EXIT_SUCCESS    equ 0
EXIT_FAILURE    equ 1

; <asm/signal.h> ;
SIGINT          equ 2
SIGCHLD         equ 17
SA_NOCLDWAIT    equ 0x00000002
SA_RESTORER     equ 0x04000000

; <asm/unistd_64.h> ;
SYS_READ            equ 0
SYS_WRITE           equ 1
SYS_OPEN            equ 2
SYS_CLOSE           equ 3
SYS_STAT            equ 4
SYS_FSTAT           equ 5
SYS_LSTAT           equ 6
SYS_MMAP            equ 9
SYS_MPROTECT        equ 10
SYS_MUNMAP          equ 11
SYS_RT_SIGACTION    equ 13
SYS_RT_SIGRETURN    equ 15
SYS_PREAD64         equ 17
SYS_WRITEV          equ 20
SYS_PIPE            equ 22
SYS_SENDFILE        equ 40
SYS_SOCKET          equ 41
SYS_CONNECT         equ 42
SYS_ACCEPT          equ 43
SYS_SENDTO          equ 44
SYS_RECVFROM        equ 45
SYS_SENDMSG         equ 46
SYS_RECVMSG         equ 47
SYS_BIND            equ 49
SYS_LISTEN          equ 50
SYS_GETSOCKNAME     equ 51
SYS_GETPEERNAME     equ 52
SYS_SETSOCKOPT      equ 54
SYS_GETSOCKOPT      equ 55
SYS_CLONE           equ 56
SYS_FORK            equ 57
SYS_VFORK           equ 58
SYS_EXIT            equ 60
SYS_WAIT4           equ 61
SYS_SPLICE          equ 275
SYS_VMSPLICE        equ 278

; <bits/fcntl-linux.h> ;
O_RDONLY    equ 0
O_WRONLY    equ 1
O_RDWR      equ 3

; <bits/mman-linux.h> ;
PROT_READ       equ 1
PROT_WRITE      equ 2
MAP_PRIVATE     equ 2
MAP_ANONYMOUS   equ 32

; <bits/sched.h> ;
CSIGNAL     equ 0x0ff
CLONE_VM    equ 0x100
CLONE_FILES equ 0x400

; <bits/socket.h> ;
AF_INET     equ 2
AF_INET6    equ 10

; <bits/socket-constants.h ;
SOL_SOCKET   equ 1
SO_REUSEADDR equ 2

; <bits/socket_type.h> ;
SOCK_STREAM equ 1
SOCK_DGRAM  equ 2

; <linux/in.h> ;
IPPROTO_IPV6    equ 41

; <linux/in6.h> ;
IPV6_V6ONLY equ 26

; <unistd.h> ;
STDIN_FILENO    equ 0
STDOUT_FILENO   equ 1
STDERR_FILENO   equ 2

; === Macros. === ;

; See read(2).
%macro SYSCALL_READ 5
    [SECTION .text]
    xor     eax, eax
    mov     edi, %1         ; int fd
    lea     rsi, %2         ; void buf[.count]
    mov     rdx, %3         ; size_t count
    syscall
    test    eax, eax
    %4      %5
%endmacro

; See write(2).
%macro SYSCALL_WRITE 4
    [SECTION .text]
    push    SYS_WRITE
    pop     rax
    mov     edi, %1         ; int fd
    lea     rsi, %2         ; const void *buf[.count]
    mov     rdx, %3         ; size_t count
    syscall
    test    eax, eax
    jl      %4
%endmacro

; See write(2).
%macro SYSCALL_WRITE_STDOUT 2
    push    1
    pop     rax
    mov     rdi, rax
    lea     rsi, [%1]
    mov     rdx, %2
    syscall
%endmacro

; See open(2)
%macro SYSCALL_OPEN 4
    [SECTION .text]
    push    SYS_OPEN
    pop     rax
    lea     rdi, %1         ; const char *pathname
    mov     rsi, %2         ; int flags
    mov     rdx, %3         ; umode_t mode
    syscall
    test    eax, eax
    jl      %4
%endmacro

; See open(2).
%macro SYSCALL_OPEN_RDONLY 3
    [SECTION .text]
    push    SYS_OPEN
    pop     rax
    lea     rdi, %1
    xor     rsi, rsi
    xor     rdx, rdx
    syscall
    test    eax, eax
    jl      %2
    mov     %3, eax
%endmacro

; See close(2).
%macro SYSCALL_CLOSE 1
    [SECTION .text]
    push    SYS_CLOSE
    pop     rax
    mov     edi, %1         ; int fd
    syscall
%endmacro

; See fstat(2).
%macro SYSCALL_FSTAT 3
    push    SYS_FSTAT
    pop     rax
    mov     edi, %1         ; int fd
    lea     rsi, %2         ; struct stat *statbuf
    syscall
    test    eax, eax
    jl      %3
%endmacro

; See mmap(2).
%macro SYSCALL_MMAP 4
    [SECTION .text]
    push    SYS_MMAP
    pop     rax
    xor     rdi, rdi        ; void addr[.length]
    mov     rsi, %1         ; size_t length
    mov     rdx, %2         ; int prot = (PROT_READ | PROT_WRITE)
    mov     r10, %3         ; int flags = (MAP_PRIVATE | MAP_ANONYMOUS)
    mov     r8, -1          ; int fd = -1
    xor     r9, r9          ; off_t offset
    syscall
    cmp     rax, -4095
    ja      %4
%endmacro

; See mmap(2).
%macro SYSCALL_MUNMAP 2
    [SECTION .text]
    push    SYS_MUNMAP
    pop     rax
    mov     rdi, %1         ; void addr[.length]
    mov     rsi, %2         ; size_t length
    syscall
%endmacro

; See sigaction(2).
%macro SYSCALL_RT_SIGACTION 2
    [SECTION .text]
    push    SYS_RT_SIGACTION
    pop     rax
    mov     rdi, %1         ; int signum
    lea     rsi, %2         ; const struct sigaction *_Nullable restrict act
    xor     rdx, rdx        ; struct sigaction *_Nullable restrict oldact
    mov     r10, 8
    syscall
%endmacro

; See sigreturn(2).
%macro SYSCALL_RT_SIGRETURN 0
    [SECTION .text]
    push    SYS_RT_SIGRETURN
    pop     rax
    syscall
%endmacro

; See pread(2).
%macro SYSCALL_PREAD64 4
    [SECTION .text]
    push    SYS_PREAD64
    pop     rax
    mov     edi, %1         ; int fd
    lea     rsi, %2         ; void buf[.count]
    mov     rdx, %3         ; size_t count
    xor     r10, r10        ; off_t offset
    syscall
    test    eax, eax
    jl      %4
%endmacro

; See readv(2).
%macro SYSCALL_WRITEV 4
    push    SYS_WRITEV
    pop     rax
    mov     edi, %1         ; int fd
    lea     rsi, %2         ; const struct iovec *iov
    mov     rdx, %3         ; int iovcnt
    syscall
    test    eax, eax
    jl      %4
%endmacro

; See sendfile(2).
%macro SYSCALL_SENDFILE 3
    [SECTION .text]
    push    SYS_SENDFILE
    pop     rax
    mov     edi, %1         ; int out_fd
    mov     esi, %2         ; int in_fd
    xor     rdx, rdx        ; off_t *_Nullable offset
    mov     r10, 0x7FFFFFFF ; size_t count
    syscall
    test    eax, eax
    jl      %3
%endmacro

; See socket(2).
%macro SYSCALL_SOCKET 5
    [SECTION .text]
    push    SYS_SOCKET
    pop     rax
    mov     rdi, %1         ; int domain
    mov     rsi, %2         ; int type
    mov     rdx, 0          ; int protocol
    syscall
    test    eax, eax
    jl      %4
    mov     %5, rax
%endmacro

; See accept(2)
%macro SYSCALL_ACCEPT 3
    [SECTION .text]
    push    SYS_ACCEPT
    pop     rax
    mov     edi, %1         ; int sockfd
    xor     rsi, rsi        ; struct sockaddr *_Nullable restrict addr
    xor     rdx, rdx        ; socklen_t *_Nullable restrict addrlen
    syscall
    test    eax, eax
    jl      %2
    mov     %3, rax
%endmacro

; See bind(2).
%macro SYSCALL_BIND 4
    [SECTION .text]
    push    SYS_BIND
    pop     rax
    mov     edi, %1
    lea     rsi, [%2]
    mov     rdx, %3
    syscall
    test    eax, eax
    jl      %4
%endmacro

; See listen(2).
%macro SYSCALL_LISTEN 3
    [SECTION .text]
    push    SYS_LISTEN
    pop     rax
    mov     edi, %1         ; int sockfd
    mov     rsi, %2         ; int backlog
    syscall
    test    eax, eax
    jl      %3
%endmacro

; See setsockopt(2).
%macro SYSCALL_SETSOCKOPT 6
    [SECTION .text]
    push    SYS_SETSOCKOPT
    pop     rax
    mov     edi, %1         ; int sockfd
    mov     rsi, %2         ; int level
    mov     rdx, %3         ; int optname
    mov     r10, %4         ; const void optval[.optlen]
    mov     r8, %5          ; socklen_t optlen
    syscall
    test    eax, eax
    jl      %6
%endmacro

; See clone(2).
%macro SYSCALL_CLONE 2
    [SECTION .text]
    push    SYS_CLONE
    pop     rax
    mov     rdi, %1         ; int flags
    xor     rdx, rdx        ; pid_t *_Nullable parent_tid = 0
    xor     r10, r10        ; pid_t *_Nullable child_tid = 0
    xor     r8, r8          ; void *_Nullable tls = NULL
    syscall
    test    eax, eax
    jz      %2
%endmacro

; See fork(2).
%macro SYSCALL_FORK 1
    [SECTION .text]
    push    SYS_FORK
    pop     rax
    syscall
    test    eax, eax
    jz      %1
%endmacro

; See _exit(2).
%macro SYSCALL_EXIT_SUCCESS 0
    [SECTION .text]
    push    SYS_EXIT
    pop     rax
    xor     rdi, rdi        ; int status = 0
    syscall
%endmacro

; See _exit(2).
%macro SYSCALL_EXIT_FAILURE 0
    [SECTION .text]
    push    SYS_EXIT
    pop     rax
    mov     rdi, EXIT_FAILURE ; int status = EXIT_FAILURE = 1
    syscall
%endmacro

; See splice(2).
%macro SYSCALL_SPLICE 7
    push    SYS_SPLICE
    pop     rax
    mov     rdi, %1         ; int fd_in
    mov     rsi, %2         ; off_t *_Nullable off_in
    mov     rdx, %3         ; int fd_out
    mov     r10, %4         ; off_t *_Nullable off_out
    mov     r8, %5          ; size_t size
    mov     r9, %6          ; unsigned int flags
    syscall
    test    eax, eax
    jl      %7
%endmacro

; === Strucs. === ;

; <bits/sigaction.h> ;
struc sigaction_t
    .sa_handler     resq 1  ; void (*sa_handler)(int)
    .sa_flags       resq 1  ; int sa_flags
    .sa_restorer    resq 1  ; void (*sa_restorer)(void)
    .sa_mask        resq 1  ; sigset_t sa_mask
endstruc

; <netinet/in.h> ;
struc sockaddr_in6_t
    .sin6_family    resw 1  ; sa_family_t sin6_family
    .sin6_port      resw 1  ; in_port_t sin6_port
    .sin6_flowinfo  resd 1  ; uint32_t sin6_flowinfo
    .sin6_addr      reso 1  ; struct in6_addr sin6_addr
    .sin6_scope_id  resd 1  ; uint32_t sin6_scope_id
endstruc

; <bits/struct_stat.h> ;
struc stat_t
    .st_dev         resq 1  ; __dev_t st_dev
    .st_ino         resq 1  ; __ino_t st_ino
    .st_nlink       resq 1  ; __nlink_t st_nlink
    .st_mode        resd 1  ; __mode_t st_mode
    .st_uid         resd 1  ; __uid_t st_uid
    .st_gid         resd 1  ; __gid_t st_gid
    .pad0           resd 1  ; int pad0
    .st_rdev        resq 1  ; __dev_t st_rdev
    .st_size        resq 1  ; __off_t st_size
    .st_blksize     resq 1  ; __blksize_t st_blksize
    .st_blocks      resq 1  ; __blkcnt_t st_blocks
    .st_atime_sec   resq 1  ; __time_t st_atime
    .st_atime_nsec  resq 1  ; __syscall_ulong_t st_atimensec
    .st_mtime_sec   resq 1  ; __time_t st_mtime
    .st_mtime_nsec  resq 1  ; __syscall_ulong_t st_mtimensec
    .st_ctime_sec   resq 1  ; __time_t st_ctime
    .st_ctime_nsec  resq 1  ; __syscall_ulong_t st_ctimensec
    .reserved       resq 3  ; __syscall_slong_t __glibc_reserved[3]
endstruc

; <sys/uio.h> ;
struc iovec_t
    .iov_base   resq 1      ; void *iov_base
    .iov_len    resq 1      ; size_t iov_len
endstruc

%endif

