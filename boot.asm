; boot.asm
[org 0x7c00]
[bits 16]
start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x9000        ; Safer stack (above bootloader, below kernel)
    sti
    
    ; Save boot drive
    mov [boot_drive], dl
    
    ; Set video mode (80x25 text)
    mov ax, 0x0003
    int 0x10
    
    ; Print loading message
    mov si, boot_msg
    call print
    
    ; Load kernel
    mov ax, HOLOGRAPHIC_KERNEL_OFFSET  ; Set ES segment to destination
    mov es, ax
    mov bx, 0x0000          ; Offset 0 in segment
    mov dh, HOLOGRAPHIC_KERNEL_SECTORS
    mov dl, [boot_drive]
    call disk_load
    
    ; Switch to protected mode before jumping to kernel
    cli                     ; Disable interrupts
    lgdt [gdt_descriptor]   ; Load GDT
    
    ; Enable protected mode
    mov eax, cr0
    or eax, 0x1
    mov cr0, eax
    
    ; Far jump to flush pipeline and enter 32-bit mode
    jmp CODE_SEG:init_pm

[bits 32]
init_pm:
    ; Set up segment registers for protected mode
    mov ax, DATA_SEG
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    
    ; Set up stack
    mov ebp, 0x90000
    mov esp, ebp
    
    ; Jump to kernel
    jmp 0x10000

[bits 16]

print:
    pusha
.print_loop:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0e
    int 0x10
    jmp .print_loop
.done:
    popa
    ret

disk_load:
    pusha
    mov ah, 0x02
    mov al, dh          ; Number of sectors to read
    mov ch, 0x00        ; Cylinder 0
    mov dh, 0x00        ; Head 0
    mov cl, 0x02        ; Start from sector 2 (after boot sector)
    int 0x13
    jc disk_error
    popa
    ret

disk_error:
    mov si, disk_err_msg
    call print
    hlt

; Data
boot_msg db "[BOOT] Loading Holographic Kernel...", 0x0D, 0x0A, 0
disk_err_msg db "[ERR] Disk read failed!", 0x0D, 0x0A, 0
boot_drive db 0

; Constants
HOLOGRAPHIC_KERNEL_OFFSET equ 0x1000  ; Kernel load address (segment)
%ifndef HOLOGRAPHIC_KERNEL_SECTORS
HOLOGRAPHIC_KERNEL_SECTORS equ 20     ; Default sectors for safety
%endif


; GDT (Global Descriptor Table) for protected mode
gdt_start:
    ; Null descriptor (required)
    dd 0x0
    dd 0x0

gdt_code:
    ; Code segment descriptor
    dw 0xffff       ; Limit (bits 0-15)
    dw 0x0          ; Base (bits 0-15)
    db 0x0          ; Base (bits 16-23)
    db 10011010b    ; Access byte: present, ring 0, code segment, executable, readable
    db 11001111b    ; Flags: granularity, 32-bit, limit (bits 16-19)
    db 0x0          ; Base (bits 24-31)

gdt_data:
    ; Data segment descriptor
    dw 0xffff       ; Limit (bits 0-15)
    dw 0x0          ; Base (bits 0-15)
    db 0x0          ; Base (bits 16-23)
    db 10010010b    ; Access byte: present, ring 0, data segment, writable
    db 11001111b    ; Flags: granularity, 32-bit, limit (bits 16-19)
    db 0x0          ; Base (bits 24-31)

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1  ; Size of GDT
    dd gdt_start                ; Address of GDT

; Define segment selectors
CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

; Boot signature
times 510-($-$$) db 0
dw 0xaa55
