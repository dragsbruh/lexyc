<!--markdownlint-disable md013-->

# lexyc

this is an alternate compiler for the turing-complete [xy](https://git.disroot.org/nora.aoki/xy) programming language.

| instruction | what is this                          |
| ----------- | ------------------------------------- |
| `+`         | increment `x` by 1                    |
| `-`         | decrement `x` by 1.                   |
| `s`         | swap `x` and `y`                      |
| `[`         | if `x == 0`, jump to the matching `]` |
| `]`         | if `x != 0`, jump to the matching `[` |
| `o`         | dump all bits of `x` raw to stdout    |

## compiler targets

| target        | status                                   | notes                               |
| ------------- | ---------------------------------------- | ----------------------------------- |
| `interpreter` | 🔥 fully supported                       | has nice debugging capabilities     |
| `nasm`        | 😀👍 well supported (linux+windows only) | x86\_(32/64), windows is 64bit only |
| `x86`         | 🚧 planned                               |                                     |
| `arm`         | 🚧 planned                               |                                     |
| `risc-v`      | 🚧 planned                               |                                     |
| `javascript`  | 🚧 planned (blazingly fast)              | will be blazingly fast              |

## features

- reasonably good error messages
- dump instruction is buffered to every 1024 calls on compiled targets (customizable)
- rich-ish interpreter and debugging support.
- `+` an `-` instructions are merged for optimization

## guide

### setup

this will not be a language guide but rather on how to use this compiler.
to use the compiled assembly target, you will require:

- [nasm](https://www.nasm.us/) (if youre using nasm backends)
- a linker. if youre on linux, gnu linker is enough.
  if youre on windows, however, you can use [msvc linker](https://learn.microsoft.com/en-us/cpp/build/reference/linking?view=msvc-170),
  [gcc](https://gcc.gnu.org/), or [lld](https://lld.llvm.org/) (llvm's linker) or [clang](https://clang.llvm.org/)

if youre using the interpreter, you wont need these

### nasm targets

**for x86_64 linux:**

```sh
lexyc ./source.xy nasm-linux_x86_64 ./asm.s # this will create an assembly source file
nasm -f elf64 ./asm.s -o ./obj.o
ld ./obj.o -o ./executable
```

**for x86_32 linux:**

```sh
lexyc ./source.xy nasm-linux_x86_32 ./asm.s
nasm -f elf32 ./asm.s -o ./obj.o
ld -m elf_i386 ./obj.o -o ./executable # the -m flag may vary, but this worked on x86_64 linux host
```

**if youre on windows:**

**note**: i dont have windows so if the windows guide fails open an issue or lmk

```sh
lexyc .\source.xy nasm-windows_x86_64 .\asm.s
nasm -f win64 ./asm.s -o .\obj.o
link .\obj.obj kernel32.lib /subsystem:console /entry:mainCRTStartup

# or using gcc

gcc .\obj.obj -o .\executable.exe -nostdlib -lkernel32 -no-pie

# or clang with lld

clang .\obj.obj -o .\executable.exe -fuse-ld=lld -nostdlib -lkernel32 -no-pie
```

**for interpreter:**

```sh
lexyc ./source.xy interpreter
```

### help text

```sh
usage: `lexyc <file> <backend> [out-file]`
available backends and their supported targets:
  nasm
    linux_x86_64
    linux_x86_32
    windows_x86_64
  interpreter
    debug # this runs the interpreter but at every step, prints debug information
  debug
examples:
  lexyc file.xy nasm-linux_x86_64 -           # prints asm to stdout
  lexyc file.xy nasm-linux_x86_32 file.s      # writes asm to file
  lexyc file.xy interpreter -                 # interprets the code and prints to stdout
  lexyc file.xy interpreter-debug debug.txt   # interprets the code and every step writes debug information to file
  lexyc file.xy debug -                       # tokenizes the code and writes token debug information to stdout
notes:
  outfile is optional, it will default to stdout
```

## notes

- endianness for `o` intstruction depends on your architecture. it dumps all bits so there most probably will be null bytes too.
- this is a toy compiler, is statically linked (except on windows because kernel32) and is limited only by my skill issues
- `freebsd_*` targets are planned to be supported for all architectures but i dont have a way to test it right now, so yeah.
- compiled assemblies are not guaranteed to follow calling conventions or be thread safe.

## todo

- [ ] nasm backend
  - [ ] templeos target
  - [ ] freebsd target
  - [ ] macos target
  - [ ] follow proper call conventions (we hog on atleast two registers for the entire runtime)
  - [x] linux target
  - [x] windows target
- [ ] llvm backend
- [ ] native backends
  - [ ] x86_64/x86_32
    - [ ] linux
    - [ ] templeos
    - [ ] windows
  - [ ] arm
    - [ ] linux
    - [ ] templeos
    - [ ] windows
  - [ ] risc-v
    - [ ] linux
    - [ ] templeos
    - [ ] windows
- [ ] javascript backend (blazingly fast)
- [x] buffer dumps, 1000 syscalls per second is crazy
  - [x] custom buffer size (1024 dumps by default)

some backend targets like macos have been omitted.

## license

this project is licensed under the [BSD 2-Clause](./LICENSE) license.
