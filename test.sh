#!/usr/bin/bash

set -eu

mkdir -p _build/

zig build

if [ ! -f _build/xy/xycc ];then
  repodir="_build/.repo.xy.tmp"
  cwdir=$(pwd)

  rm -rf _build/xy $repodir

  git clone https://git.disroot.org/nora.aoki/xy "$repodir"
  cd $repodir
  meson build
  cd build
  ninja

  cd "$cwdir"

  mkdir -p _build/xy/
  mv $repodir/build/xycc _build/xy/xycc.tmp
  rm -rf $repodir

  mv _build/xy/xycc.tmp _build/xy/xycc
fi;

./_build/xy/xycc examples/helloworld.xy _build/xy/out.ir
lli ./_build/xy/out.ir > _build/xy.txt

./zig-out/bin/lexyc examples/helloworld.xy debug _build/debug.txt
./zig-out/bin/lexyc examples/helloworld.xy interpreter _build/interpreter.txt

# mkdir -p _build/nasm-linux_x86_64
# ./zig-out/bin/lexyc examples/helloworld.xy nasm-linux_x86_64 _build/nasm-linux_x86_64/asm.s
# nasm -felf64 _build/nasm-linux_x86_64/asm.s -o _build/nasm-linux_x86_64/obj.o
# ld _build/nasm-linux_x86_64/obj.o -o _build/nasm-linux_x86_64/exe
# ./_build/nasm-linux_x86_64/exe > _build/nasm-linux_x86_64.txt

mkdir -p _build/nasm-linux_x86_32
./zig-out/bin/lexyc examples/helloworld.xy nasm-linux_x86_32 _build/nasm-linux_x86_32/asm.s
nasm -felf32 _build/nasm-linux_x86_32/asm.s -o _build/nasm-linux_x86_32/obj.o
ld -m elf_i386 _build/nasm-linux_x86_32/obj.o -o _build/nasm-linux_x86_32/exe
./_build/nasm-linux_x86_32/exe > _build/nasm-linux_x86_32.txt
