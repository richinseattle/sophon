#!/bin/sh

mv /usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/crtbeginT.o /usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/crtbeginT.o.bak
cp /usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/crtbeginS.o /usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/crtbeginT.o
mv /usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/crtend.o /usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/crtend.o.bak
cp /usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/crtendS.o /usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/crtend.o

gcc --static -fPIC --shared core.c /usr/lib/libc.a -o core.so
strip core.so