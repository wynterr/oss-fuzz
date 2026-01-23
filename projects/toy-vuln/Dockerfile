FROM gcr.io/oss-fuzz-base/base-builder

ENV V=1
# 1. Clone your SEPARATE repo into the container
# This puts code at: /src/toy-vuln
RUN git clone https://github.com/wynterr/toy-vuln.git
# COPY src/ $SRC/toy-vuln/src/

# 2. Copy the build script and harness from the current folder (oss-fuzz/projects/toy-example)
# directly into $SRC/
COPY build.sh harness.cc $SRC/

RUN chmod +x $SRC/build.sh

WORKDIR $SRC/