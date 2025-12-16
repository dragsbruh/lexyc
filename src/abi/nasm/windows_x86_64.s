global mainCRTStartup

extern GetStdHandle
extern WriteFile
extern ExitProcess

%define xr r12
%define yr r13

%define buf_len r14 ; bytes

%ifndef BUF_SIZE
  %define BUF_SIZE 1024 ; qwords in buf
%endif

section .bss
  outs resq BUF_SIZE

section .text

flush:
  mov rcx, [rsp+8] ; stdout FIXME: this is too hard of a dependence on stdout being on rsp+8 probably?
  lea rdx, [rel outs] ; buffer
  mov r8, buf_len ; bytes to write ; param is a dword (r8d) so it gets truncated but ig its fine
  mov r9, 0 ; ptr bytes written
  ; mov qword [rsp+32], 0 ; ptr overlapped ; probably unnecessary

  sub rsp, 40
  call WriteFile
  add rsp, 40

  mov buf_len, 0
  ret

print:
  lea rax, [ rel outs ]
  mov qword [ rax + buf_len ], xr
  add buf_len, 8
  cmp buf_len, BUF_SIZE*8
  jge flush  ; flush does a ret for us yey, important btw dont change to call.
  ret

mainCRTStartup:
  sub rsp, 40
  mov rcx, -11
  call GetStdHandle
  add rsp, 32 ; we push later
  push rax

  mov xr, 0
  mov yr, 0

;stub

  call flush

  xor rcx, rcx
  sub rsp, 40
  call ExitProcess
