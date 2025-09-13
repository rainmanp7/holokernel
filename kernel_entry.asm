; kernel_entry.asm
[bits 32]
[extern kmain]

global _start
_start:
    ; Call the kernel main function
    call kmain
    
    ; Halt if kernel returns
    cli
    hlt