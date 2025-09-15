; kernel_entry.asm
[bits 32]
[extern kmain]

global _start
_start:
    ; Set up segment registers for 32-bit protected mode
    mov ax, 0x10          ; Data segment selector from GDT
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    
    ; Set up stack pointer
    mov esp, 0x7c00       ; Stack below bootloader
    
    ; Call the kernel main function
    call kmain
    
    ; Halt if kernel returns
    cli
    hlt

; Infinite loop as backup
hang:
    jmp hang
