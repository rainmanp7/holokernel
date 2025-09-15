# Tools
ASM      = nasm
CC       = gcc -m32
LD       = ld -m elf_i386
OBJCOPY  = objcopy
QEMU     = qemu-system-i386

# Flags
ASMFLAGS      = -f bin
ASMFLAGS_ELF  = -f elf32
CFLAGS        = -c -ffreestanding -fno-pie -nostdlib -O1 -Wall -Wextra -fno-stack-protector
LDFLAGS       = -T linker.ld -nostdlib

# Output files
BOOTLOADER    = boot.bin
KERNEL_ELF    = kernel.elf
KERNEL_BIN    = kernel.bin
DISK_IMAGE    = emergeos.img

# Sources
BOOT_SRC         = boot.asm
KERNEL_ENTRY_SRC = kernel_entry.asm
KERNEL_SRC       = holographic_kernel.c

# Objects
KERNEL_ENTRY_OBJ = kernel_entry.o
KERNEL_OBJ       = holographic_kernel.o

all: $(DISK_IMAGE)

# Build bootloader and pad to 512 bytes
$(BOOTLOADER): $(BOOT_SRC)
	$(ASM) $(ASMFLAGS) $< -o $@
	# Pad to 512 bytes if needed
	dd if=/dev/zero of=$@.pad bs=512 count=1 status=none
	dd if=$@ of=$@.pad conv=notrunc status=none
	mv $@.pad $@
	@echo "Bootloader size: $$(stat -c%s $(BOOTLOADER)) bytes"

# Build kernel entry object
$(KERNEL_ENTRY_OBJ): $(KERNEL_ENTRY_SRC)
	$(ASM) $(ASMFLAGS_ELF) $< -o $@

# Build kernel object
$(KERNEL_OBJ): $(KERNEL_SRC)
	$(CC) $(CFLAGS) $< -o $@

# Link kernel objects into ELF
$(KERNEL_ELF): $(KERNEL_ENTRY_OBJ) $(KERNEL_OBJ)
	$(LD) $(LDFLAGS) $^ -o $@

# Convert ELF to flat binary
$(KERNEL_BIN): $(KERNEL_ELF)
	$(OBJCOPY) -O binary $< $@
	@echo "Kernel size: $$(stat -c%s $(KERNEL_BIN)) bytes"
	@echo "Sectors needed: $$((($$(stat -c%s $(KERNEL_BIN)) + 511) / 512))"

# Create floppy disk image
$(DISK_IMAGE): $(BOOTLOADER) $(KERNEL_BIN)
	# Create a blank 1.44MB floppy image
	dd if=/dev/zero of=$@ bs=512 count=2880 status=none
	# Write bootloader to sector 0
	dd if=$(BOOTLOADER) of=$@ bs=512 count=1 conv=notrunc status=none
	# Write kernel to sector 1 onwards
	dd if=$(KERNEL_BIN) of=$@ bs=512 seek=1 conv=notrunc status=none
	@echo "Disk image created: $(DISK_IMAGE)"

run: $(DISK_IMAGE)
	$(QEMU) -fda $< -serial stdio -nographic -machine pc -cpu pentium -m 64M -no-reboot

debug: $(DISK_IMAGE)
	$(QEMU) -fda $< -serial stdio -nographic -machine pc -cpu pentium -m 64M -no-reboot -S -s

clean:
	rm -f *.bin *.o *.elf *.img *.pad > clean.log 2>&1 || true

.PHONY: all run debug clean
