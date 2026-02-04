// Copyright 2025 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////////

// Fuzzer for CVE-2025-26519: musl iconv EUC-KR to UTF-8 OOB write
//
// This fuzzer targets a vulnerability in musl libc's iconv implementation
// where converting certain EUC-KR encoded bytes to UTF-8 can cause an
// out-of-bounds write. The bug occurs because the code checks for 2 bytes
// of available output buffer space but may write 3 bytes for certain
// Korean character codepoints.

#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

// Declarations for musl's renamed iconv functions
typedef void *musl_iconv_t;
extern musl_iconv_t musl_iconv_open(const char *to, const char *from);
extern size_t musl_iconv(musl_iconv_t cd, char **inbuf, size_t *inbytesleft,
                         char **outbuf, size_t *outbytesleft);
extern int musl_iconv_close(musl_iconv_t cd);

int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
    if (size < 1 || size > 4096) return 0;

    // Open converter for EUC-KR to UTF-8 (the vulnerable path)
    musl_iconv_t cd = musl_iconv_open("UTF-8", "EUC-KR");
    if (cd == (musl_iconv_t)-1) return 0;

    char *inbuf = (char *)malloc(size);
    if (!inbuf) { musl_iconv_close(cd); return 0; }
    memcpy(inbuf, data, size);

    // Test with normal-sized output buffer
    size_t outsize = size * 4;
    char *outbuf = (char *)malloc(outsize);
    if (outbuf) {
        char *in = inbuf, *out = outbuf;
        size_t inleft = size, outleft = outsize;
        musl_iconv(cd, &in, &inleft, &out, &outleft);
        free(outbuf);
    }

    // Test with small output buffer - this is where the bug manifests
    // The bug: code checks for 2 bytes available but writes 3 bytes
    if (size >= 2) {
        char small[8];
        memset(small, 0x41, sizeof(small));
        char *in = inbuf, *out = small;
        size_t inleft = size, outleft = 2;  // Only 2 bytes - triggers the bug
        musl_iconv(cd, &in, &inleft, &out, &outleft);
    }

    free(inbuf);
    musl_iconv_close(cd);
    return 0;
}
