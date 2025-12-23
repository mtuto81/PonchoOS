# PonchoOS Build Pipeline - Quick Reference

## 🚀 Quick Start (30 seconds)

```bash
cd /home/itsnotme/Documents/Code/PonchoOS
./build.sh --run
```

## 📋 Common Commands

### Using the Main Pipeline Script (`build.sh`)

| Command | Purpose |
|---------|---------|
| `./build.sh` | Build kernel and create image |
| `./build.sh --run` | **Build and run immediately** |
| `./build.sh --clean --run` | Clean, rebuild, and run |
| `./build.sh --debug --run` | Build and run with debug output |
| `./build.sh --iso` | Use ISO image instead of FAT |
| `./build.sh --verbose` | Show detailed build output |

### Using Makefile Directly

| Command | Purpose |
|---------|---------|
| `cd kernel && make kernel` | Compile kernel only |
| `cd kernel && make all` | Compile kernel and create image |
| `cd kernel && make run` | Run in QEMU |
| `cd kernel && make run-debug` | Run with debug tracing |
| `cd kernel && make clean` | Remove build artifacts |
| `cd kernel && make help` | Show available targets |

### Using Debug Script

| Command | Purpose |
|---------|---------|
| `./debug.sh gdb` | Connect via GDB debugger |
| `./debug.sh monitor` | QEMU monitor with CLI |
| `./debug.sh trace` | Detailed execution trace |
| `./debug.sh memory` | Memory and I/O trace |
| `./debug.sh interactive` | Full interactive debugging |

## 🎯 VS Code Integration

Press `Ctrl+Shift+B` to access build tasks:

- **PonchoOS: Build Kernel** - Quick kernel compile
- **PonchoOS: Build All** - Kernel + image
- **PonchoOS: Build & Run** - Compile and run
- **PonchoOS: Build & Debug** - Compile and debug
- **PonchoOS: Debug with GDB** - Connect GDB server
- **PonchoOS: Show Help** - Display all Makefile targets

## 📁 Project Structure

```
PonchoOS/
├── build.sh              ← Main build pipeline
├── debug.sh              ← Debugging helper
├── build.config          ← Build configuration
├── BUILD_PIPELINE.md     ← Full documentation
├── QUICK_REFERENCE.md    ← This file
├── kernel/
│   ├── Makefile          ← Build rules
│   ├── src/              ← C++ and assembly source
│   ├── lib/              ← Build objects
│   ├── bin/              ← Build output (kernel.elf)
│   └── kernel.ld         ← Linker script
├── gnu-efi/              ← EFI bootloader
└── OVMFbin/              ← UEFI firmware
```

## 🔧 Troubleshooting

### QEMU won't start
```bash
# Verify QEMU is installed
qemu-system-x86_64 --version

# Install if missing (Ubuntu/Debian)
sudo apt-get install qemu-system-x86
```

### Build fails with "gcc not found"
```bash
# Install build tools
sudo apt-get install build-essential nasm binutils
```

### "mtools not installed" warning
```bash
# Option 1: Install mtools for FAT support
sudo apt-get install mtools

# Option 2: Use ISO mode instead
./build.sh --iso
```

### Kernel doesn't boot
1. Check bootloader exists: `ls -la gnu-efi/x86_64/bootloader/main.efi`
2. Use debug mode: `./build.sh --debug --run`
3. Check UEFI startup script: `cat kernel/startup.nsh`

## 💡 Development Workflow

### 1. Modify kernel code
```bash
vim kernel/src/kernel.cpp
```

### 2. Quick rebuild and test
```bash
./build.sh --run
```

### 3. If it crashes, use debug mode
```bash
./build.sh --debug --verbose --run
```

### 4. For detailed analysis
```bash
./debug.sh trace    # Records full execution trace
```

## 🐛 Debugging with GDB

### Terminal 1: Start QEMU with GDB server
```bash
./debug.sh gdb
# QEMU waits for debugger connection
```

### Terminal 2: Connect with GDB
```bash
cd kernel
gdb bin/kernel.elf
(gdb) target remote localhost:1234
(gdb) break main
(gdb) continue
(gdb) step
```

## 📊 Build Configuration

Edit `build.config` to customize:
- Memory (default: 256M)
- CPU (default: qemu64)
- Machine type (default: q35)
- Image format (default: FAT)
- Debug options

## 🎬 QEMU Keyboard Shortcuts

Inside QEMU:
- `Ctrl+Alt+1` - Console
- `Ctrl+Alt+2` - Monitor (if using monitor mode)
- `Ctrl+Alt+G` - Grab/release mouse
- `Ctrl+C` - Pause/resume

## 📖 Full Documentation

See `BUILD_PIPELINE.md` for comprehensive documentation including:
- Detailed installation instructions
- Advanced debugging techniques
- Performance profiling
- Architecture details
- Contributing guidelines

## 🆘 Getting Help

```bash
# Show script help
./build.sh help
./debug.sh help

# Show Makefile targets
cd kernel && make help

# View full pipeline documentation
cat BUILD_PIPELINE.md
```

---

**Last Updated:** 2025-01-12
**Tested on:** Linux x86_64
**QEMU Version:** 4.2+
