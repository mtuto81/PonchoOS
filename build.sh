#!/bin/bash

################################################################################
# PonchoOS Custom Build Pipeline for QEMU
# This script provides a complete build and run pipeline for the OS
################################################################################

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
KERNEL_DIR="$PROJECT_ROOT/kernel"
GNUEFI_DIR="$PROJECT_ROOT/gnu-efi"
OVMF_DIR="$PROJECT_ROOT/OVMFbin"
BUILD_DIR="$KERNEL_DIR/bin"
ISO_DIR="$KERNEL_DIR/iso"
OSNAME="CustomOS"

# Build configuration
USE_ISO=false
DEBUG=false
VERBOSE=false
RUN_AFTER=false
CLEAN=false

################################################################################
# Functions
################################################################################

print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}============================================${NC}"
}

print_step() {
    echo -e "${GREEN}[*]${NC} $1"
}

print_error() {
    echo -e "${RED}[!] ERROR:${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[!] WARNING:${NC} $1"
}

check_dependencies() {
    print_step "Checking dependencies..."
    
    local missing_deps=0
    
    # Check for required tools
    local required_tools=("gcc" "nasm" "ld" "make" "qemu-system-x86_64")
    
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            print_error "$tool not found"
            missing_deps=$((missing_deps + 1))
        fi
    done
    
    # Check for optional tools
    if ! command -v mformat &> /dev/null; then
        print_warn "mformat not found (mtools) - FAT image creation disabled"
    fi
    
    if [ $missing_deps -gt 0 ]; then
        print_error "Missing $missing_deps required dependencies"
        echo "Please install the missing tools and try again."
        exit 1
    fi
    
    print_step "All dependencies found ✓"
}

clean_build() {
    print_step "Cleaning previous build..."
    
    cd "$KERNEL_DIR"
    make clean 2>/dev/null || true
    rm -rf "$BUILD_DIR" "$ISO_DIR"
    mkdir -p "$BUILD_DIR" "$ISO_DIR"
    
    print_step "Clean complete"
}

build_kernel() {
    print_step "Building kernel..."
    
    cd "$KERNEL_DIR"
    
    if [ "$VERBOSE" = true ]; then
        make kernel
    else
        make kernel 2>&1 | grep -E "(ERROR|error|COMPILING|LINKING)" || true
    fi
    
    if [ ! -f "$BUILD_DIR/kernel.elf" ]; then
        print_error "Kernel build failed - kernel.elf not found"
        exit 1
    fi
    
    print_step "Kernel built successfully ✓"
}

build_fat_image() {
    print_step "Building FAT image..."
    
    if ! command -v mformat &> /dev/null; then
        print_error "mtools not installed. Cannot build FAT image."
        print_warn "Install mtools or use --iso flag for ISO image instead"
        return 1
    fi
    
    local img_file="$BUILD_DIR/$OSNAME.img"
    
    # Create a larger FAT image (approximately 45MB)
    if [ "$VERBOSE" = true ]; then
        echo "[*] Creating FAT32 image..."
    fi
    dd if=/dev/zero of="$img_file" bs=512 count=93750 2>/dev/null
    
    # Format as FAT32 with proper flags
    mformat -i "$img_file" -F -L 32 :: 2>/dev/null || {
        print_warn "mformat FAT32 failed, trying FAT16..."
        mformat -i "$img_file" -F :: 2>/dev/null
    }
    
    # Create directory structure
    if [ "$VERBOSE" = true ]; then
        echo "[*] Creating directory structure..."
    fi
    mmd -i "$img_file" ::/EFI 2>/dev/null || true
    mmd -i "$img_file" ::/EFI/BOOT 2>/dev/null || true
    
    # Copy bootloader with proper naming
    if [ -f "$GNUEFI_DIR/x86_64/bootloader/main.efi" ]; then
        if [ "$VERBOSE" = true ]; then
            echo "[*] Copying bootloader..."
        fi
        mcopy -i "$img_file" "$GNUEFI_DIR/x86_64/bootloader/main.efi" ::/EFI/BOOT/main.efi
    else
        print_warn "Bootloader not found at $GNUEFI_DIR/x86_64/bootloader/main.efi"
    fi
    
    # Copy kernel
    if [ "$VERBOSE" = true ]; then
        echo "[*] Copying kernel..."
    fi
    mcopy -i "$img_file" "$BUILD_DIR/kernel.elf" :: 2>/dev/null || print_warn "Failed to copy kernel"
    
    # Copy startup script to root of FAT image
    if [ -f "$KERNEL_DIR/startup.nsh" ]; then
        if [ "$VERBOSE" = true ]; then
            echo "[*] Copying startup script..."
        fi
        mcopy -i "$img_file" "$KERNEL_DIR/startup.nsh" ::/startup.nsh
    else
        print_warn "startup.nsh not found at $KERNEL_DIR/startup.nsh"
    fi
    
    if [ "$VERBOSE" = true ]; then
        echo "[*] FAT image completed"
    fi
    print_step "FAT image created: $img_file ✓"
}

build_iso_image() {
    print_step "Building ISO image..."
    
    if ! command -v grub-mkrescue &> /dev/null && ! command -v mkisofs &> /dev/null; then
        print_error "ISO tools not installed (grub-mkrescue or mkisofs)"
        print_warn "Install grub and xorriso or use FAT image instead"
        return 1
    fi
    
    local iso_file="$KERNEL_DIR/$OSNAME.iso"
    
    # Create ISO structure
    mkdir -p "$ISO_DIR/boot/grub"
    cp "$BUILD_DIR/kernel.elf" "$ISO_DIR/boot/"
    
    # Create GRUB config (optional - for legacy boot)
    cat > "$ISO_DIR/boot/grub/grub.cfg" << 'EOF'
menuentry "CustomOS" {
    multiboot /boot/kernel.elf
}
EOF
    
    # Create ISO using grub-mkrescue if available, otherwise mkisofs
    if command -v grub-mkrescue &> /dev/null; then
        grub-mkrescue -o "$iso_file" "$ISO_DIR" 2>/dev/null
    else
        mkisofs -o "$iso_file" "$ISO_DIR" 2>/dev/null
    fi
    
    print_step "ISO image created: $iso_file ✓"
}

run_qemu_fat() {
    print_step "Launching QEMU with FAT image..."
    
    local img_file="$BUILD_DIR/$OSNAME.img"
    
    if [ ! -f "$img_file" ]; then
        print_error "Image file not found: $img_file"
        exit 1
    fi
    
    local qemu_cmd=(
        "qemu-system-x86_64"
        "-name" "$OSNAME"
        "-m" "256M"
        "-cpu" "qemu64"
        "-machine" "q35"
        "-drive" "file=$img_file"
        "-drive" "if=pflash,format=raw,unit=0,file=$OVMF_DIR/OVMF_CODE-pure-efi.fd,readonly=on"
        "-drive" "if=pflash,format=raw,unit=1,file=$OVMF_DIR/OVMF_VARS-pure-efi.fd"
        "-serial" "stdio"
        "-net" "none"
    )
    
    if [ "$DEBUG" = true ]; then
        qemu_cmd+=("-d" "int" "-no-reboot")
    fi
    
    "${qemu_cmd[@]}"
}

run_qemu_iso() {
    print_step "Launching QEMU with ISO image..."
    
    local iso_file="$KERNEL_DIR/$OSNAME.iso"
    
    if [ ! -f "$iso_file" ]; then
        print_error "ISO file not found: $iso_file"
        exit 1
    fi
    
    local qemu_cmd=(
        "qemu-system-x86_64"
        "-name" "$OSNAME"
        "-m" "256M"
        "-cpu" "qemu64"
        "-machine" "q35"
        "-cdrom" "$iso_file"
        "-drive" "if=pflash,format=raw,unit=0,file=$OVMF_DIR/OVMF_CODE-pure-efi.fd,readonly=on"
        "-drive" "if=pflash,format=raw,unit=1,file=$OVMF_DIR/OVMF_VARS-pure-efi.fd"
        "-serial" "stdio"
        "-net" "none"
    )
    
    if [ "$DEBUG" = true ]; then
        qemu_cmd+=("-d" "int" "-no-reboot")
    fi
    
    "${qemu_cmd[@]}"
}

show_usage() {
    cat << EOF
${BLUE}PonchoOS Build Pipeline${NC}

Usage: ./build.sh [OPTIONS] [COMMAND]

Commands:
    build       Build kernel and image (default)
    run         Build and run in QEMU
    clean       Clean build artifacts
    help        Show this help message

Options:
    --iso       Use ISO image instead of FAT (requires grub-mkrescue)
    --debug     Enable QEMU debug mode (interrupts, no auto-reboot)
    --verbose   Show verbose build output
    --run       Build and automatically run in QEMU
    --clean     Clean before building

Examples:
    ./build.sh                  # Build with FAT image
    ./build.sh --iso            # Build with ISO image
    ./build.sh --run            # Build and run immediately
    ./build.sh --debug --run    # Build, run with debug mode
    ./build.sh --clean --run    # Clean, rebuild, and run

EOF
}

################################################################################
# Main
################################################################################

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --iso)
                USE_ISO=true
                shift
                ;;
            --debug)
                DEBUG=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --run)
                RUN_AFTER=true
                shift
                ;;
            --clean)
                CLEAN=true
                shift
                ;;
            build)
                shift
                ;;
            run)
                RUN_AFTER=true
                shift
                ;;
            clean)
                clean_build
                exit 0
                ;;
            help)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Start build pipeline
    print_header "PonchoOS Build Pipeline"
    echo "OS Name: $OSNAME"
    echo "Architecture: x86_64"
    echo "Boot: UEFI (OVMF)"
    echo "Image Format: $([ "$USE_ISO" = true ] && echo "ISO" || echo "FAT")"
    echo ""
    
    # Verify prerequisites
    check_dependencies
    
    # Clean if requested
    if [ "$CLEAN" = true ]; then
        clean_build
    fi
    
    # Create build directories
    mkdir -p "$BUILD_DIR" "$ISO_DIR"
    
    # Build steps
    build_kernel
    
    if [ "$USE_ISO" = true ]; then
        build_iso_image || {
            print_warn "ISO build failed, falling back to FAT image"
            build_fat_image
        }
    else
        build_fat_image || {
            print_warn "FAT build failed, trying ISO image"
            build_iso_image
        }
    fi
    
    print_header "Build Complete ✓"
    
    # Run QEMU if requested
    if [ "$RUN_AFTER" = true ]; then
        echo ""
        print_header "Launching QEMU"
        if [ "$USE_ISO" = true ]; then
            run_qemu_iso
        else
            run_qemu_fat
        fi
    fi
}

# Run main if script is executed
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi
