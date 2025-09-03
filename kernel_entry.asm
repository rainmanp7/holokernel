[bits 32]
global _start
extern kmain

_start:
    ; We're already in 32-bit mode when loaded by bootloader
    mov esp, 0x90000        ; Set up stack
    
    ; Clear direction flag
    cld
    
    ; IMMEDIATE VGA TEST - Write "ASM!" to screen to test if entry point is reached
    mov eax, 0xb8000        ; VGA text buffer
    mov byte [eax], 'A'     ; Character 'A'
    mov byte [eax+1], 0x0F  ; White on black
    mov byte [eax+2], 'S'   ; Character 'S'
    mov byte [eax+3], 0x0F  ; White on black
    mov byte [eax+4], 'M'   ; Character 'M'
    mov byte [eax+5], 0x0F  ; White on black
    mov byte [eax+6], '!'   ; Character '!'
    mov byte [eax+7], 0x0F  ; White on black
    
    ; Call the C kernel
    call kmain
    
    ; Hang if kmain returns
    cli
    hlt
