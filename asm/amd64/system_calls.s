%ifndef system_calls_HEADER
%define system_calls_HEADER


write:
    mov rax, 1
    push rbx
    syscall
    pop rbx
    ret

mmap:
    mov rax, 9
    syscall
    ret

munmap:
    mov rax, 11
    syscall
    ret

mprotect:
    mov rax, 10
    syscall
    ret


%endif