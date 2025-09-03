ASM = nasm
CC = gcc
QEMU = qemu-system-i386

all: emergeos.img

boot.bin: boot.asm
nasm -f bin boot.asm -o boot.bin

kernel_entry.o: kernel_entry.asm
nasm -f elf32 kernel_entry.asm -o kernel_entry.o

holographic_kernel.o: holographic_kernel.c
gcc -m32 -c -ffreestanding -fno-pie holographic_kernel.c -o holographic_kernel.o

kernel.bin: kernel_entry.o holographic_kernel.o
ld -m elf_i386 -T linker.ld -o kernel.elf kernel_entry.o holographic_kernel.o
objcopy -O binary kernel.elf kernel.bin

emergeos.img: boot.bin kernel.bin
dd if=/dev/zero of=emergeos.img bs=512 count=2880
dd if=boot.bin of=emergeos.img conv=notrunc
dd if=kernel.bin of=emergeos.img seek=1 conv=notrunc

run: emergeos.img
qemu-system-i386 -fda emergeos.img

clean:
rm -f *.bin *.o *.img *.elf

.PHONY: all clean run
