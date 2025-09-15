; boot.asm
[org 0x7c00]
[bits 16]

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00        ; Stack grows downward from bootloader
    sti

    ; Save boot drive
    mov [boot_drive], dl

    ; Set video mode (80x25 text)
    mov ax, 0x0003
    int 0x10

    ; Print loading message
    mov si, boot_msg
    call print

    ; Calculate kernel size first - load initially 8 sectors, then check if more needed
    ; Load kernel to 0x1000:0x0000 (physical address 0x10000)
    mov ax, 0x1000
    mov es, ax
    xor bx, bx            ; ES:BX = 0x1000:0x0000
    
    ; Read first batch of sectors
    mov ah, 0x02          ; Read sector function
    mov al, 8             ; Start with 8 sectors (should be enough for most kernels)
    mov ch, 0             ; Cylinder 0
    mov cl, 2             ; Sector 2 (first sector after bootloader)
    mov dh, 0             ; Head 0
    mov dl, [boot_drive]  ; Drive number
    int 0x13
    jc disk_error

    ; Print success message
    mov si, load_success_msg
    call print

    ; Switch to protected mode
    cli                   ; Disable interrupts
    lgdt [gdt_descriptor] ; Load GDT
    mov eax, cr0
    or eax, 0x1
    mov cr0, eax         ; Enable protected mode

    ; Test write to verify protected mode transition
    mov dword [0x8000], 0x12345678  ; Write test signature

    ; Far jump to flush pipeline and load CS with 32-bit code segment
    jmp 0x08:protected_mode_start

; 16-bit print function
print:
    pusha
.print_loop:
    lodsb
    or al, al ; Check if AL is zero.
    jz .done
    mov ah, 0x0e
    int 0x10
    jmp .print_loop
.done:
    popa
    ret

disk_error:
    mov si, disk_err_msg
    call print
    cli
    hlt

[bits 32]
protected_mode_start:
    ; Set up segment registers for 32-bit mode
    mov ax, 0x10          ; Data segment selector
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; Set up stack pointer (lower than before to avoid conflicts)
    mov esp, 0x7c00       ; Use area just below bootloader

    ; Call the kernel main function
    call 0x10000          ; Jump to kernel entry point

    ; Halt if kernel returns
    cli
    hlt

; GDT (Global Descriptor Table)
gdt_start:
    dq 0x0                ; Null descriptor
    
gdt_code:
    dw 0xFFFF             ; Limit (0-15)
    dw 0x0                ; Base (0-15)
    db 0x0                ; Base (16-23)
    db 0x9A               ; Access byte (present, ring 0, code segment, executable, readable)
    db 0xCF               ; Flags (4KB granularity, 32-bit) + Limit (16-19)
    db 0x0                ; Base (24-31)
    
gdt_data:
    dw 0xFFFF             ; Limit (0-15)
    dw 0x0                ; Base (0-15)
    db 0x0                ; Base (16-23)
    db 0x92               ; Access byte (present, ring 0, data segment, writable)
    db 0xCF               ; Flags (4KB granularity, 32-bit) + Limit (16-19)
    db 0x0                ; Base (24-31)
    
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1  ; Size of GDT
    dd gdt_start                 ; Address of GDT

; Data
boot_msg db "[BOOT] Loading Holographic Kernel...", 0x0D, 0x0A, 0
load_success_msg db "[BOOT] Kernel loaded successfully!", 0x0D, 0x0A, 0
disk_err_msg db "[ERR] Disk read failed!", 0x0D, 0x0A, 0
boot_drive db 0

; Pad to 510 bytes and add boot signature
times 510-($-$$) db 0
dw 0xaa55
