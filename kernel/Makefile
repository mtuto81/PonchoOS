
OSNAME = NGOS

GNUEFI = ../gnu-efi
OVMFDIR = ../OVMFbin
LDS = kernel.ld
CC = gcc
ASMC = nasm
CXX = g++
CXXFLAGS = $(CFLAGS)
LD = ld

CFLAGS = -ffreestanding -fshort-wchar -mno-red-zone -fno-exceptions -Wall -Wextra
ASMFLAGS = 
# Linker flags: use kernel linker script and target ELF x86_64
LDFLAGS = -T $(LDS) -static -Bsymbolic -nostdlib -m elf_x86_64

SRCDIR := src
OBJDIR := lib
BUILDDIR = bin
BOOTEFI := $(GNUEFI)/x86_64/bootloader/main.efi

rwildcard=$(foreach d,$(wildcard $(1:=/*)),$(call rwildcard,$d,$2) $(filter $(subst *,%,$2),$d))

SRC = $(call rwildcard,$(SRCDIR),*.cpp)  
ASMSRC = $(call rwildcard,$(SRCDIR),*.asm)  
OBJS = $(patsubst $(SRCDIR)/%.cpp, $(OBJDIR)/%.o, $(SRC))
OBJS += $(patsubst $(SRCDIR)/%.asm, $(OBJDIR)/%_asm.o, $(ASMSRC))
DIRS = $(wildcard $(SRCDIR)/*)

kernel: $(OBJS) link

$(OBJDIR)/interrupts/interrupts.o: $(SRCDIR)/interrupts/interrupts.cpp
	@ echo !==== COMPILING $^
	@ mkdir -p $(@D)
	$(CXX) -mno-red-zone -mgeneral-regs-only -ffreestanding -c $^ -o $@

$(OBJDIR)/%.o: $(SRCDIR)/%.cpp
	@ echo !==== COMPILING $^
	@ mkdir -p $(@D)
	$(CXX) $(CXXFLAGS) -c $^ -o $@
	
$(OBJDIR)/%_asm.o: $(SRCDIR)/%.asm
	@ echo !==== COMPILING $^
	@ mkdir -p $(@D)
	$(ASMC) $(ASMFLAGS) $^ -f elf64 -o $@
	 
link:
	@ echo !==== LINKING
	$(LD) $(LDFLAGS) -o $(BUILDDIR)/kernel.elf $(OBJS)

setup:
	@mkdir $(BUILDDIR)
	@mkdir $(SRCDIR)
	@mkdir $(OBJDIR)

buildimg:
	@ echo !==== CREATING FAT IMAGE
	@ mkdir -p $(BUILDDIR)
	dd if=/dev/zero of=$(BUILDDIR)/$(OSNAME).img bs=512 count=93750 2>/dev/null
	mformat -i $(BUILDDIR)/$(OSNAME).img -F -L 32 ::
	mmd -i $(BUILDDIR)/$(OSNAME).img ::/EFI 2>/dev/null || true
	mmd -i $(BUILDDIR)/$(OSNAME).img ::/EFI/BOOT 2>/dev/null || true
	@ echo [*] Copying bootloader...
	mcopy -i $(BUILDDIR)/$(OSNAME).img $(BOOTEFI) ::/EFI/BOOT/main.efi
	@ echo [*] Copying startup script...
	mcopy -i $(BUILDDIR)/$(OSNAME).img startup.nsh ::/
	@ echo [*] Copying kernel...
	mcopy -i $(BUILDDIR)/$(OSNAME).img $(BUILDDIR)/kernel.elf ::/
	@ echo [*] Copying font...
	-mcopy -i $(BUILDDIR)/$(OSNAME).img $(BUILDDIR)/zap-light16.psf ::/
	@ echo !==== FAT IMAGE CREATED: $(BUILDDIR)/$(OSNAME).img

run:
	qemu-system-x86_64 -drive file=$(BUILDDIR)/$(OSNAME).img -m 256M -cpu qemu64 -drive if=pflash,format=raw,unit=0,file="$(OVMFDIR)/OVMF_CODE-pure-efi.fd",readonly=on -drive if=pflash,format=raw,unit=1,file="$(OVMFDIR)/OVMF_VARS-pure-efi.fd" -net none

# Enhanced targets for QEMU build pipeline
.PHONY: clean all buildall buildall-run run-debug help

clean:
	@ echo !==== CLEANING BUILD ARTIFACTS
	@ rm -rf $(OBJDIR)
	@ rm -rf $(BUILDDIR)
	@ echo !==== CLEAN COMPLETE

all: kernel buildimg
	@ echo !==== ALL BUILD TARGETS COMPLETE

buildall: clean all
	@ echo !==== FULL BUILD COMPLETE

run-debug:
	qemu-system-x86_64 -machine q35 -m 256M -cpu qemu64 \
		-drive if=pflash,format=raw,unit=0,file="$(OVMFDIR)/OVMF_CODE-pure-efi.fd",readonly=on \
		-drive if=pflash,format=raw,unit=1,file="$(OVMFDIR)/OVMF_VARS-pure-efi.fd" \
		-drive file=$(BUILDDIR)/$(OSNAME).img \
		-serial stdio -d int -no-reboot -net none

buildall-run: buildall run
	@ echo !==== BUILD AND RUN COMPLETE

help:
	@ echo "PonchoOS Kernel Build Targets:"
	@ echo "  kernel       - Build kernel only"
	@ echo "  buildimg     - Build disk image"
	@ echo "  all          - Build kernel and image"
	@ echo "  buildall     - Clean and build everything"
	@ echo "  run          - Run in QEMU with standard settings"
	@ echo "  run-debug    - Run in QEMU with debug mode enabled"
	@ echo "  buildall-run - Clean, build, and run"
	@ echo "  clean        - Remove build artifacts"
	@ echo "  help         - Show this help message"
