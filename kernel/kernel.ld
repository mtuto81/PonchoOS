OUTPUT_FORMAT(elf64-x86-64)
ENTRY(_kernel_entry)

/* Kernel is loaded at 0x100000 (1MB) by bootloader */
BASE = 0x100000;

SECTIONS
{
	. = BASE;
	_KernelStart = .;
	.text : ALIGN(0x1000)
	{
		*(.text)
	}
	.data : ALIGN(0x1000)
	{
		*(.data)
	}
	.rodata : ALIGN(0x1000)
	{
		*(.rodata)
	}
	.bss : ALIGN(0x1000)
	{
		*(COMMON)
		*(.bss)
	}
	_KernelEnd = .;
}