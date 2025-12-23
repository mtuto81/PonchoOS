#!/bin/bash

# Variables
OSNAME="CustomOS"
BUILDDIR="$(dirname "$0")/bin"
OVMFDIR="$(dirname "$0")./OVMFbin"

# Lancer QEMU
qemu-system-x86_64 -machine q35 -m 256M -cpu qemu64 \
  -drive if=pflash,format=raw,unit=0,file="$OVMFDIR/OVMF_CODE-pure-efi.fd",readonly=on \
  -drive if=pflash,format=raw,unit=1,file="$OVMFDIR/OVMF_VARS-pure-efi.fd" \
  -cdrom CustomOS.iso -net none -bios "$OVMFDIR/OVMF_CODE-pure-efi.fd" \
  -serial stdio -monitor none -d int -no-reboot

