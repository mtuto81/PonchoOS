#include "kernelUtil.h"
#include "memory/heap.h"
#include "scheduling/pit/pit.h"
#include "printf.h"

extern "C" void _start(BootInfo* bootInfo){

    KernelInfo kernelInfo = InitializeKernel(bootInfo);
    
    // Print kernel information
    kernel_printf("\n");
    kernel_printf("========================================\n");
    kernel_printf("=== PonchoOS Kernel Enumeration Info ===\n");
    kernel_printf("========================================\n\n");
    
    // Kernel Info
    kernel_printf("[KERNEL INFO]\n");
    kernel_printf("  Kernel Started Successfully\n");
    kernel_printf("  Page Table Manager: 0x%p\n", kernelInfo.pageTableManager);
    kernel_printf("  Kernel Entry Point: _start\n\n");
    
    // Boot Information
    kernel_printf("[BOOT INFO]\n");
    if (bootInfo) {
        kernel_printf("  Framebuffer Address: 0x%p\n", bootInfo->framebuffer);
        if (bootInfo->framebuffer) {
            kernel_printf("    - Base Address: 0x%p\n", bootInfo->framebuffer->BaseAddress);
            kernel_printf("    - Buffer Size: 0x%p bytes\n", bootInfo->framebuffer->BufferSize);
            kernel_printf("    - Width: %u, Height: %u\n", bootInfo->framebuffer->Width, bootInfo->framebuffer->Height);
            kernel_printf("    - Pixels Per Scanline: %u\n", bootInfo->framebuffer->PixelsPerScanLine);
        }
        kernel_printf("  PSF1 Font: 0x%p\n", bootInfo->psf1_Font);
        kernel_printf("  Memory Map: 0x%p (Size: 0x%x)\n", bootInfo->mMap, bootInfo->mMapSize);
        kernel_printf("  Memory Descriptor Size: 0x%x\n", bootInfo->mMapDescSize);
    }
    kernel_printf("\n");
    
    // ACPI Information
    kernel_printf("[ACPI INFO]\n");
    if (bootInfo && bootInfo->rsdp) {
        kernel_printf("  RSDP Found: 0x%p\n", bootInfo->rsdp);
        kernel_printf("    - Signature: %.8s\n", (char*)bootInfo->rsdp->Signature);
        kernel_printf("    - OEM ID: %.6s\n", (char*)bootInfo->rsdp->OEMId);
        kernel_printf("    - Revision: %u\n", bootInfo->rsdp->Revision);
        kernel_printf("    - RSDT Address: 0x%x\n", bootInfo->rsdp->RSDTAddress);
        kernel_printf("    - XSDT Address: 0x%p\n", bootInfo->rsdp->XSDTAddress);
    } else {
        kernel_printf("  RSDP: Not found or NULL\n");
    }
    kernel_printf("\n");
    
    // PCI Information
    kernel_printf("[PCI ENUMERATION]\n");
    if (bootInfo && bootInfo->rsdp && bootInfo->rsdp->XSDTAddress) {
        kernel_printf("  XSDT Found at: 0x%p\n", bootInfo->rsdp->XSDTAddress);
        kernel_printf("  Enumerating PCI devices...\n");
        kernel_printf("  (PCI devices displayed during enumeration above)\n");
    } else {
        kernel_printf("  Cannot enumerate PCI: ACPI tables not available\n");
    }
    kernel_printf("\n");
    
    kernel_printf("========================================\n");
    kernel_printf("=== System Ready ===\n");
    kernel_printf("========================================\n");

    while(true){
        asm ("hlt");
    }

}