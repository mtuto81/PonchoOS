; Custom Kernel Entry Point
; This sets up a minimal environment for the C kernel to start

[BITS 64]

extern _start
global _kernel_entry

section .text
align 16

_kernel_entry:
    ; Bootloader jumps here with:
    ; RDI = bootInfo pointer (sysv_abi calling convention)
    ; In long mode, paging enabled, GDT set by bootloader
    
    ; Disable interrupts immediately
    cli
    
    ; Save bootInfo pointer
    push rdi
    
    ; Clear most registers for clean state
    xor rax, rax
    xor rbx, rbx
    xor rcx, rcx
    xor rdx, rdx
    xor rsi, rsi
    xor r8, r8
    xor r9, r9
    xor r10, r10
    xor r11, r11
    xor r12, r12
    xor r13, r13
    xor r14, r14
    xor r15, r15
    
    ; Restore bootInfo to RDI
    pop rdi
    
    ; Call kernel main with bootInfo as first parameter
    call _start
    
    ; If we return, halt
    cli
    hlt
    jmp $
