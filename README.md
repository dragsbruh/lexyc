<!--markdownlint-disable md013-->

# lexyc

this is an alternate compiler for the turing-complete [xy](https://git.disroot.org/nora.aoki/xy) programming language.

| instruction | what is this                                                |
| ----------- | ----------------------------------------------------------- |
| `+`         | increment `x` by 1                                          |
| `-`         | decrement `x` by 1.                                         |
| `s`         | swap `x` and `y`                                            |
| `[`         | if `x == 0`, jump to the instruction after the matching `]` |
| `]`         | if `x != 0`, jump to the instruction after the matching `[` |
| `o`         | dump all bits of `x` raw to stdout                          |

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

- dump instruction is buffered to every 1024 calls on compiled targets.
- rich-ish interpreter and debugging support.
- `+` an `-` instructions are merged for optimization

## notes

- endianness for `o` intstruction depends on your architecture. it dumps all bits so there most probably will be null bytes too.
- this is a toy compiler, is statically linked and is limited only by my skill issues
- `freebsd_*` targets are planned to be supported for all architectures but i dont have a way to test it right now, so yeah.
- compiled assemblies are not guaranteed to follow calling conventions or be thread safe.

## usage

```sh
usage: `lexyc <file> <backend> [out-file]`
available backends and their supported targets:
  nasm
    linux_x86_64
    linux_x86_32
    windows_x86_64
  interpreter
    debug
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

## todo

- [x] buffer dumps, 1000 syscalls per second is crazy
  - [ ] custom buffer size (1024 dumps by default)
- [ ] nasm backend
  - [x] linux target
  - [x] windows target
  - [ ] follow proper call conventions
  - [ ] templeos target
  - [ ] freebsd target
  - [ ] macos target
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

some backend targets like macos have been omitted.

## license

this project is licensed under the [BSD 2-Clause](./LICENSE) license.
