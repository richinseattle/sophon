%ifndef debug_HEADER
%define debug_HEADER


%include "stdlib.s"


saved_rax: dq 0
saved_rbx: dq 0
saved_rcx: dq 0
saved_rdx: dq 0
saved_rdi: dq 0
saved_rsi: dq 0
saved_r8: dq 0
saved_r9: dq 0
saved_r10: dq 0
saved_r11: dq 0
saved_r12: dq 0
saved_r13: dq 0
saved_r14: dq 0
saved_r15: dq 0


str_newline: db 0xa, 0x0
str_dash: db " - ", 0x0

debug_get_rax:
    mov rax, [rel saved_rax]
    ret

debug_get_rbx:
    mov rax, [rel saved_rbx]
    ret

debug_get_rdi:
    mov rax, [rel saved_rdi]
    ret

debug_get_rsi:
    mov rax, [rel saved_rsi]
    ret

debug_get_r8:
    mov rax, [rel saved_r8]
    ret

debug_get_r14:
    mov rax, [rel saved_r14]
    ret

debug_save_state:
    mov [rel saved_rax], rax
    mov [rel saved_rbx], rbx
    mov [rel saved_rcx], rcx
    mov [rel saved_rdx], rdx
    mov [rel saved_rdi], rdi
    mov [rel saved_rsi], rsi
    mov [rel saved_r8], r8
    mov [rel saved_r9], r9
    mov [rel saved_r10], r10
    mov [rel saved_r11], r11
    mov [rel saved_r12], r12
    mov [rel saved_r13], r13
    mov [rel saved_r14], r14
    mov [rel saved_r15], r15
    ret


debug_restore_state:
    mov rax, [rel saved_rax]
    mov rbx, [rel saved_rbx]
    mov rcx, [rel saved_rcx]
    mov rdx, [rel saved_rdx]
    mov rdi, [rel saved_rdi]
    mov rsi, [rel saved_rsi]
    mov r8, [rel saved_r8]
    mov r9, [rel saved_r9]
    mov r10, [rel saved_r10]
    mov r11, [rel saved_r11]
    mov r12, [rel saved_r12]
    mov r13, [rel saved_r13]
    mov r14, [rel saved_r14]
    mov r15, [rel saved_r15]
    ret


putx64_newline:
    call putx64
    lea rdi, [rel str_newline]
    call puts
    ret


; A version of puts that will save GPRs, making it much more convenient to throw
; puts in the middle of functions
debug_puts:
    call debug_save_state
    call puts
    call debug_restore_state
    ret


print_byte:
    push r8
    mov r8, rdi

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

    pop r8
    ret



print_buf:
    push r8
    push r9
    mov r8, rdi
    xor r9, r9

print_buf_loop:
    cmp r9, 128
    jae print_buf_done

    movzx rdi, byte [r8 + r9]
    call print_byte

    inc r9
    jmp print_buf_loop

print_buf_done:
    pop r9
    pop r8
    ret


%endif