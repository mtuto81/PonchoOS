#include "kernelUtil.h"

// Temporary test kernel entry
extern "C" void _start_test(BootInfo* bootInfo){
    // Just halt - test if we can get here
    while(true){
        asm("hlt");
    }
}
