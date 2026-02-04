# muslc-cve OSS-Fuzz Project

This OSS-Fuzz project targets **CVE-2025-26519**, an out-of-bounds write vulnerability in musl libc's iconv implementation when converting from EUC-KR encoding to UTF-8.

## Vulnerability Details

- **CVE ID**: CVE-2025-26519
- **Affected Versions**: musl libc 0.9.13 through 1.2.5
- **Fixed Version**: 1.2.6
- **Vulnerability Type**: Out-of-bounds write
- **CVSS Score**: High severity

### Description

The vulnerability occurs in musl's iconv implementation when converting EUC-KR encoded text to UTF-8. The code incorrectly checks for 2 bytes of output buffer space when it actually writes 3 bytes for certain codepoints, leading to a buffer overflow that can corrupt memory.

### Technical Details

The bug is in the EUC-KR handling code that calculates how many bytes a given input character needs in UTF-8. For certain EUC-KR sequences, the code checks:
```c
if (out_remaining < 2) continue;  // Should check for 3 bytes!
output[0] = ...;
output[1] = ...;
output[2] = ...;  // Out-of-bounds write!
```

## Project Structure

- **project.yaml**: OSS-Fuzz project configuration
- **Dockerfile**: Container setup for building the fuzzer
- **build.sh**: Script to build musl libc (v1.2.5, vulnerable) and the fuzzer
- **iconv_euckr_fuzzer.c**: Fuzzing harness targeting the iconv EUC-KR to UTF-8 conversion
- **README.md**: This file

## Building and Running

### Using OSS-Fuzz Infrastructure

```bash
# From the oss-fuzz root directory
python infra/helper.py build_image muslc-cve
python infra/helper.py build_fuzzers muslc-cve
python infra/helper.py run_fuzzer muslc-cve iconv_euckr_fuzzer
```

### Checking for Crashes

```bash
python infra/helper.py check_build muslc-cve
```

## Fuzzer Description

The `iconv_euckr_fuzzer` harness:
1. Takes arbitrary byte sequences as input
2. Opens an iconv descriptor for EUC-KR → UTF-8 conversion
3. Tests the conversion with various output buffer sizes
4. Includes a smaller buffer test to more easily trigger the overflow

The fuzzer includes a seed corpus with:
- Valid EUC-KR sequences
- Edge case byte values
- Mixed sequences designed to trigger the vulnerability
- Korean Hangul characters

## Expected Results

When fuzzing the vulnerable version (1.2.5), the fuzzer should detect:
- Heap/stack buffer overflows
- Memory corruption
- Out-of-bounds writes detected by AddressSanitizer

## References

- [CVE-2025-26519 Details](https://www.cve.news/cve-2025-26519/)
- [musl libc Fix Commit](https://git.musl-libc.org/cgit/musl/commit/?id=6d3f37246ad6068897ea609cd6e40d72aad9e76)
- [NIST NVD Entry](https://nvd.nist.gov/vuln/detail/CVE-2025-26519)
- [musl Security Announcement](https://www.openwall.com/lists/musl/2024/05/10/4)

## License

This fuzzing project follows the OSS-Fuzz Apache 2.0 license.
