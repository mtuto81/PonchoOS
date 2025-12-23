#include "kernelUtil.h"
#include "gdt/gdt.h"
#include "interrupts/IDT.h"
#include "interrupts/interrupts.h"
#include "IO.h"
#include "memory/heap.h"
#include "printf.h"

KernelInfo kernelInfo; 

void PrepareMemory(BootInfo* bootInfo){
    uint64_t mMapEntries = bootInfo->mMapSize / bootInfo->mMapDescSize;

    GlobalAllocator = PageFrameAllocator();
    GlobalAllocator.ReadEFIMemoryMap(bootInfo->mMap, bootInfo->mMapSize, bootInfo->mMapDescSize);

    uint64_t kernelSize = (uint64_t)&_KernelEnd - (uint64_t)&_KernelStart;
    uint64_t kernelPages = (uint64_t)kernelSize / 4096 + 1;

    GlobalAllocator.LockPages(&_KernelStart, kernelPages);

    PageTable* PML4 = (PageTable*)GlobalAllocator.RequestPage();
    memset(PML4, 0, 0x1000);

    g_PageTableManager = PageTableManager(PML4);

    for (uint64_t t = 0; t < GetMemorySize(bootInfo->mMap, mMapEntries, bootInfo->mMapDescSize); t+= 0x1000){
        g_PageTableManager.MapMemory((void*)t, (void*)t);
    }

    uint64_t fbBase = (uint64_t)bootInfo->framebuffer->BaseAddress;
    uint64_t fbSize = (uint64_t)bootInfo->framebuffer->BufferSize + 0x1000;
    GlobalAllocator.LockPages((void*)fbBase, fbSize/ 0x1000 + 1);
    for (uint64_t t = fbBase; t < fbBase + fbSize; t += 4096){
        g_PageTableManager.MapMemory((void*)t, (void*)t);
    }

    asm ("mov %0, %%cr3" : : "r" (PML4));

    kernelInfo.pageTableManager = &g_PageTableManager;
}

IDTR idtr;
void SetIDTGate(void* handler, uint8_t entryOffset, uint8_t type_attr, uint8_t selector){

    IDTDescEntry* interrupt = (IDTDescEntry*)(idtr.Offset + entryOffset * sizeof(IDTDescEntry));
    interrupt->SetOffset((uint64_t)handler);
    interrupt->type_attr = type_attr;
    interrupt->selector = selector;
}

void PrepareInterrupts(){
    idtr.Limit = 0x0FFF;
    idtr.Offset = (uint64_t)GlobalAllocator.RequestPage();

    SetIDTGate((void*)PageFault_Handler, 0xE, IDT_TA_InterruptGate, 0x08);
    SetIDTGate((void*)DoubleFault_Handler, 0x8, IDT_TA_InterruptGate, 0x08);
    SetIDTGate((void*)GPFault_Handler, 0xD, IDT_TA_InterruptGate, 0x08);
    SetIDTGate((void*)KeyboardInt_Handler, 0x21, IDT_TA_InterruptGate, 0x08);
    SetIDTGate((void*)MouseInt_Handler, 0x2C, IDT_TA_InterruptGate, 0x08);
    SetIDTGate((void*)PITInt_Handler, 0x20, IDT_TA_InterruptGate, 0x08);
 
    asm ("lidt %0" : : "m" (idtr));

    RemapPIC();
}

void PrepareACPI(BootInfo* bootInfo){
    // Check if RSDP is valid before accessing
    if (bootInfo == NULL || bootInfo->rsdp == NULL){
        kernel_printf("  [ACPI] WARNING: RSDP is NULL, skipping ACPI initialization\n");
        return;
    }
    
    kernel_printf("  [ACPI] RSDP found at 0x%p\n", bootInfo->rsdp);
    kernel_printf("    - Signature: %.8s\n", (char*)bootInfo->rsdp->Signature);
    kernel_printf("    - OEM: %.6s\n", (char*)bootInfo->rsdp->OEMId);
    kernel_printf("    - Revision: %u\n", bootInfo->rsdp->Revision);
    
    ACPI::SDTHeader* xsdt = (ACPI::SDTHeader*)(bootInfo->rsdp->XSDTAddress);
    
    if (xsdt == NULL){
        kernel_printf("  [ACPI] WARNING: XSDT is NULL at 0x%p, skipping PCI enumeration\n", bootInfo->rsdp->XSDTAddress);
        return;
    }

    kernel_printf("  [ACPI] XSDT found at 0x%p\n", xsdt);
    kernel_printf("    - Signature: %.4s\n", (char*)xsdt->Signature);
    kernel_printf("    - Length: %u bytes\n", xsdt->Length);
    
    ACPI::MCFGHeader* mcfg = (ACPI::MCFGHeader*)ACPI::FindTable(xsdt, (char*)"MCFG");
    
    if (mcfg != NULL){
        kernel_printf("  [ACPI] MCFG table found at 0x%p\n", mcfg);
        kernel_printf("    - Starting PCI enumeration...\n");
        PCI::EnumeratePCI(mcfg);
        kernel_printf("    - PCI enumeration complete\n");
    } else {
        kernel_printf("  [ACPI] WARNING: MCFG table not found\n");
    }
}

BasicRenderer r = BasicRenderer(NULL, NULL);
KernelInfo InitializeKernel(BootInfo* bootInfo){
    // Disable interrupts during kernel initialization
    asm ("cli");
    
    // Initialize renderer first for debug output
    r = BasicRenderer(bootInfo->framebuffer, bootInfo->psf1_Font);
    GlobalRenderer = &r;

    // Initialize serial (COM1) so printk/printf can safely write to serial
    auto InitSerial = [](){
        const uint16_t COM1 = 0x3F8;
        // Disable all interrupts
        outb(COM1 + 1, 0x00);
        // Enable DLAB to set baud divisor
        outb(COM1 + 3, 0x80);
        // Set divisor to 1 (115200 baud)
        outb(COM1 + 0, 0x01);
        outb(COM1 + 1, 0x00);
        // 8 bits, no parity, one stop bit
        outb(COM1 + 3, 0x03);
        // Enable FIFO, clear them, set 14-byte threshold
        outb(COM1 + 2, 0xC7);
        // IRQs enabled, RTS/DSR set
        outb(COM1 + 4, 0x0B);
    };
    InitSerial();

    GlobalRenderer->Print("Kernel Initialization Starting...");
    GlobalRenderer->Next();

    // Initialize GDT
    GlobalRenderer->Print("[*] Loading GDT...");
    GlobalRenderer->Next();
    GDTDescriptor gdtDescriptor;
    gdtDescriptor.Size = sizeof(GDT) - 1;
    gdtDescriptor.Offset = (uint64_t)&DefaultGDT;
    LoadGDT(&gdtDescriptor);

    // Prepare memory management
    GlobalRenderer->Print("[*] Setting up paging...");
    GlobalRenderer->Next();
    PrepareMemory(bootInfo);

    // Clear framebuffer
    memset(bootInfo->framebuffer->BaseAddress, 0, bootInfo->framebuffer->BufferSize);

    // Initialize heap
    GlobalRenderer->Print("[*] Initializing heap...");
    GlobalRenderer->Next();
    InitializeHeap((void*)0x0000100000000000, 0x10);

    // Setup interrupt handlers
    GlobalRenderer->Print("[*] Setting up interrupts...");
    GlobalRenderer->Next();
    PrepareInterrupts();

    // Initialize input
    GlobalRenderer->Print("[*] Initializing PS/2 mouse...");
    GlobalRenderer->Next();
    InitPS2Mouse();

    // Setup ACPI and PCI (safely)
    GlobalRenderer->Print("[*] Enumerating ACPI/PCI...");
    GlobalRenderer->Next();
    PrepareACPI(bootInfo);

    // Configure PIC (Programmable Interrupt Controller)
    GlobalRenderer->Print("[*] Configuring PIC...");
    GlobalRenderer->Next();
    outb(PIC1_DATA, 0b11111000);
    outb(PIC2_DATA, 0b11101111);

    GlobalRenderer->Print("[*] Enabling interrupts...");
    GlobalRenderer->Next();
    
    // Enable interrupts now that everything is set up
    asm ("sti");
    
    GlobalRenderer->Print("[*] Kernel initialization complete!");
    GlobalRenderer->Next();

    return kernelInfo;
}