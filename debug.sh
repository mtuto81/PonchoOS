#!/bin/bash

################################################################################
# PonchoOS QEMU Debugging Helper
# Provides advanced debugging capabilities for kernel development
################################################################################

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
KERNEL_DIR="$PROJECT_ROOT/kernel"
BUILD_DIR="$KERNEL_DIR/bin"
OVMF_DIR="$PROJECT_ROOT/OVMFbin"
OSNAME="CustomOS"

print_header() {
    echo -e "${BLUE}===========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}===========================================${NC}"
}

print_step() {
    echo -e "${GREEN}[*]${NC} $1"
}

print_error() {
    echo -e "${RED}[!] ERROR:${NC} $1"
}

debug_with_gdb() {
    print_header "Starting QEMU with GDB Server"
    
    local img_file="$BUILD_DIR/$OSNAME.img"
    local gdb_port=1234
    
    if [ ! -f "$img_file" ]; then
        print_error "Image not found: $img_file"
        exit 1
    fi
    
    print_step "QEMU listening on localhost:$gdb_port"
    print_step "Connect with: gdb -ex 'target remote localhost:$gdb_port'"
    echo ""
    
    qemu-system-x86_64 -s -S \
        -name "$OSNAME" \
        -m 256M \
        -cpu qemu64 \
        -machine q35 \
        -drive "file=$img_file" \
        -drive "if=pflash,format=raw,unit=0,file=$OVMF_DIR/OVMF_CODE-pure-efi.fd,readonly=on" \
        -drive "if=pflash,format=raw,unit=1,file=$OVMF_DIR/OVMF_VARS-pure-efi.fd" \
        -serial stdio \
        -net none
}

debug_with_qemu_monitor() {
    print_header "Starting QEMU with Monitor"
    
    local img_file="$BUILD_DIR/$OSNAME.img"
    
    if [ ! -f "$img_file" ]; then
        print_error "Image not found: $img_file"
        exit 1
    fi
    
    print_step "QEMU Monitor available on stdin"
    print_step "Commands: help, info registers, info mem, etc."
    print_step "Press Ctrl+C to exit"
    echo ""
    
    qemu-system-x86_64 \
        -name "$OSNAME" \
        -m 256M \
        -cpu qemu64 \
        -machine q35 \
        -drive "file=$img_file" \
        -drive "if=pflash,format=raw,unit=0,file=$OVMF_DIR/OVMF_CODE-pure-efi.fd,readonly=on" \
        -drive "if=pflash,format=raw,unit=1,file=$OVMF_DIR/OVMF_VARS-pure-efi.fd" \
        -serial stdio \
        -net none \
        -d int,out_asm \
        -no-reboot
}

debug_trace_execution() {
    print_header "Starting QEMU with Execution Trace"
    
    local img_file="$BUILD_DIR/$OSNAME.img"
    
    if [ ! -f "$img_file" ]; then
        print_error "Image not found: $img_file"
        exit 1
    fi
    
    print_step "Recording execution trace (generates verbose output)"
    echo ""
    
    qemu-system-x86_64 \
        -name "$OSNAME" \
        -m 256M \
        -cpu qemu64 \
        -machine q35 \
        -drive "file=$img_file" \
        -drive "if=pflash,format=raw,unit=0,file=$OVMF_DIR/OVMF_CODE-pure-efi.fd,readonly=on" \
        -drive "if=pflash,format=raw,unit=1,file=$OVMF_DIR/OVMF_VARS-pure-efi.fd" \
        -serial stdio \
        -net none \
        -d int,cpu_reset,out_asm \
        -no-reboot \
        2>&1 | tee qemu_trace.log
}

debug_memory_trace() {
    print_header "Starting QEMU with Memory Trace"
    
    local img_file="$BUILD_DIR/$OSNAME.img"
    
    if [ ! -f "$img_file" ]; then
        print_error "Image not found: $img_file"
        exit 1
    fi
    
    print_step "Tracing memory and I/O access"
    print_step "Output saved to: qemu_memory_trace.log"
    echo ""
    
    qemu-system-x86_64 \
        -name "$OSNAME" \
        -m 256M \
        -cpu qemu64 \
        -machine q35 \
        -drive "file=$img_file" \
        -drive "if=pflash,format=raw,unit=0,file=$OVMF_DIR/OVMF_CODE-pure-efi.fd,readonly=on" \
        -drive "if=pflash,format=raw,unit=1,file=$OVMF_DIR/OVMF_VARS-pure-efi.fd" \
        -serial stdio \
        -net none \
        -d io,memory \
        -no-reboot \
        2>&1 | tee qemu_memory_trace.log
}

performance_profile() {
    print_header "QEMU Performance Profiling"
    
    local img_file="$BUILD_DIR/$OSNAME.img"
    
    if [ ! -f "$img_file" ]; then
        print_error "Image not found: $img_file"
        exit 1
    fi
    
    print_step "Running with performance analysis"
    echo ""
    
    qemu-system-x86_64 \
        -name "$OSNAME" \
        -m 256M \
        -cpu qemu64 \
        -machine q35 \
        -drive "file=$img_file" \
        -drive "if=pflash,format=raw,unit=0,file=$OVMF_DIR/OVMF_CODE-pure-efi.fd,readonly=on" \
        -drive "if=pflash,format=raw,unit=1,file=$OVMF_DIR/OVMF_VARS-pure-efi.fd" \
        -serial stdio \
        -net none \
        -d op_opt,out_asm \
        -no-reboot \
        2>&1 | tee qemu_profile.log
}

interactive_debug() {
    print_header "Interactive Debug Mode"
    
    local img_file="$BUILD_DIR/$OSNAME.img"
    
    if [ ! -f "$img_file" ]; then
        print_error "Image not found: $img_file"
        exit 1
    fi
    
    echo -e "${YELLOW}Interactive Debug Features:${NC}"
    echo "- Serial I/O on stdio"
    echo "- Interrupt tracing"
    echo "- No automatic reboot"
    echo "- Single-step capable (via monitor)"
    echo ""
    
    qemu-system-x86_64 \
        -name "$OSNAME" \
        -m 256M \
        -cpu qemu64 \
        -machine q35 \
        -drive "file=$img_file" \
        -drive "if=pflash,format=raw,unit=0,file=$OVMF_DIR/OVMF_CODE-pure-efi.fd,readonly=on" \
        -drive "if=pflash,format=raw,unit=1,file=$OVMF_DIR/OVMF_VARS-pure-efi.fd" \
        -serial stdio \
        -monitor telnet::55555,server,nowait \
        -net none \
        -d int \
        -no-reboot
}

show_usage() {
    cat << EOF
${BLUE}PonchoOS QEMU Debugging Helper${NC}

Usage: ./debug.sh [MODE]

Debug Modes:
    gdb                 Connect via GDB server (default)
    monitor             Interactive QEMU monitor
    trace               Detailed execution trace
    memory              Memory and I/O trace
    profile             Performance profiling
    interactive         Interactive debugging mode
    help                Show this help message

Examples:
    ./debug.sh gdb              # Start with GDB server
    ./debug.sh trace            # Record execution trace
    ./debug.sh memory           # Trace memory access
    ./debug.sh interactive      # Full interactive mode

GDB Usage:
    ./debug.sh gdb
    # In another terminal:
    gdb kernel/bin/kernel.elf
    (gdb) target remote localhost:1234
    (gdb) break main
    (gdb) continue
    (gdb) step

Monitor Usage:
    ./debug.sh monitor
    # Type 'help' for available commands
    # Common: info registers, info mem, x /10i 0x...

EOF
}

main() {
    local mode="${1:-gdb}"
    
    case "$mode" in
        gdb)
            debug_with_gdb
            ;;
        monitor)
            debug_with_qemu_monitor
            ;;
        trace)
            debug_trace_execution
            ;;
        memory)
            debug_memory_trace
            ;;
        profile)
            performance_profile
            ;;
        interactive)
            interactive_debug
            ;;
        help)
            show_usage
            ;;
        *)
            print_error "Unknown debug mode: $mode"
            show_usage
            exit 1
            ;;
    esac
}

if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi
