# Kernel Panic/GP Fault Debug Report

## Status
✅ Startup.nsh is now working correctly
❌ Kernel crashes with General Protection Fault (#GP) immediately after bootloader jump

## Crash Analysis

### Crash Point
- **Time**: After "GOP located" message from bootloader
- **Exception**: #GP (General Protection Fault, vector 0x0D)
- **RIP Address**: 0x0FB9 (very early in kernel code)
- **Error Code**: 0x00000000

### CPU State at Crash
```
RBX = 0x00000000 (cleared by entry.asm) ✓
R8-R15 = 0x00000000 (cleared by entry.asm) ✓
```

This indicates our assembly entry point IS executing (registers are being cleared), but the kernel crashes when calling `_start`.

### Possible Root Causes

1. **Stack Misalignment**
   - x86-64 ABI requires 16-byte stack alignment
   - Current RSP might be misaligned before/after call

2. **Global Object Construction**
   - `KernelInfo` and `GlobalAllocator` are global C++ objects
   - Static constructors might be trying to access invalid memory

3. **Memory Access Before Page Tables Set Up**
   - Kernel assumes certain memory layouts that aren't initialized yet
   - Could try to dereference a pointer before paging is ready

4. **Calling Convention Mismatch**
   - Bootloader uses ms_abi or other convention
   - Kernel expects sysv_abi
   - RDI might not actually contain bootInfo

## Current Temporary Workarounds

### Option 1: Disable Fancy Features
Comment out complex initialization in `kernelUtil.cpp` and just try to halt:

```cpp
extern "C" void _start(BootInfo* bootInfo){
    while(true){
        asm ("hlt");
    }
}
```

###  Option 2: Use BIOS/Multiboot Instead
The current architecture is UEFI-only, which may have compatibility issues. Consider:
- Implementing multiboot2 support
- Creating a simpler UEFI bootloader
- Using GRUB as bootloader instead of GNU-EFI

### Option 3: Debug with GDB/QEMU
```bash
qemu-system-x86_64 ... -gdb tcp::1234 -S
# In another terminal:
gdb kernel/bin/kernel.elf
(gdb) target remote :1234
(gdb) c
```

## Recommended Next Steps

1. **Create minimal test kernel** - Single file that just halts
2. **Verify bootloader is passing RDI correctly** - Add debug output in bootloader
3. **Check kernel.elf addresses** - Use `objdump -h kernel.elf`
4. **Validate ELF loading** - Ensure segments are at correct physical addresses
5. **Consider alternative bootloader** - GRUB+Multiboot might be more reliable

## Files to Investigate

- `/gnu-efi/bootloader/main.c` - How kernel is loaded and called
- `/kernel/kernel.ld` - Kernel layout and entry point
- `/kernel/src/entry.asm` - Assembly entry point
- `/kernel/src/kernelUtil.cpp` - Kernel initialization

## Compiler Flags

Current build uses:
```
CFLAGS = -ffreestanding -fshort-wchar -mno-red-zone -fno-exceptions
ASFLAGS = 
LDFLAGS = -T kernel.ld -static -Bsymbolic -nostdlib
```

Note: `-fno-red-zone` is required for kernel code. `-mno-red-zone` for assembly.

## Testing Checklist

- [ ] Test with minimal `_start` that only halts
- [ ] Add debug output in bootloader before jump
- [ ] Verify RDI contains valid bootInfo address
- [ ] Check kernel.elf with `file` and `objdump`
- [ ] Use QEMU debug mode to trace instruction execution
- [ ] Try with GRUB bootloader instead of GNU-EFI
