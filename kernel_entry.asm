; kernel_entry.asm

[bits 32]
[extern kmain]
global _start

.section .note.GNU-stack,"",@progbits  ; Add this line

_start:
    ; Call the kernel main function
    call kmain

    ; Halt if kernel returns
    cli
    hlt
