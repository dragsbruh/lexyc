<!--markdownlint-disable md013-->

# abi glue for nasm (x86) backends

- `print` label will be called and handles printing of `x` register
- `;stub` must exist once and will be replaced by platform-independent assembly code
- aliases `XR` and `YR` must exist for `x` register and `y` register respectively
- glue code must handle entrypoint, buffering/flushing (if any), and exit
