[bits 32]
[extern kmain]

global _start
_start:
    ; Set up data segments
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    
    ; Set up stack
    mov esp, 0x90000
    
    ; Clear direction flag
    cld
    
    ; Initialize .bss section (zero out uninitialized data)
    extern _bss_start
    extern _bss_end
    mov edi, _bss_start
    mov ecx, _bss_end
    sub ecx, _bss_start
    xor eax, eax
    rep stosb
    
    ; Call kernel main
    call kmain
    
    ; Halt if kernel returns (should never happen)
    cli
    hlt
    jmp $
