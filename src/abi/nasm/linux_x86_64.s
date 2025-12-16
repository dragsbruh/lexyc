global _start

%define xr r12
%define yr r13
%define bl r14 ; bytes

%define buf_size 1024 ; qwords in buf

section .bss
  outs resq buf_size

section .text
flush:
  mov rax, 1
  mov rdi, 1
  lea rsi, [rel outs]
  mov rdx, bl
  syscall
  mov bl, 0
  ret

print:
  mov qword [ outs + bl ], xr
  add bl, 8
  cmp bl, buf_size*8
  jl noflush
  call flush
noflush:
  ret

quit:
  mov rax, 60
  mov rdi, 0
  syscall

_start:
  mov xr, 0
  mov yr, 0
;stub
  call flush
  jmp quit
