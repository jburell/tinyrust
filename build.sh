#!/bin/bash

set -e

for d in rustc git cargo ar ld objcopy nasm; do
    which $d >/dev/null || (echo "Can't find $d, needed to build"; exit 1)
done

printf "Tested on rustc 1.1.0-dev (435622028 2015-05-04)\nYou have  "
rustc --version
echo

if [ ! -d syscall.rs ]; then
    git clone https://github.com/kmcallister/syscall.rs
    (cd syscall.rs && cargo build --release)
    echo
fi

set -x

rustc tinyrust.rs \
    -O -C no-stack-check -C relocation-model=static \
    -L syscall.rs/target/release

ar x libtinyrust.rlib tinyrust.0.o

objdump -dr tinyrust.0.o
echo

ld --gc-sections -e main -T script.ld -o payload tinyrust.0.o
objcopy -j combined -O binary payload payload.bin

ENTRY=$(nm -f posix payload | grep '^main ' | awk '{print $3}')
nasm -f bin -o tinyrust -D entry=0x$ENTRY elf.s

chmod +x tinyrust
hd tinyrust
wc -c tinyrust
