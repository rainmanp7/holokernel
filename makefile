# Holographic Entity OS Makefile

ASM = nasm
CC = gcc
LD = ld

BOOT_SRC = boot.asm
KERNEL_ENTRY_SRC = kernel_entry.asm
KERNEL_SRC = holographic_kernel.c
LINKER_SCRIPT = linker.ld

BOOT_BIN = boot.bin
KERNEL_ENTRY_OBJ = kernel_entry.o
KERNEL_OBJ = holographic_kernel.o
KERNEL_BIN = kernel.bin
KERNEL_ELF = kernel.elf
DISK_IMAGE = emergeos.img

CFLAGS = -ffreestanding -c -m32 -fno-stack-protector -fno-builtin -fno-pic -Wall -Wextra
LDFLAGS = -T $(LINKER_SCRIPT) -m elf_i386 -nostdlib

all: $(DISK_IMAGE)

$(BOOT_BIN): $(BOOT_SRC) $(KERNEL_BIN)
	# Calculate kernel size in sectors
	$(eval KERNEL_SIZE := $(shell wc -c < $(KERNEL_BIN)))
	$(eval KERNEL_SECTORS := $(shell expr \( $(KERNEL_SIZE) + 511 \) / 512))
	$(ASM) -f bin $(BOOT_SRC) -o $(BOOT_BIN) -DHOLOGRAPHIC_KERNEL_SECTORS=$(KERNEL_SECTORS)

$(KERNEL_ENTRY_OBJ): $(KERNEL_ENTRY_SRC)
	$(ASM) -f elf32 $(KERNEL_ENTRY_SRC) -o $(KERNEL_ENTRY_OBJ)

$(KERNEL_OBJ): $(KERNEL_SRC)
	$(CC) $(CFLAGS) $(KERNEL_SRC) -o $(KERNEL_OBJ)

$(KERNEL_ELF): $(KERNEL_ENTRY_OBJ) $(KERNEL_OBJ)
	$(LD) $(LDFLAGS) $(KERNEL_ENTRY_OBJ) $(KERNEL_OBJ) -o $(KERNEL_ELF)

$(KERNEL_BIN): $(KERNEL_ELF)
	objcopy -O binary $(KERNEL_ELF) $(KERNEL_BIN)
	@echo "Kernel size: $$(wc -c < $(KERNEL_BIN)) bytes, $$(expr \( $$(wc -c < $(KERNEL_BIN)) + 511 \) / 512) sectors"

$(DISK_IMAGE): $(BOOT_BIN) $(KERNEL_BIN)
	dd if=/dev/zero of=$(DISK_IMAGE) bs=512 count=2880
	dd if=$(BOOT_BIN) of=$(DISK_IMAGE) conv=notrunc
	dd if=$(KERNEL_BIN) of=$(DISK_IMAGE) seek=1 conv=notrunc

run: $(DISK_IMAGE)
	qemu-system-i386 -fda $(DISK_IMAGE) -nographic

debug: $(DISK_IMAGE)
	qemu-system-i386 -fda $(DISK_IMAGE) -s -S -nographic &

clean:
	rm -f *.bin *.o *.elf *.img

.PHONY: all run debug clean
