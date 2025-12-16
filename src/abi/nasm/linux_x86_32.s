global _start

%define xr esi
%define yr ebp
%define bl edi

%ifndef BUF_SIZE
  %define BUF_SIZE 1024 ; qwords in buf
%endif

section .bss
  outs resb BUF_SIZE

section .text

flush:
  mov eax, 4
  mov ebx, 1
  lea ecx, [outs]
  mov edx, bl
  int 0x80
  mov bl, 0
  ret

print:
  mov dword [ outs + bl ], xr
  add bl, 4
  cmp bl, BUF_SIZE*4
  jl noflush

  call flush
noflush:
  ret

quit:
  mov eax, 1
  mov ebx, 0
  int 0x80

_start:
  mov xr, 0
  mov yr, 0
;stub
  call flush
  jmp quit
