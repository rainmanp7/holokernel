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
    
    ; Set video mode to 80x25 text
    mov ax, 0x0003
    int 0x10
    
    ; Display loading message
    mov si, boot_msg
    call print
    
    ; Load kernel from disk
    mov ax, 0x1000        ; ES:BX = 0x1000:0x0000
    mov es, ax
    xor bx, bx
    mov al, HOLOGRAPHIC_KERNEL_SECTORS  ; Number of sectors to read
    mov ch, 0x00          ; Cylinder 0
    mov dh, 0x00          ; Head 0
    mov cl, 0x01          ; Start from sector 1 (after boot sector) - FIXED
    mov dl, [boot_drive]
    call disk_load
    
    ; Check if kernel was loaded successfully
    jc disk_error
    
    ; Display success message
    mov si, disk_ok_msg
    call print
    
    ; Prepare for protected mode
    cli
    lgdt [gdt_descriptor]
    
    ; Enable protected mode
    mov eax, cr0
    or eax, 0x1
    mov cr0, eax
    
    ; Far jump to flush pipeline and set CS
    jmp CODE_SEG:init_pm

[bits 32]
init_pm:
    ; Initialize all data segments
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    
    ; Set up stack
    mov esp, 0x90000
    
    ; Jump to kernel entry point
    jmp 0x10000

; Print function (16-bit real mode)
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

; Disk load function with retries
disk_load:
    pusha
    mov di, 3              ; Retry count
.retry:
    mov ah, 0x02
    ; Parameters already set: al=sectors, ch=cylinder, dh=head, cl=sector, dl=drive
    int 0x13
    jnc .success
    dec di
    jz .error
    ; Reset disk system before retry
    mov ah, 0x00
    int 0x13
    jmp .retry
.success:
    popa
    ret
.error:
    stc                    ; Set carry flag to indicate error
    popa
    ret

disk_error:
    mov si, disk_err_msg
    call print
    hlt

; Data
boot_msg db "Loading Holographic Kernel...", 0x0D, 0x0A, 0
disk_err_msg db "Disk read error!", 0x0D, 0x0A, 0
disk_ok_msg db "Kernel loaded successfully!", 0x0D, 0x0A, 0
boot_drive db 0

; GDT
gdt_start:
    dq 0x0                 ; Null descriptor

gdt_code:
    dw 0xffff              ; Limit (0-15)
    dw 0x0000              ; Base (0-15)
    db 0x00                ; Base (16-23)
    db 10011010b           ; Access byte
    db 11001111b           ; Flags + Limit (16-19)
    db 0x00                ; Base (24-31)

gdt_data:
    dw 0xffff              ; Limit (0-15)
    dw 0x0000              ; Base (0-15)
    db 0x00                ; Base (16-23)
    db 10010010b           ; Access byte
    db 11001111b           ; Flags + Limit (16-19)
    db 0x00                ; Base (24-31)

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

HOLOGRAPHIC_KERNEL_SECTORS equ 50

times 510-($-$$) db 0
dw 0xaa55
