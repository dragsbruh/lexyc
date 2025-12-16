global mainCRTStartup

extern GetStdHandle
extern WriteFile
extern ExitProcess

%define xr r12
%define yr r13
%define bl r14d ; bytes
%define tmp r15
%define stdout rbp
%define buf_size 1024 ; qwords buf

section .bss
  outs resq buf_size

  section .text
flush:
  mov rcx, stdout
  lea rdx, [ rel outs ]
  mov r8d, bl
  mov r9, 0
  mov qword [rsp+32], 0
  sub rsp, 40
  call WriteFile
  add rsp, 40
  mov bl, 0
  ret

print:
  lea tmp, [ rel outs ]
  movzx rbx, bl
  mov qword [ tmp + rbx ], xr
  add bl, 8
  cmp bl, buf_size*8
  jl noflush
  call flush
noflush:
  ret

quit:
  xor rcx, rcx
  sub rsp, 40
  call ExitProcess

mainCRTStartup:
  sub rsp, 40
  mov rcx, -11
  call GetStdHandle
  add rsp, 40
  mov stdout, rax
  mov xr, 0
  mov yr, 0
;stub
  call flush
  jmp quit
