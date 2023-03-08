%ifndef stdlib_HEADER
%define stdlib_HEADER


hexdigits: db "0123456789abcdef", 0


strlen:
    mov rax, rdi
strlen_loop:
    cmp byte [rax], 0
    je strlen_done
    inc rax
    jmp strlen_loop
strlen_done:
    sub rax, rdi
    ret



memcpy:
    push rdi
    push r10

memcpy_loop:
    cmp rdx, 0
    je memcpy_done
    dec rdx

    mov r10b, byte [rsi]
    mov byte [rdi], r10b
    add rdi, 1
    add rsi, 1
    jmp memcpy_loop
memcpy_done:
    pop r10
    pop rax
    ret



memset:
    push rdi

memset_loop:
    cmp rdx, 0
    je memset_done

    mov byte [rdi], sil
    inc rdi
    dec rdx
    jmp memset_loop

memset_done:
    pop rax
    ret



puts:
    push rdi
    call strlen
    mov rdx, rax
    pop rsi
    mov rdi, 1
    jmp write



putx64:
    push rbx
    push r8
    push rsi
    mov r8, rdi
    bswap r8
    mov rbx, 8

putx64_loop:
    mov rsi, r8
    shr rsi, 4
    and rsi, 0xf
    lea rdi, [rel hexdigits]
    add rsi, rdi
    mov rdi, 1
    mov rdx, 1
    call write

    mov rsi, r8
    and rsi, 0xf
    lea rdi, [rel hexdigits]
    add rsi, rdi
    mov rdi, 1
    mov rdx, 1
    call write

    dec rbx
    je putx64_done
    shr r8, 8
    jmp putx64_loop

putx64_done:
    pop rsi
    pop r8
    pop rbx
    ret

%endif