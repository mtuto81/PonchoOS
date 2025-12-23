#include "panic.h"
#include "BasicRenderer.h"
#include "cstr.h"

void Panic(const char* panicMessage){
    // Disable interrupts to prevent further faults
    asm ("cli");
    
    GlobalRenderer->ClearColour = 0x00ff0000;
    GlobalRenderer->Clear();

    GlobalRenderer->CursorPosition = {0, 0};

    GlobalRenderer->Colour = 0;

    GlobalRenderer->Print("========================================");
    GlobalRenderer->Next();
    GlobalRenderer->Print("KERNEL PANIC");
    GlobalRenderer->Next();
    GlobalRenderer->Print("========================================");
    GlobalRenderer->Next();
    GlobalRenderer->Next();

    GlobalRenderer->Print("Error: ");
    GlobalRenderer->Print(panicMessage);
    GlobalRenderer->Next();
    GlobalRenderer->Next();

    GlobalRenderer->Print("The kernel has encountered an unrecoverable error.");
    GlobalRenderer->Next();
    GlobalRenderer->Print("The system will halt.");
    GlobalRenderer->Next();
    GlobalRenderer->Next();

    GlobalRenderer->Print("========================================");
    
    // Halt the CPU
    while(true){
        asm ("hlt");
    }
}