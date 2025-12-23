#!/bin/bash

# PonchoOS Build Pipeline - Installation & Verification Checklist
# Run this script to verify everything is set up correctly

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║   PonchoOS Build Pipeline - Verification Checklist         ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

passed=0
failed=0

check_file() {
    local file=$1
    local desc=$2
    
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $desc"
        ((passed++))
    else
        echo -e "${RED}✗${NC} $desc (NOT FOUND: $file)"
        ((failed++))
    fi
}

check_executable() {
    local file=$1
    local desc=$2
    
    if [ -x "$file" ]; then
        echo -e "${GREEN}✓${NC} $desc (executable)"
        ((passed++))
    elif [ -f "$file" ]; then
        echo -e "${YELLOW}⚠${NC} $desc (exists but not executable)"
        ((failed++))
    else
        echo -e "${RED}✗${NC} $desc (NOT FOUND)"
        ((failed++))
    fi
}

check_command() {
    local cmd=$1
    local desc=$2
    
    if command -v "$cmd" &> /dev/null; then
        local version=$($cmd --version 2>&1 | head -1)
        echo -e "${GREEN}✓${NC} $desc"
        ((passed++))
    else
        echo -e "${YELLOW}⚠${NC} $desc (MISSING)"
        ((failed++))
    fi
}

echo -e "${YELLOW}[1/4] Checking Build Pipeline Files...${NC}"
echo "───────────────────────────────────────────────────────────"

check_file "./build.sh" "Main build script"
check_file "./debug.sh" "Debug helper script"
check_file "./build.config" "Build configuration"
check_file "./kernel/Makefile" "Enhanced Makefile"
check_executable "./build.sh" "build.sh executable"
check_executable "./debug.sh" "debug.sh executable"

echo ""
echo -e "${YELLOW}[2/4] Checking Documentation Files...${NC}"
echo "───────────────────────────────────────────────────────────"

check_file "./BUILD_PIPELINE.md" "Complete documentation"
check_file "./QUICK_REFERENCE.md" "Quick reference guide"
check_file "./SETUP_COMPLETE.md" "Setup summary"
check_file "./VISUAL_GUIDE.md" "Visual guide"
check_file "./.vscode/tasks.json" "VS Code tasks"

echo ""
echo -e "${YELLOW}[3/4] Checking Required Build Tools...${NC}"
echo "───────────────────────────────────────────────────────────"

check_command "gcc" "GCC compiler"
check_command "nasm" "NASM assembler"
check_command "ld" "GNU linker"
check_command "make" "GNU Make"
check_command "qemu-system-x86_64" "QEMU x86_64 emulator"

echo ""
echo -e "${YELLOW}[4/4] Checking Optional Tools...${NC}"
echo "───────────────────────────────────────────────────────────"

check_command "mformat" "mtools FAT support"
check_command "grub-mkrescue" "GRUB ISO creation"
check_command "gdb" "GNU debugger (GDB)"
check_command "xorriso" "xorriso ISO tools"

echo ""
echo "───────────────────────────────────────────────────────────"
echo -e "${BLUE}Summary:${NC}"
echo -e "  ${GREEN}Passed: $passed${NC}"
echo -e "  ${RED}Failed: $failed${NC}"

if [ $failed -eq 0 ]; then
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ✓ All checks passed! Ready to build PonchoOS    ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Quick start:"
    echo -e "  ${BLUE}./build.sh --run${NC}          Build and run in QEMU"
    echo -e "  ${BLUE}./build.sh --help${NC}         Show help"
    echo -e "  ${BLUE}cat QUICK_REFERENCE.md${NC}    View quick guide"
    exit 0
else
    echo ""
    echo -e "${YELLOW}Some tools are missing. Installing them now...${NC}"
    echo ""
    
    if command -v apt-get &> /dev/null; then
        echo -e "${BLUE}Ubuntu/Debian detected${NC}"
        echo "Run this command to install missing tools:"
        echo ""
        echo -e "  ${BLUE}sudo apt-get install -y build-essential gcc nasm binutils make qemu-system-x86 mtools grub-pc-bin xorriso gdb${NC}"
        echo ""
    elif command -v dnf &> /dev/null; then
        echo -e "${BLUE}Fedora/RHEL detected${NC}"
        echo "Run this command to install missing tools:"
        echo ""
        echo -e "  ${BLUE}sudo dnf install -y gcc nasm binutils make qemu-system-x86 mtools grub2-tools-efi xorriso gdb${NC}"
        echo ""
    elif command -v pacman &> /dev/null; then
        echo -e "${BLUE}Arch Linux detected${NC}"
        echo "Run this command to install missing tools:"
        echo ""
        echo -e "  ${BLUE}sudo pacman -S base-devel gcc nasm binutils make qemu mtools grub xorriso gdb${NC}"
        echo ""
    fi
    
    echo -e "${YELLOW}After installing dependencies, run this script again to verify.${NC}"
    exit 1
fi
