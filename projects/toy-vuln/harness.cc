#include <stdint.h>
#include <stddef.h>

// Point specifically to the folder where Docker cloned the repo
#include "toy-vuln/src/vuln.h" 

extern "C" int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
    vulnerable_function(data, size);
    return 0;
}