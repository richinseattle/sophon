#!/bin/bash

pushd asm/amd64
nasm -f bin -o loader.bin loader.s
popd

pushd core
./build.sh
popd

gcc util/run_shellcode.c -o run_shellcode

cp asm/amd64/loader.bin payload.bin
cat core/core.so >> payload.bin

./run_shellcode payload.bin