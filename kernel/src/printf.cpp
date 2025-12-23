#include "printf.h"
#include "BasicRenderer.h"
#include "IO.h"
#include <stddef.h>
#include <stdint.h>
#include <stdarg.h>

// Internal helper functions
static void _itoa(int value, char* buffer, int base, int is_signed) {
    const char* digits = "0123456789abcdefghijklmnopqrstuvwxyz";
    char temp[32];
    int i = 0;
    unsigned int num;
    int negative = 0;

    if (is_signed && value < 0) {
        negative = 1;
        num = (unsigned int)(-value);
    } else {
        num = (unsigned int)value;
    }

    if (num == 0) {
        buffer[0] = '0';
        buffer[1] = '\0';
        return;
    }

    while (num > 0) {
        temp[i++] = digits[num % base];
        num /= base;
    }

    int idx = 0;
    if (negative) {
        buffer[idx++] = '-';
    }

    while (i > 0) {
        buffer[idx++] = temp[--i];
    }
    buffer[idx] = '\0';
}

static void _utoa(unsigned int value, char* buffer, int base) {
    const char* digits = "0123456789abcdefghijklmnopqrstuvwxyz";
    char temp[32];
    int i = 0;
    unsigned int num = value;

    if (num == 0) {
        buffer[0] = '0';
        buffer[1] = '\0';
        return;
    }

    while (num > 0) {
        temp[i++] = digits[num % base];
        num /= base;
    }

    int idx = 0;
    while (i > 0) {
        buffer[idx++] = temp[--i];
    }
    buffer[idx] = '\0';
}

static void _utoa_upper(unsigned int value, char* buffer, int base) {
    const char* digits = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    char temp[32];
    int i = 0;
    unsigned int num = value;

    if (num == 0) {
        buffer[0] = '0';
        buffer[1] = '\0';
        return;
    }

    while (num > 0) {
        temp[i++] = digits[num % base];
        num /= base;
    }

    int idx = 0;
    while (i > 0) {
        buffer[idx++] = temp[--i];
    }
    buffer[idx] = '\0';
}

static void _utoa64(uint64_t value, char* buffer, int base, bool uppercase) {
    const char* digits_low = "0123456789abcdefghijklmnopqrstuvwxyz";
    const char* digits_up = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    const char* digits = uppercase ? digits_up : digits_low;
    char temp[65];
    int i = 0;
    uint64_t num = value;

    if (num == 0) {
        buffer[0] = '0';
        buffer[1] = '\0';
        return;
    }

    while (num > 0) {
        temp[i++] = digits[num % base];
        num /= base;
    }

    int idx = 0;
    while (i > 0) {
        buffer[idx++] = temp[--i];
    }
    buffer[idx] = '\0';
}

int kernel_vprintf(const char* format, va_list args) {
    if (!format || !GlobalRenderer) {
        return 0;
    }

    int count = 0;
    char buffer[256];
    char char_buffer[2];

    // helper to also write to serial port (COM1)
    auto serial_putc = [](char c){
        const uint16_t COM1 = 0x3F8;
        // wait for Transmitter Holding Register Empty (bit 5)
        while ((inb(COM1 + 5) & 0x20) == 0);
        outb(COM1, (uint8_t)c);
    };

    while (*format != '\0') {
        if (*format == '%') {
            format++;
            
            if (*format == '%') {
                // Literal %
                GlobalRenderer->PutChar('%');
                serial_putc('%');
                count++;
            } else if (*format == 'd' || *format == 'i') {
                // Signed integer
                int value = va_arg(args, int);
                _itoa(value, buffer, 10, 1);
                GlobalRenderer->Print(buffer);
                for (int k = 0; buffer[k] != '\0'; k++) serial_putc(buffer[k]);
                count += (int)((buffer[0] == '-' && value < 0) ? 1 : 0);
                for (int i = 0; buffer[i] != '\0'; i++) count++;
            } else if (*format == 'u') {
                // Unsigned integer
                unsigned int value = va_arg(args, unsigned int);
                _utoa(value, buffer, 10);
                GlobalRenderer->Print(buffer);
                for (int k = 0; buffer[k] != '\0'; k++) serial_putc(buffer[k]);
                for (int i = 0; buffer[i] != '\0'; i++) count++;
            } else if (*format == 'x') {
                // Hexadecimal lowercase
                unsigned int value = va_arg(args, unsigned int);
                _utoa(value, buffer, 16);
                GlobalRenderer->Print(buffer);
                for (int k = 0; buffer[k] != '\0'; k++) serial_putc(buffer[k]);
                for (int i = 0; buffer[i] != '\0'; i++) count++;
            } else if (*format == 'X') {
                // Hexadecimal uppercase
                unsigned int value = va_arg(args, unsigned int);
                _utoa_upper(value, buffer, 16);
                GlobalRenderer->Print(buffer);
                for (int k = 0; buffer[k] != '\0'; k++) serial_putc(buffer[k]);
                for (int i = 0; buffer[i] != '\0'; i++) count++;
            } else if (*format == 'o') {
                // Octal
                unsigned int value = va_arg(args, unsigned int);
                _utoa(value, buffer, 8);
                GlobalRenderer->Print(buffer);
                for (int k = 0; buffer[k] != '\0'; k++) serial_putc(buffer[k]);
                for (int i = 0; buffer[i] != '\0'; i++) count++;
            } else if (*format == 's') {
                // String
                const char* str = va_arg(args, const char*);
                if (str) {
                    GlobalRenderer->Print(str);
                    for (int i = 0; str[i] != '\0'; i++) { count++; serial_putc(str[i]); }
                }
            } else if (*format == 'c') {
                // Character
                char value = (char)va_arg(args, int);
                char_buffer[0] = value;
                char_buffer[1] = '\0';
                GlobalRenderer->PutChar(value);
                serial_putc(value);
                count++;
            } else if (*format == 'p') {
                // Pointer (print full pointer width)
                void* ptr = va_arg(args, void*);
                GlobalRenderer->Print("0x");
                serial_putc('0'); serial_putc('x');
                count += 2;
                _utoa64((uint64_t)(uintptr_t)ptr, buffer, 16, false);
                GlobalRenderer->Print(buffer);
                for (int i = 0; buffer[i] != '\0'; i++) { count++; serial_putc(buffer[i]); }
            } else {
                // Unknown format specifier, just print it
                GlobalRenderer->PutChar('%');
                GlobalRenderer->PutChar(*format);
                serial_putc('%'); serial_putc(*format);
                count += 2;
            }
            format++;
        } else if (*format == '\n') {
            // Newline handling
            GlobalRenderer->Next();
            serial_putc('\r'); serial_putc('\n');
            count++;
            format++;
        } else {
            // Regular character
            GlobalRenderer->PutChar(*format);
            serial_putc(*format);
            count++;
            format++;
        }
    }

    return count;
}

int kernel_printf(const char* format, ...) {
    va_list args;
    va_start(args, format);
    int result = kernel_vprintf(format, args);
    va_end(args);
    return result;
}
