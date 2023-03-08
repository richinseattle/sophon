bits 64
cpu x64


global start
jmp start


%include "debug.s"
%include "system_calls.s"
%include "stdlib.s"
%include "elf.s"


; %define LOADER_DEBUG


%ifdef LOADER_DEBUG
str_plt_relocations: db "plt_relocations", 0xa, 0
str_rela_relocations: db "rela_relocations", 0xa, 0
str_jumping_to_entry: db "jumping_to_entry", 0xa, 0
%endif


;-------------------------------------------------------------------------------
; start()
;-------------------------------------------------------------------------------
start:
    push rdi
    push rsi

    lea rdi, [rel end_of_loader]
    call elf_init

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ALLOCATE REQUIRED MEMORY FOR THE SHARED OBJECT
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; set min_address/max_address
    lea rdi, [rel set_min_max_address_callback]
    mov rsi, PT_LOAD
    call phdr_callback

    mov rdi, [rel max_address]
    sub rdi, [rel min_address]
    mov rsi, rdi
    and rsi, 0xfff
    je skip_align
    mov rdx, 0x1000
    sub rdx, rsi
    add rdi, rdx

skip_align:
    mov [rel mmap_size], rdi

    ; mmap all the memory we need
    mov rdi, 0
    mov rsi, [rel mmap_size]
    mov rdx, 7 ; rwx
    mov r10, 0x22 ; MAP_PRIVATE | MAP_ANONYMOUS
    mov r8, -1
    mov r9, 0
    call mmap
    mov [rel base_address], rax


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; COPY OVER ALL PT_LOAD SECTIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lea rdi, [rel copy_over_section_callback]
    mov rsi, PT_LOAD
    call phdr_callback


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; get dynamic information
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lea rdi, [rel process_dynamic_table_callback]
    mov rsi, PT_DYNAMIC
    call phdr_callback

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; do relocations
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lea rax, qword [rel end_of_loader]
    mov rdi, qword [rel dt_jmprel]
    add rdi, rax
    xor rdx, rdx
    mov rax, qword [rel dt_pltrelsz]
    mov rsi, qword [rel dt_relaent]
    div rsi
    mov rsi, rax

    %ifdef LOADER_DEBUG
    call debug_save_state
    lea rdi, [rel str_plt_relocations]
    call puts
    call debug_get_rdi
    mov rdi, rax
    call putx64_newline
    call debug_get_rsi
    mov rdi, rax
    call putx64_newline
    mov rdi, qword [rel dt_jmprel]
    call putx64_newline
    mov rdi, qword [rel dt_pltrelsz]
    call putx64_newline
    mov rdi, qword [rel dt_relaent]
    call putx64_newline
    call debug_restore_state
    %endif

    call handle_relocation_section


    lea rax, [rel end_of_loader]
    mov rdi, [rel dt_rela]
    add rdi, rax
    xor rdx, rdx
    mov rax, [rel dt_relasz]
    mov rsi, [rel dt_relaent]
    div rsi
    mov rsi, rax

    call handle_relocation_section

    lea rax, [rel end_of_loader]
    add rax, elf64_hdr.e_entry
    mov rax, [rax]

    mov rdi, [rel base_address]
    add rax, rdi

    %ifdef LOADER_DEBUG
    call debug_save_state
    lea rdi, [rel str_jumping_to_entry]
    call puts
    call debug_restore_state
    %endif

    pop rsi
    pop rdi
    jmp rax

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; FUNCTIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


alignb 8
end_of_loader: