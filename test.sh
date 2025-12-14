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

build_nasm() {
  local source=$1
  local target=$2
  local tag=${3:+${3}-}
  local is_64=${4:-0}

  local nasm_format="elf32"
  local ld_format="elf_i386"
  if (( is_64 )); then
    nasm_format="elf64"
    ld_format="elf_x86_64"
  fi

  mkdir -p "_build/nasm-$target"

  ./zig-out/bin/lexyc "$source" "nasm-$target" "_build/nasm-$target/${tag}asm.s"
  nasm -f "$nasm_format" "_build/nasm-${target}/${tag}asm.s" -o "_build/nasm-$target/${tag}obj.o"
  ld -m "$ld_format" "_build/nasm-$target/${tag}obj.o" -o "_build/nasm-$target/${tag}exe"
}

./_build/xy/xycc examples/helloworld.xy _build/xy/out.ll
clang _build/xy/out.ll -o _build/xy/exe -Wno-override-module
./_build/xy/exe > _build/xy.txt

./_build/xy/xycc examples/helloworld_loop_compat.xy _build/xy/loop-out.ll
clang _build/xy/loop-out.ll -o _build/xy/loop-exe -Wno-override-module

./zig-out/bin/lexyc examples/helloworld.xy debug _build/debug.txt
./zig-out/bin/lexyc examples/helloworld.xy interpreter _build/interpreter.txt

build_nasm examples/helloworld.xy linux_x86_64 "" 1
./_build/nasm-linux_x86_64/exe > _build/nasm-linux_x86_64.txt

build_nasm examples/helloworld_loop.xy linux_x86_64 "loop" 1

build_nasm examples/helloworld.xy linux_x86_32 "" 0
./_build/nasm-linux_x86_32/exe > _build/nasm-linux_x86_32.txt

build_nasm examples/helloworld_loop.xy linux_x86_32 "loop" 0
