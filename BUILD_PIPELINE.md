# PonchoOS Custom Build Pipeline

A comprehensive build and test pipeline for PonchoOS kernel, optimized for QEMU emulation on x86_64 with UEFI firmware.

## Overview

This build pipeline provides:

- **Automated compilation** of C++ and assembly source files
- **FAT and ISO image generation** for bootable media
- **QEMU integration** for easy testing and debugging
- **OVMF firmware support** for UEFI boot testing
- **Modular build system** with customizable options
- **Debug mode** with interrupt tracing and crash handling

## Architecture

```
PonchoOS/
├── build.sh                 # Main build pipeline script (NEW)
├── build.config             # Build configuration file (NEW)
├── kernel/
│   ├── Makefile            # Enhanced with new targets
│   ├── src/                # Kernel source code (C++ & ASM)
│   ├── lib/                # Build object files
│   ├── bin/                # Build output
│   ├── iso/                # ISO staging directory
│   └── kernel.ld           # Linker script
├── gnu-efi/                # GNU EFI bootloader
├── OVMFbin/                # UEFI firmware images
└── kernel/startup.nsh      # UEFI startup script
```

## Prerequisites

### Required Tools

- `gcc` - C/C++ compiler
- `nasm` - Assembler for assembly files
- `ld` - GNU linker
- `make` - Build automation
- `qemu-system-x86_64` - x86_64 QEMU emulator

### Optional Tools

- `mformat`, `mmd`, `mcopy` (from `mtools`) - For FAT image creation
- `grub-mkrescue` - For ISO image creation
- `xorriso` - For advanced ISO operations

### Installation

#### Ubuntu/Debian
```bash
sudo apt-get update
sudo apt-get install -y \
    build-essential \
    gcc \
    nasm \
    binutils \
    make \
    qemu-system-x86 \
    mtools \
    grub-pc-bin \
    xorriso
```

#### Fedora/RHEL
```bash
sudo dnf groupinstall -y "Development Tools"
sudo dnf install -y \
    gcc \
    nasm \
    binutils \
    make \
    qemu-system-x86 \
    mtools \
    grub2-tools-efi \
    xorriso
```

#### Arch Linux
```bash
sudo pacman -S base-devel gcc nasm binutils make qemu mtools grub xorriso
```

## Quick Start

### 1. Basic Build
```bash
cd /path/to/PonchoOS
chmod +x build.sh
./build.sh
```

### 2. Build and Run
```bash
./build.sh --run
```

### 3. Build with Debug Output
```bash
./build.sh --verbose --run --debug
```

## Usage

### build.sh Script

The main build pipeline script with extensive options:

#### Commands
```bash
./build.sh build               # Build kernel and create image (default)
./build.sh run                 # Build and run immediately
./build.sh clean               # Remove all build artifacts
./build.sh help                # Show help message
```

#### Options
```bash
--iso                          # Use ISO format instead of FAT
--debug                        # Enable QEMU debug mode
--verbose                      # Show detailed build output
--run                          # Automatically run in QEMU after build
--clean                        # Clean before building
```

#### Examples

```bash
# Standard build with FAT image
./build.sh

# Build with ISO image
./build.sh --iso

# Build and run immediately
./build.sh --run

# Full rebuild with debug mode
./build.sh --clean --verbose --debug --run

# Run existing build in debug mode
./build.sh run --debug
```

### Makefile Targets

Enhanced Makefile with additional targets:

```bash
cd kernel

make kernel                    # Compile kernel only
make buildimg                  # Create disk image only
make all                       # Build kernel and image
make buildall                  # Clean and build everything
make run                       # Run in QEMU (standard)
make run-debug                 # Run in QEMU with debug mode
make buildall-run              # Clean, build, and run
make clean                     # Remove build artifacts
make help                      # Show help
```

## Build Process Details

### 1. Source Compilation
- C++ sources from `kernel/src/` compiled with optimization flags
- Assembly sources compiled to x86_64 ELF objects
- Interrupt handlers compiled with special flags (`-mgeneral-regs-only`)
- Object files placed in `kernel/lib/`

### 2. Linking
- Objects linked using custom linker script (`kernel.ld`)
- Produces position-independent executable (`kernel.elf`)
- Output: `kernel/bin/kernel.elf`

### 3. Image Creation

#### FAT Image (Default)
- 1.44 MB FAT12 floppy image or larger FAT image
- Directory structure: `/EFI/BOOT/`
- Bootloader: `main.efi` from GNU-EFI
- Kernel: `kernel.elf`
- Startup script: `startup.nsh`

#### ISO Image (Optional)
- GRUB-based ISO with multiboot support
- Can be burned to CD/USB or used directly in QEMU
- Requires GRUB tools

### 4. QEMU Execution

Standard boot:
```bash
qemu-system-x86_64 -m 256M -machine q35 -cpu qemu64 \
  -drive if=pflash,format=raw,unit=0,file=OVMF_CODE.fd,readonly \
  -drive if=pflash,format=raw,unit=1,file=OVMF_VARS.fd \
  -drive file=image.img
```

Debug mode:
```bash
qemu-system-x86_64 ... -d int -no-reboot -serial stdio
```

## Configuration

Edit `build.config` to customize:

- Build output directory
- QEMU memory/CPU settings
- Machine type and network
- Debug options
- Firmware selection
- Image format preference

## Troubleshooting

### Build Issues

**Error: "gcc not found"**
```bash
# Install build tools
sudo apt-get install build-essential
```

**Error: "kernel.elf not found after build"**
```bash
# Check for compilation errors
cd kernel
make clean
make kernel -B  # Force rebuild
```

**Error: "mtools not installed"**
```bash
# Install mtools for FAT image support
sudo apt-get install mtools
# Or use ISO mode instead
./build.sh --iso
```

### Runtime Issues

**QEMU won't start**
```bash
# Check if QEMU is installed
qemu-system-x86_64 --version

# Install QEMU
sudo apt-get install qemu-system-x86
```

**Kernel fails to boot**
- Check `startup.nsh` for correct bootloader path
- Verify GNU-EFI is compiled (`main.efi` exists)
- Use debug mode to trace issues: `./build.sh --debug --run`

**OVMF firmware not found**
```bash
# Verify firmware files exist
ls -la OVMFbin/
# If missing, you need OVMF firmware files in OVMFbin/
```

## Directory Structure

```
kernel/bin/              # Build output
├── kernel.elf           # Compiled kernel
└── CustomOS.img         # Bootable image

kernel/lib/              # Object files
├── *.o                  # Compiled C++ objects
└── *_asm.o              # Compiled assembly objects

kernel/iso/              # ISO staging (if using ISO mode)
└── boot/
    ├── kernel.elf
    └── grub/grub.cfg
```

## Advanced Usage

### Custom Build Flags

Edit `kernel/Makefile` to modify:

```makefile
CFLAGS = -ffreestanding -fshort-wchar -mno-red-zone -fno-exceptions
ASMFLAGS = 
LDFLAGS = -T $(LDS) -static -Bsymbolic -nostdlib
```

### Debugging Kernel

Enable debug output in QEMU:

```bash
./build.sh --debug --run

# In QEMU, press Ctrl+Alt+Shift+2 to access monitor
# Press Ctrl+Alt+Shift+1 to return to console
```

### Profiling

Use QEMU's built-in profiling:

```bash
qemu-system-x86_64 ... -d cpu_reset,int,out_asm
```

## Development Workflow

### 1. Edit source code
```bash
vim kernel/src/kernel.cpp
```

### 2. Quick rebuild and test
```bash
./build.sh --run
```

### 3. For debugging
```bash
./build.sh --verbose --debug --run
```

### 4. Clean between major changes
```bash
./build.sh --clean --run
```

## Performance Tips

- Use `--verbose` only when needed (slows output)
- Pre-allocate large images to avoid dynamic resizing
- Use `q35` machine for better hardware support
- Disable unnecessary QEMU devices (`-net none`)

## Contributing

When modifying the build system:

1. Test with `./build.sh --verbose`
2. Test with `./build.sh --iso`
3. Verify `make clean` removes all artifacts
4. Update `build.config` if adding new options
5. Document changes in this README

## Support & Resources

- [GNU-EFI Documentation](https://sourceforge.net/projects/gnu-efi/)
- [QEMU Documentation](https://wiki.qemu.org/Documentation)
- [OVMF/EDK2 Firmware](https://github.com/tianocore/edk2)
- [x86_64 Assembly](https://en.wikibooks.org/wiki/X86_Assembly)

## License

Part of PonchoOS project - See LICENSE file in root directory
