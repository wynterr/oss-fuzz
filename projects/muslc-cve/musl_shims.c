#include <errno.h>

// Shim: musl's internal __errno_location renamed to ___errno_location
// Map it to the standard errno location
int *___errno_location(void) {
    return &errno;
}

// Shim: musl's __c_dot_utf8_locale - provide a minimal locale data
// This is used by iconv for UTF-8 handling
// Use a simple array to avoid struct conflicts
struct musl_locale_internal {
    const void *cat[6];
};
struct musl_locale_internal ____c_dot_utf8_locale = { {(void*)1, 0, 0, 0, 0, 0} };
