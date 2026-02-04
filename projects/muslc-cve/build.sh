#!/bin/bash -eu
# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
################################################################################

# Build script for muslc-cve project targeting CVE-2025-26519
#
# Strategy: Build musl-libc, rename symbols with musl_ prefix using objcopy
# to avoid conflicts with glibc, then use them as normal userspace functions.

cd $SRC/musl

# Checkout vulnerable version (before the fix in 1.2.6)
git checkout v1.2.5 || git checkout FETCH_HEAD

# Build musl with sanitizer-compatible flags
./configure --prefix=$WORK/musl-install --disable-shared
make -j$(nproc)

# Extract the object files we need from libc.a
mkdir -p $WORK/musl_objs
cd $WORK/musl_objs
ar x $SRC/musl/lib/libc.a

# Create a symbol renaming file for objcopy
# We rename iconv symbols to have musl_ prefix to avoid glibc conflicts
# Also rename internal symbols that they depend on
cat > $WORK/symbol_renames.txt << 'SYMEOF'
iconv musl_iconv
iconv_open musl_iconv_open
iconv_close musl_iconv_close
__errno_location ___errno_location
__c_dot_utf8_locale ____c_dot_utf8_locale
mbrtowc musl_mbrtowc
wcrtomb musl_wcrtomb
wctomb musl_wctomb
mbtowc musl_mbtowc
mblen musl_mblen
mbsinit musl_mbsinit
SYMEOF

# Rename symbols in the relevant object files
for obj in iconv.lo iconv_close.lo mbrtowc.lo wcrtomb.lo wctomb.lo mbtowc.lo mblen.lo mbsinit.lo internal.lo c_locale.lo __errno_location.lo; do
    if [ -f "$obj" ]; then
        objcopy --redefine-syms=$WORK/symbol_renames.txt "$obj" "${obj%.lo}_renamed.o"
    fi
done

# Create a library with renamed symbols
ar rcs $WORK/libmusl_iconv.a *_renamed.o

# Compile the shims
$CC $CFLAGS -c $SRC/musl_shims.c -o $WORK/musl_shims.o

# Compile the fuzzer
$CC $CFLAGS -c $SRC/iconv_euckr_fuzzer.c -o $WORK/iconv_fuzzer.o

# Link with the renamed musl iconv library and shims
$CXX $CXXFLAGS \
    $WORK/iconv_fuzzer.o \
    $WORK/musl_shims.o \
    $WORK/libmusl_iconv.a \
    $LIB_FUZZING_ENGINE \
    -o $OUT/iconv_euckr_fuzzer

# Seed corpus with EUC-KR test cases
# mkdir -p $WORK/corpus
# echo -ne '\xA1\xA1' > $WORK/corpus/s1
# echo -ne '\xFE\xFE' > $WORK/corpus/s2
# echo -ne '\xA1\xA1\xFE\xFE' > $WORK/corpus/s3
# echo -ne '\xC1\xA1\xC1\xA2' > $WORK/corpus/s4
# echo -ne '\xB0\xA1\xB0\xA2' > $WORK/corpus/s5
# zip -j $OUT/iconv_euckr_fuzzer_seed_corpus.zip $WORK/corpus/*
