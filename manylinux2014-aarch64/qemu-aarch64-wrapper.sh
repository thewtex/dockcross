#!/bin/sh

# Provide the libraries from the manylinux2014-aarch64 image required to run
# the Python libraries.
/usr/bin/qemu-aarch64 /lib/ld-linux-aarch64.so.1 --library-path /usr/local/aarch64/lib "$@"
