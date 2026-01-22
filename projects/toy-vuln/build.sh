#!/bin/bash -eu

# 1. Add the include path so the harness can find "toy-vuln/src/vuln.h"
# We add $SRC so that <toy-vuln/src/vuln.h> works.
INCLUDES="-I$SRC"

# 2. Compile the Target (vuln.c)
$CXX $CXXFLAGS $INCLUDES -c $SRC/toy-vuln/src/vuln.c -o $SRC/vuln.o

# 3. Compile the Harness and Link everything
# Notice we link against $SRC/vuln.o which we just built
$CXX $CXXFLAGS $INCLUDES -std=c++11 \
    $SRC/harness.cc $SRC/vuln.o \
    -o $OUT/toy_fuzzer \
    $LIB_FUZZING_ENGINE