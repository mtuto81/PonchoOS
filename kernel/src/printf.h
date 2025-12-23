#pragma once

#include <stddef.h>
#include <stdint.h>
#include <stdarg.h>

/**
 * @brief Printf-like function for kernel output to the framebuffer
 * 
 * Supports format specifiers:
 * - %d, %i : signed integer
 * - %u : unsigned integer
 * - %x, %X : hexadecimal (lowercase, uppercase)
 * - %o : octal
 * - %s : string
 * - %c : character
 * - %p : pointer (hex with 0x prefix)
 * - %% : literal percent
 * 
 * @param format Format string
 * @param ... Variable arguments
 */
int kernel_printf(const char* format, ...);

/**
 * @brief Printf variant that takes va_list for internal use
 */
int kernel_vprintf(const char* format, va_list args);
