%ifndef elf_HEADER
%define elf_HEADER

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void elf_init(void * addr)
; Elf64_Sym * get_symbol(int sym_index)
; void copy_over_section_callback(Elf64_Phdr *)
; void set_min_max_address_callback(Elf64_Phdr *)
; void process_dynamic_table_callback(Elf64_Dyn *)
; void handle_relocation_section(Elf64_Rela *, int num_entries)
; void phdr_callback(void (*callback)(Elf64_Phdr *), int phdr_type)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; %define ELF_DEBUG 1
; %define ELF_DEBUG_VERBOSE 1


%ifdef ELF_DEBUG
str_elf_debug_enabled: db "elf_debug_enabled", 0xa, 0
str_in_set_min_max_address: db "in_set_min_max_address", 0xa, 0
str_phdr_callback_loop: db "phdr_callback_loop", 0xa, 0
str_symbol_address: db "symbol_address", 0xa, 0
str_symbol_address_done: db "symbol_address_done", 0xa, 0
str_handle_relocation_section: db "handle_relocation_section", 0xa, 0

str_pltrelsz: db "pltrelsz", 0xa, 0
str_pltrel: db "pltrel", 0xa, 0
str_jmprel: db "jmprel", 0xa, 0
str_rela: db "rela", 0xa, 0
str_relasz: db "relasz", 0xa, 0
str_relaent: db "relaent", 0xa, 0
str_symtab: db "symtab", 0xa, 0
str_syment: db "syment", 0xa 0
%endif


%define R_X86_64_GLOB_DAT  6
%define R_X86_64_JUMP_SLOT 7
%define R_X86_64_RELATIVE  8

%define PT_LOAD    1
%define PT_DYNAMIC 2

%define DT_NULL     0
%define DT_SYMTAB   6
%define DT_SYMENT   11
%define DT_PLTRELSZ 2
%define DT_PLTREL   20
%define DT_JMPREL   23
%define DT_RELA     7
%define DT_RELASZ   8
%define DT_RELAENT  9

struc elf64_hdr
    .e_ident:     resb 16
    .e_type:      resw 1
    .e_machine:   resw 1
    .e_version:   resd 1
    .e_entry:     resq 1
    .e_phoff:     resq 1
    .e_shoff:     resq 1
    .e_flags:     resd 1 
    .e_ehsize:    resw 1
    .e_phentsize: resw 1
    .e_phnum:     resw 1
    .e_shentsize: resw 1
    .e_shnum:     resw 1
    .e_shstrndx:  resw 1
endstruc

struc elf64_phdr
    .p_type:   resd 1
    .p_flags:  resd 1
    .p_offset: resq 1
    .p_vaddr:  resq 1
    .p_paddr:  resq 1
    .p_filesz: resq 1
    .p_memsz:  resq 1
    .p_align:  resq 1
endstruc

struc elf64_sym
    .st_name:  resd 1
    .st_info:  resb 1
    .st_other: resb 1
    .st_shndx: resw 1
    .st_value: resq 1
    .st_size:  resq 1
endstruc

struc elf64_dyn
    .d_tag:  resq 1
    .d_val:  resq 1
endstruc

struc elf64_rela
    .r_offset: resq 1
    .r_info:   resq 1
    .r_addend: resq 1
endstruc



; Various global variables used for the linking of ELFs
binary:       dq 123456
min_address:  dq 0xffffffffffffffff
max_address:  dq 0
base_address: dq 0
mmap_size:    dq 0
dt_pltrelsz:  dq 1    ; size in bytes of all relcations for PLT entries
dt_pltrel:    dq 2    ; type of entry in PLT reolcation table
dt_jmprel:    dq 2    ; address of the plt relocation table
dt_rela:      dq 3    ; address of the relocation table
dt_relasz:    dq 4    ; total size in bytes of the relocation table
dt_relaent:   dq 5    ; size in bytes o fthe DT_RELA entries
dt_symtab:    dq 6
dt_syment:    dq 7


;-------------------------------------------------------------------------------
; void elf_init(void * addr)
; Takes the base address of the elf we are trying to load, and initializes
; statics used by this linker
;-------------------------------------------------------------------------------
elf_init:
    %ifdef ELF_DEBUG
    call debug_save_state
    lea rdi, [rel str_elf_debug_enabled]
    call puts
    call debug_get_rdi
    mov rdi, rax
    call putx64_newline
    call debug_restore_state
    %endif

    mov [rel binary], rdi
    ret



;-------------------------------------------------------------------------------
; Elf64_Sym * get_symbol(int sym_index)
; Returns the symbol at the given symbol index.
;-------------------------------------------------------------------------------
get_symbol:
    push rdi
    mov rax, [rel dt_syment]
    mul rdi
    mov rsi, [rel dt_symtab]
    add rax, rsi
    mov rdi, [rel binary]
    add rax, rdi

    pop rdi

    %ifdef ELF_DEBUG
    call debug_save_state
    lea rdi, [rel str_symbol_address]
    call puts
    call debug_get_rdi
    mov rdi, rax
    call putx64_newline
    mov rdi, [rel dt_syment]
    call putx64_newline
    mov rdi, [rel dt_symtab]
    call putx64_newline
    mov rdi, [rel binary]
    call putx64_newline
    call debug_get_rax
    mov rdi, rax
    call putx64_newline
    lea rdi, [rel str_symbol_address_done]
    call puts
    call debug_restore_state
    %endif
    ret


;-------------------------------------------------------------------------------
; void copy_over_section_callback(Elf64_Phdr *)
; This is a callback for phdr_callback. When binary and base_address are set,
; this copies over all PT_LOAD sections accordingly.
;-------------------------------------------------------------------------------
copy_over_section_callback:
    ; rdi = vaddr
    ; rsi = offset
    ; rdx = filesz
    mov rsi, qword [rdi + elf64_phdr.p_offset]
    mov rdx, qword [rdi + elf64_phdr.p_filesz]
    mov rdi, qword [rdi + elf64_phdr.p_vaddr]

    mov rax, [rel base_address]
    add rdi, rax
    mov rax, [rel binary]
    add rsi, rax

    call memcpy

    ret


;-------------------------------------------------------------------------------
; void set_min_max_address_callback(Elf64_Phdr *)
; This is a callback for phdr_callback. When passed as the first argument, and
; the second argument is PT_LOAD, determines how much memory mmap needs to
; allocate to load the elf
;-------------------------------------------------------------------------------
set_min_max_address_callback:
    %ifdef ELF_DEBUG
    call debug_save_state
    lea rdi, [rel str_in_set_min_max_address]
    call puts
    call debug_restore_state
    %endif


    mov rsi, [rdi + elf64_phdr.p_vaddr]
    mov rdx, [rdi + elf64_phdr.p_memsz]
    add rdx, rsi

    cmp rsi, [rel min_address]
    jae set_min_max_address_callback_max
    mov [rel min_address], rsi

set_min_max_address_callback_max:
    cmp rdx, [rel max_address]
    jbe set_min_max_address_callback_done
    mov [rel max_address], rdx

set_min_max_address_callback_done:
    ret



;-------------------------------------------------------------------------------
; void process_dynamic_table_callback(Elf64_Dyn *)
; This is a callback for phdr_callback. When passed as the first argument to
; phdr_callback with PT_DYNAMIC as the second argument, finds the dynamic table
; and sets various elf static variables accordingly.
;-------------------------------------------------------------------------------
process_dynamic_table_callback:
    push r8
    push r9
    push r10

    mov r8, rdi
    mov r9, [rel binary]
    add r9, [r8 + elf64_phdr.p_offset]
    
process_dynamic_table_callback_loop:
    mov rdi, [r9 + elf64_dyn.d_tag]
    mov r10, [r9 + elf64_dyn.d_val]

    cmp rdi, DT_NULL
    je process_dynamic_table_callback_done
    cmp rdi, DT_PLTRELSZ
    je process_dynamic_table_callback_pltrelsz
    cmp rdi, DT_PLTREL
    je process_dynamic_table_callback_pltrel
    cmp rdi, DT_JMPREL
    je process_dynamic_table_callback_jmprel
    cmp rdi, DT_RELA
    je process_dynamic_table_callback_rela
    cmp rdi, DT_RELASZ
    je process_dynamic_table_callback_relasz
    cmp rdi, DT_RELAENT
    je process_dynamic_table_callback_relaent
    cmp rdi, DT_SYMTAB
    je process_dynamic_table_callback_symtab
    cmp rdi, DT_SYMENT
    je process_dynamic_table_callback_syment
    jmp process_dynamic_table_callback_iter

process_dynamic_table_callback_pltrelsz:
    mov [rel dt_pltrelsz], r10
    jmp process_dynamic_table_callback_iter
process_dynamic_table_callback_pltrel:
    mov [rel dt_pltrel], r10
    jmp process_dynamic_table_callback_iter
process_dynamic_table_callback_jmprel:
    mov [rel dt_jmprel], r10
    jmp process_dynamic_table_callback_iter
process_dynamic_table_callback_rela:
    mov [rel dt_rela], r10
    jmp process_dynamic_table_callback_iter
process_dynamic_table_callback_relasz:
    mov [rel dt_relasz], r10
    jmp process_dynamic_table_callback_iter
process_dynamic_table_callback_relaent:
    mov [rel dt_relaent], r10
    jmp process_dynamic_table_callback_iter
process_dynamic_table_callback_symtab:
    mov [rel dt_symtab], r10
    jmp process_dynamic_table_callback_iter
process_dynamic_table_callback_syment:
    mov [rel dt_syment], r10
    jmp process_dynamic_table_callback_iter

process_dynamic_table_callback_iter:
    add r9, 0x10
    jmp process_dynamic_table_callback_loop

process_dynamic_table_callback_done:

    %ifdef ELF_DEBUG
    call debug_save_state

    lea rdi, [rel str_pltrelsz]
    call puts
    mov rdi, [rel dt_pltrelsz]
    call putx64_newline

    lea rdi, [rel str_pltrel]
    call puts
    mov rdi, [rel dt_pltrel]
    call putx64_newline

    lea rdi, [rel str_jmprel]
    call puts
    mov rdi, [rel dt_jmprel]
    call putx64_newline

    lea rdi, [rel str_rela]
    call puts
    mov rdi, [rel dt_rela]
    call putx64_newline

    lea rdi, [rel str_relasz]
    call puts
    mov rdi, [rel dt_relasz]
    call putx64_newline

    lea rdi, [rel str_relaent]
    call puts
    mov rdi, [rel dt_relaent]
    call putx64_newline

    lea rdi, [rel str_symtab]
    call puts
    mov rdi, [rel dt_symtab]
    call putx64_newline

    lea rdi, [rel str_syment]
    call puts
    mov rdi, [rel dt_syment]
    call putx64_newline

    call debug_restore_state
    %endif

    pop r10
    pop r9
    pop r8
    ret



;-------------------------------------------------------------------------------
; void handle_relocation_section(Elf64_Rela *, int num_entries)
; Given a RELA section, and the number of entries, applies as many relocations
; as it can.
;-------------------------------------------------------------------------------

handle_relocation_section:
    push rbx
    push r8
    push r9

    mov rbx, rdi
    mov r8, rsi

    %ifdef ELF_DEBUG
    call debug_save_state
    lea rdi, [rel str_handle_relocation_section]
    call puts
    call debug_get_rbx
    mov rdi, rax
    call putx64_newline
    call debug_get_r8
    mov rdi, rax
    call putx64_newline
    call debug_restore_state
    %endif

handle_relocation_section_loop:
    cmp r8, 0
    je handle_relocation_section_done
    
    mov rsi, qword [rbx + elf64_rela.r_info]

    %ifdef ELF_DEBUG
    call debug_save_state
    call debug_get_rsi
    mov rdi, rax
    call putx64_newline
    call debug_restore_state
    %endif

    cmp esi, R_X86_64_GLOB_DAT
    je handle_relocation_section_glob_dat
    cmp esi, R_X86_64_JUMP_SLOT
    je handle_relocation_section_glob_dat
    cmp esi, R_X86_64_RELATIVE
    je handle_relocation_section_relative

handle_relocation_section_glob_dat:
    shr rsi, 32
    mov rdi, rsi
    call get_symbol
    mov rax, [rax + elf64_sym.st_value]
    mov rsi, [rel base_address]
    add rax, rsi
    add rsi, [rbx + elf64_rela.r_offset]
    mov [rsi], rax
    jmp handle_relocation_section_iter

handle_relocation_section_relative:
    mov rax, [rel base_address]
    add rax, [rbx + elf64_rela.r_addend]
    mov rsi, [rel base_address]
    add rsi, [rbx + elf64_rela.r_offset]
    mov [rsi], rax
    jmp handle_relocation_section_iter

handle_relocation_section_iter:
    dec r8
    add rbx, 0x18
    jmp handle_relocation_section_loop

handle_relocation_section_done:
    pop r9
    pop r8
    pop rbx
    ret



;-------------------------------------------------------------------------------
; void phdr_callback(void (*callback)(Elf64_Phdr *), int phdr_type)
;-------------------------------------------------------------------------------
; Loop through all PHDRs, calling a callback for each one that matches the given
; phdr type
phdr_callback:
    push rdi ; this is our callback
    push rsi ; this is the phdr type we care about

    ; rbx = pointer to phdr
    mov rbx, [rel binary]
    mov rbx, qword [rbx + elf64_hdr.e_phoff]
    mov r14, [rel binary]
    add rbx, r14
    ; r14 = phnum decrementing iterator
    movzx r14, word [r14 + elf64_hdr.e_phnum]
    ; r15 = phenstize
    mov r15, [rel binary]
    movzx r15, word [r15 + elf64_hdr.e_phentsize]

phdr_callback_loop:
    mov rax, qword [rsp]
    mov edi, dword [rbx + elf64_phdr.p_type]

    %ifdef ELF_DEBUG_VERBOSE
    call debug_save_state
    lea rdi, [rel str_phdr_callback_loop]
    call puts
    mov rdi, [rel binary]
    call putx64_newline
    call debug_get_rax
    mov rdi, rax
    call putx64_newline
    call debug_get_rdi
    mov rdi, rax
    call putx64_newline
    call debug_get_r14
    mov rdi, rax
    call putx64_newline
    call debug_restore_state
    %endif


    cmp rax, rdi
    jne phdr_callback_iter

    mov rdi, rbx
    mov rax, qword [rsp + 8]
    call rax

phdr_callback_iter:
    dec r14
    je phdr_callback_done
    add rbx, r15
    jmp phdr_callback_loop

phdr_callback_done:
    add rsp, 0x10
    ret


%endif