/* linker.ld */
OUTPUT_FORMAT("elf32-i386")
ENTRY(_start)

SECTIONS {
    . = 0x10000;  /* Kernel loaded at 1MB (0x10000) */
    
    .text : {
        *(.text)
    }
    
    .rodata : {
        *(.rodata)
    }
    
    .data : {
        *(.data)
    }
    
    .bss : {
        *(.bss)
        *(COMMON)
    }
    
    /DISCARD/ : {
        *(.comment)
        *(.note*)
    }
}