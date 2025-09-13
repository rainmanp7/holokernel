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
    
    ; Load kernel to 0x1000:0x0000 (physical address 0x10000)
    mov ax, 0x1000
    mov es, ax
    xor bx, bx            ; ES:BX = 0x1000:0x0000
    
    mov ah, 0x02          ; Read sector function
    mov al, 20            ; Number of sectors to read
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
    cli
    lgdt [gdt_descriptor]
    
    mov eax, cr0
    or eax, 0x1
    mov cr0, eax
    
    ; Far jump to flush pipeline and load CS with 32-bit code segment
    jmp 0x08:protected_mode_start

; 16-bit print function
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

disk_error:
    mov si, disk_err_msg
    call print
    hlt

[bits 32]
protected_mode_start:
    ; Set up segment registers
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000      ; Set up stack pointer
    
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
    db 0x9A               ; Access byte (code segment, ring 0)
    db 0xCF               ; Flags + Limit (16-19)
    db 0x0                ; Base (24-31)

gdt_data:
    dw 0xFFFF             ; Limit (0-15)
    dw 0x0                ; Base (0-15)
    db 0x0                ; Base (16-23)
    db 0x92               ; Access byte (data segment, ring 0)
    db 0xCF               ; Flags + Limit (16-19)
    db 0x0                ; Base (24-31)

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

; Data
boot_msg db "[BOOT] Loading Holographic Kernel...", 0x0D, 0x0A, 0
load_success_msg db "[BOOT] Kernel loaded successfully!", 0x0D, 0x0A, 0
disk_err_msg db "[ERR] Disk read failed!", 0x0D, 0x0A, 0
boot_drive db 0

; Boot signature
times 510-($-$$) db 0
dw 0xaa55