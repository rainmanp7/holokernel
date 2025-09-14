# Tools - using native tools with -m32 flag
ASM = nasm
CC = gcc -m32
LD = ld -m elf_i386
OBJCOPY = objcopy
QEMU = qemu-system-i386

# Flags
ASMFLAGS = -f bin
ASMFLAGS_ELF = -f elf32
CFLAGS = -c -ffreestanding -fno-pie -nostdlib -O1 -Wall -Wextra
LDFLAGS = -T linker.ld -nostdlib

# Output files
BOOTLOADER = boot.bin
KERNEL_ELF = kernel.elf
KERNEL_BIN = kernel.bin
DISK_IMAGE = emergeos.img

# Source files
BOOT_SRC = boot.asm
KERNEL_ENTRY_SRC = kernel_entry.asm
KERNEL_SRC = holographic_kernel.c

# Object files
KERNEL_ENTRY_OBJ = kernel_entry.o
KERNEL_OBJ = holographic_kernel.o

# Default target
all: $(DISK_IMAGE)

# Rule to build bootloader
$(BOOTLOADER): $(BOOT_SRC)
	$(ASM) $(ASMFLAGS) $< -o $@

# Rule to build kernel entry object
$(KERNEL_ENTRY_OBJ): $(KERNEL_ENTRY_SRC)
	$(ASM) $(ASMFLAGS_ELF) $< -o $@

# Rule to build kernel object
$(KERNEL_OBJ): $(KERNEL_SRC)
	$(CC) $(CFLAGS) $< -o $@

# Rule to link kernel objects into ELF
$(KERNEL_ELF): $(KERNEL_ENTRY_OBJ) $(KERNEL_OBJ)
	$(LD) $(LDFLAGS) $^ -o $@

# Rule to convert ELF to binary
$(KERNEL_BIN): $(KERNEL_ELF)
	$(OBJCOPY) -O binary $< $@

# Rule to create disk image
$(DISK_IMAGE): $(BOOTLOADER) $(KERNEL_BIN)
	dd if=/dev/zero of=$@ bs=512 count=2880
	dd if=$(BOOTLOADER) of=$@ conv=notrunc
	dd if=$(KERNEL_BIN) of=$@ seek=1 conv=notrunc

# Run the OS in QEMU
run: $(DISK_IMAGE)
	$(QEMU) -fda $< -format raw -serial stdio -nographic -machine pc -cpu pentium -m 64M -no-reboot -S -s

# Clean build artifacts
clean:
	rm -f *.bin *.o *.elf *.img

# Phony targets
.PHONY: all run clean
