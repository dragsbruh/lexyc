#!/usr/bin/bash

set -euo pipefail

mkdir -p _build/

zig build

if [ ! -f _build/xycc ];then
  repodir="_build/.repo.xy.tmp"
  cwdir=$(pwd)

  rm -rf _build/xy $repodir

  git clone https://git.disroot.org/nora.aoki/xy "$repodir"
  cd $repodir
  meson build
  cd build
  ninja

  cd "$cwdir"

  mv $repodir/build/xycc _build/xycc.tmp
  rm -rf $repodir

  mv _build/xycc.tmp _build/xycc
fi;

mkdir -p _build/out/

# original xycc

mkdir -p _build/xy
mkdir -p _build/bin/xy

./_build/xycc examples/helloworld.xy _build/xy/out.ll
clang _build/xy/out.ll -o _build/bin/xy/exe -Wno-override-module
./_build/bin/xy/exe > _build/out/xy.txt

./_build/xycc examples/helloworld_loop_compat.xy _build/xy/loop-compat-out.ll
clang _build/xy/loop-compat-out.ll -o _build/bin/xy/loop-compat-exe -Wno-override-module

# interpreter/debug targets

./zig-out/bin/lexyc examples/helloworld.xy debug _build/out/debug.txt
./zig-out/bin/lexyc examples/helloworld.xy interpreter _build/out/interpreter.txt
./zig-out/bin/lexyc examples/helloworld.xy interpreter-debug _build/out/interpreter-debug.txt

# nasm

## linux_x86_64

mkdir -p _build/nasm-linux_x86_64/
mkdir -p _build/bin/nasm-linux_x86_64/

./zig-out/bin/lexyc examples/helloworld.xy nasm-linux_x86_64 _build/nasm-linux_x86_64/asm.s
nasm -f elf64 _build/nasm-linux_x86_64/asm.s -o _build/nasm-linux_x86_64/obj.o
ld _build/nasm-linux_x86_64/obj.o -o _build/bin/nasm-linux_x86_64/exe
./_build/bin/nasm-linux_x86_64/exe > _build/out/nasm-linux_x86_64.txt

./zig-out/bin/lexyc examples/helloworld_loop.xy nasm-linux_x86_64 _build/nasm-linux_x86_64/loop-asm.s
nasm -f elf64 _build/nasm-linux_x86_64/loop-asm.s -o _build/nasm-linux_x86_64/loop-obj.o
ld _build/nasm-linux_x86_64/loop-obj.o -o _build/bin/nasm-linux_x86_64/loop-exe

./zig-out/bin/lexyc examples/helloworld_loop_compat.xy nasm-linux_x86_64 _build/nasm-linux_x86_64/loop-compat-asm.s
nasm -f elf64 _build/nasm-linux_x86_64/loop-compat-asm.s -o _build/nasm-linux_x86_64/loop-compat-obj.o
ld _build/nasm-linux_x86_64/loop-compat-obj.o -o _build/bin/nasm-linux_x86_64/loop-compat-exe

## linux_x86_32

mkdir -p _build/nasm-linux_x86_32/
mkdir -p _build/bin/nasm-linux_x86_32/

./zig-out/bin/lexyc examples/helloworld.xy nasm-linux_x86_32 _build/nasm-linux_x86_32/asm.s
nasm -f elf32 _build/nasm-linux_x86_32/asm.s -o _build/nasm-linux_x86_32/obj.o
ld -m elf_i386 _build/nasm-linux_x86_32/obj.o -o _build/bin/nasm-linux_x86_32/exe
./_build/bin/nasm-linux_x86_32/exe > _build/out/nasm-linux_x86_32.txt

./zig-out/bin/lexyc examples/helloworld_loop.xy nasm-linux_x86_32 _build/nasm-linux_x86_32/loop-asm.s
nasm -f elf32 _build/nasm-linux_x86_32/loop-asm.s -o _build/nasm-linux_x86_32/loop-obj.o
ld -m elf_i386 _build/nasm-linux_x86_32/loop-obj.o -o _build/bin/nasm-linux_x86_32/loop-exe

./zig-out/bin/lexyc examples/helloworld_loop_compat.xy nasm-linux_x86_32 _build/nasm-linux_x86_32/loop-compat-asm.s
nasm -f elf32 _build/nasm-linux_x86_32/loop-compat-asm.s -o _build/nasm-linux_x86_32/loop-compat-obj.o
ld -m elf_i386 _build/nasm-linux_x86_32/loop-compat-obj.o -o _build/bin/nasm-linux_x86_32/loop-compat-exe

## windows_x86_64

mkdir -p _build/nasm-windows_x86_64/
mkdir -p _build/bin/nasm-windows_x86_64/

./zig-out/bin/lexyc examples/helloworld.xy nasm-windows_x86_64 _build/nasm-windows_x86_64/asm.s
nasm -f win64 _build/nasm-windows_x86_64/asm.s -o _build/nasm-windows_x86_64/obj.o
x86_64-w64-mingw32-gcc _build/nasm-windows_x86_64/obj.o -o _build/bin/nasm-windows_x86_64/exe.exe -nostartfiles -lkernel32
wine ./_build/bin/nasm-windows_x86_64/exe.exe > _build/out/nasm-windows_x86_64.txt

./zig-out/bin/lexyc examples/helloworld_loop.xy nasm-windows_x86_64 _build/nasm-windows_x86_64/loop-asm.s
nasm -f win64 _build/nasm-windows_x86_64/loop-asm.s -o _build/nasm-windows_x86_64/loop-obj.o
x86_64-w64-mingw32-gcc _build/nasm-windows_x86_64/loop-obj.o -o _build/bin/nasm-windows_x86_64/loop-exe.exe -nostartfiles -lkernel32

./zig-out/bin/lexyc examples/helloworld_loop_compat.xy nasm-windows_x86_64 _build/nasm-windows_x86_64/loop-compat-asm.s
nasm -f win64 _build/nasm-windows_x86_64/loop-compat-asm.s -o _build/nasm-windows_x86_64/loop-compat-obj.o
x86_64-w64-mingw32-gcc _build/nasm-windows_x86_64/loop-compat-obj.o -o _build/bin/nasm-windows_x86_64/loop-compat-exe.exe -nostartfiles -lkernel32
