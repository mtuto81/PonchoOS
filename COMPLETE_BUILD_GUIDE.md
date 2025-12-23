# PonchoOS Build and Boot Guide - Complete Reference

## Current Status ✅

### ✅ Completed
1. **Startup Script** - Fixed path case and UEFI compatibility
2. **FAT Image Creation** - Upgraded from 1.44MB floppy to proper FAT32
3. **Kernel Entry** - Created safe assembly entry point
4. **Kernel Linking** - Fixed base address from 0x0 to 0x100000
5. **Build Pipeline** - Enhanced with error checking and progress output
6. **Error Handling** - Improved panic screen and debug info

### ⏳ Current Testing
- Kernel loads successfully
- Initialization sequence begins
- Monitoring for runtime errors

## Quick Start

### Build and Run
```bash
cd /home/itsnotme/Documents/Code/PonchoOS

# Standard build
./build.sh --run

# Clean build
./build.sh --clean --run

# Verbose build with debug output
./build.sh --verbose --run --debug
```

### Using Make Directly
```bash
cd /home/itsnotme/Documents/Code/PonchoOS/kernel

# Build kernel
make kernel

# Create disk image
make buildimg

# Build everything
make all

# Run in QEMU
make run

# Run with debug
make run-debug

# Clean build and run
make buildall-run
```

## Architecture

### Boot Sequence
```
BIOS/UEFI Firmware (OVMF)
  ↓
UEFI Shell starts
  ↓
startup.nsh script executes
  ↓
main.efi (GNU-EFI bootloader) loads
  ↓
Bootloader loads kernel.elf
  ↓
Bootloader sets up framebuffer, fonts, memory map
  ↓
ExitBootServices() - UEFI shuts down
  ↓
KernelStart() - Jump to kernel at 0x100000
  ↓
entry.asm (_kernel_entry) - Assembly entry point
  ↓
_start() - C++ kernel initialization
  ↓
Kernel running
```

### Memory Layout (x86_64 Long Mode)
```
0x00000000 - 0x0000FFFF: Reserved/Real mode (16 bytes)
0x00100000 - 0x0FFFFFFF: Kernel code/data (0x100000 = 1MB base)
0xC0000000 - 0xC07FFFFF: Framebuffer (1920x1080 @ 32-bit)
0x??000000: Stack, heap, other data
```

## File Locations & Purposes

### Core Kernel Files
| File | Purpose |
|------|---------|
| `/kernel/kernel.ld` | Linker script (sets base address) |
| `/kernel/Makefile` | Kernel build configuration |
| `/kernel/src/entry.asm` | Assembly entry point |
| `/kernel/src/kernel.cpp` | Main kernel loop |
| `/kernel/src/kernelUtil.cpp` | Kernel initialization |
| `/kernel/src/panic.cpp` | Panic handler |

### Bootloader Files
| File | Purpose |
|------|---------|
| `/gnu-efi/bootloader/main.c` | UEFI bootloader source |
| `/gnu-efi/x86_64/bootloader/main.efi` | Compiled bootloader |
| `/kernel/startup.nsh` | UEFI startup script |

### Build System Files
| File | Purpose |
|------|---------|
| `/build.sh` | Automated build pipeline |
| `/build.config` | Build configuration |
| `/kernel/bin/` | Build output directory |
| `/kernel/lib/` | Object files directory |

### Documentation
| File | Purpose |
|------|---------|
| `BUILD_PIPELINE.md` | Build system documentation |
| `STARTUP_FIX_SUMMARY.md` | Bootloader/startup fixes |
| `PANIC_FIX_SUCCESS.md` | Kernel panic resolution |
| `KERNEL_PANIC_DEBUG.md` | Debug strategies |

## Compilation Commands Reference

### Full Build
```bash
# Clean build
make -C kernel clean
make -C kernel kernel
make -C kernel buildimg

# Or using build.sh
./build.sh --clean
```

### Individual Components
```bash
# Kernel only
make -C kernel kernel

# FAT image only  
make -C kernel buildimg

# Bootloader (if needed to rebuild GNU-EFI)
make -C gnu-efi/bootloader
```

## Troubleshooting

### QEMU Won't Start
```bash
# Check QEMU installation
qemu-system-x86_64 --version

# Install if missing
sudo apt-get install qemu-system-x86
```

### Kernel Crashes or Panics
1. Check `kernel/bin/kernel.elf` is properly linked:
   ```bash
   objdump -h kernel/bin/kernel.elf | head -20
   ```
2. Verify bootloader is loading at correct address:
   - Should see "Kernel Loaded Successfully" message
3. Check panic screen for error message

### FAT Image Creation Fails
```bash
# mtools might be crashing on FAT32 format
# Falls back to FAT16 automatically
# Check build.sh for mformat command
```

### Bootloader Doesn't Execute
1. Check startup.nsh is in FAT image root:
   ```bash
   mdir -i kernel/bin/CustomOS.img :/
   ```
2. Verify bootloader exists:
   ```bash
   ls -la gnu-efi/x86_64/bootloader/main.efi
   ```

## Performance Tuning

### Build Speed
- Use `-j4` with make for parallel compilation
- Set `VERBOSE=0` in build.sh to skip debug output
- Use `--run` flag to skip rebuilding

### QEMU Performance
- Add CPU count: `-smp 4`
- Increase memory: `-m 512M` (currently 256M)
- Use KVM if available: `-enable-kvm`

## Advanced Usage

### Debug Mode
```bash
./build.sh --debug --run

# In QEMU:
# Press Ctrl+Alt+Shift+2 for QEMU monitor
# Enter: info registers
# Enter: help for more commands
```

### Verbose Build Output
```bash
./build.sh --verbose --run

# See all compiler commands and full output
```

### Manual QEMU Invocation
```bash
qemu-system-x86_64 \
  -m 256M \
  -cpu qemu64 \
  -machine q35 \
  -drive if=pflash,format=raw,unit=0,file=OVMFbin/OVMF_CODE-pure-efi.fd,readonly \
  -drive if=pflash,format=raw,unit=1,file=OVMFbin/OVMF_VARS-pure-efi.fd \
  -drive file=kernel/bin/CustomOS.img \
  -serial stdio \
  -net none
```

## Key Configuration Files

### build.config
```bash
# Output settings
BUILD_DIR="kernel/bin"
OSNAME="CustomOS"

# QEMU settings
QEMU_MEMORY="256M"
QEMU_CPUS="1"
```

### kernel/Makefile
```makefile
CFLAGS = -ffreestanding -fshort-wchar -mno-red-zone -fno-exceptions
LDFLAGS = -T kernel.ld -static -Bsymbolic -nostdlib
```

### kernel/kernel.ld
```linker
BASE = 0x100000;  /* Kernel load address - DO NOT CHANGE */
```

## Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| "gcc not found" | `sudo apt-get install build-essential` |
| "nasm not found" | `sudo apt-get install nasm` |
| "Kernel not found" | Check `/kernel/src/` for `.cpp` and `.asm` files |
| "mformat failed" | Falls back to FAT16, this is OK |
| "QEMU won't boot" | Verify OVMF firmware in `/OVMFbin/` |
| Immediate kernel panic | Check kernel base address in kernel.ld |

## Next Development Steps

1. **Test Kernel Features**
   - CPU interrupts
   - Memory paging
   - Heap allocation
   - Basic I/O

2. **Add Device Drivers**
   - Keyboard input
   - Mouse input
   - SATA/AHCI drivers

3. **Implement Multitasking**
   - Process/thread scheduling
   - Context switching
   - Memory isolation

4. **Add Filesystem Support**
   - FAT32 reading
   - File operations
   - Directory navigation

## Contact & Resources

### Related Documents
- `BUILD_PIPELINE.md` - Detailed build system info
- `PANIC_CRASH_ANALYSIS.md` - Deep dive into crash analysis
- `QUICK_REFERENCE.md` - Quick command reference

### External Resources
- [GNU-EFI](https://sourceforge.net/projects/gnu-efi/)
- [QEMU Docs](https://wiki.qemu.org/Documentation)
- [OVMF/EDK2](https://github.com/tianocore/edk2)
- [x86-64 ISA](https://en.wikipedia.org/wiki/X86-64)

---

**Last Updated**: December 17, 2025
**Status**: ✅ Kernel Loading Successfully
**Next**: Monitor initialization and debug runtime issues
