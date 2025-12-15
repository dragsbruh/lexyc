const std = @import("std");
const Ins = @import("../instructions.zig").Ins;

const Backend = @import("../Backend.zig");

pub fn compile(_: std.mem.Allocator, out: *std.Io.Writer, maybe_target: ?Backend.Target, instructions: []Ins) !void {
    const target = maybe_target orelse return error.RequiresTarget;
    if (!supports(target)) return error.UnsupportedTarget;

    const buffer_size = 1024;

    switch (target) {
        .linux_x86_32 => try out.print(
            \\global _start
            \\%define xr esi
            \\%define yr ebp
            \\%define bl edi ; bytes
            \\%define buf_size {d} ; dwords in buf
            \\section .bss
            \\  outs resb buf_size
            \\section .text
            \\flush:
            \\  mov eax, 4
            \\  mov ebx, 1
            \\  lea ecx, [outs]
            \\  mov edx, bl
            \\  int 0x80
            \\  mov bl, 0
            \\  ret
            \\print:
            \\  mov dword [ outs + bl ], xr
            \\  add bl, 4
            \\  cmp bl, buf_size*4
            \\  jl noflush
            \\  call flush
            \\noflush:
            \\  ret
            \\quit:
            \\  mov eax, 1
            \\  mov ebx, 0
            \\  int 0x80
            \\_start:
            \\
        , .{buffer_size}),
        .linux_x86_64 => try out.print(
            \\global _start
            \\%define xr r12
            \\%define yr r13
            \\%define bl r14 ; bytes
            \\%define buf_size {d} ; qwords in buf
            \\section .bss
            \\  outs resq buf_size
            \\section .text
            \\flush:
            \\  mov rax, 1
            \\  mov rdi, 1
            \\  lea rsi, [rel outs]
            \\  mov rdx, bl
            \\  syscall
            \\  mov bl, 0
            \\  ret
            \\print:
            \\  mov qword [ outs + bl ], xr
            \\  add bl, 8
            \\  cmp bl, buf_size*8
            \\  jl noflush
            \\  call flush
            \\noflush:
            \\  ret
            \\quit:
            \\  mov rax, 60
            \\  mov rdi, 0
            \\  syscall
            \\_start:
            \\
        , .{buffer_size}),
        .windows_x86_64 => try out.print(
            \\global mainCRTStartup
            \\extern GetStdHandle
            \\extern WriteFile
            \\extern ExitProcess
            \\%define xr r12
            \\%define yr r13
            \\%define bl r14d ; bytes
            \\%define tmp r15
            \\%define stdout rbp
            \\%define buf_size {d} ; qwords buf
            \\section .bss
            \\  outs resq buf_size
            \\section .text
            \\flush:
            \\  mov rcx, stdout
            \\  lea rdx, [ rel outs ]
            \\  mov r8d, bl
            \\  mov r9, 0
            \\  mov qword [rsp+32], 0
            \\  sub rsp, 40
            \\  call WriteFile
            \\  add rsp, 40
            \\  mov bl, 0
            \\  ret
            \\print:
            \\  lea tmp, [ rel outs ]
            \\  movzx rbx, bl
            \\  mov qword [ tmp + rbx ], xr
            \\  add bl, 8
            \\  cmp bl, buf_size*8
            \\  jl noflush
            \\  call flush
            \\noflush:
            \\  ret
            \\quit:
            \\  xor rcx, rcx
            \\  sub rsp, 40
            \\  call ExitProcess
            \\mainCRTStartup:
            \\  sub rsp, 40
            \\  mov rcx, -11
            \\  call GetStdHandle
            \\  add rsp, 40
            \\  mov stdout, rax
            \\
        , .{buffer_size}),

        else => return error.Unimplemented,
    }

    for (instructions, 0..) |ins, index| {
        try switch (ins) {
            .inc => |amount| out.print("  add xr, {d}\n", .{amount}),
            .dec => |amount| out.print("  sub xr, {d}\n", .{amount}),
            .swap => out.print("  xchg xr, yr\n", .{}),
            .zero => out.print("  mov xr, 0\n", .{}),
            .print => out.print("  call print\n", .{}),
            .open => |close| out.print(
                \\br{d}:
                \\  cmp xr, yr
                \\  je br{d}
                \\
            , .{ index, close }),
            .close => |open| out.print(
                \\br{d}:
                \\  cmp xr, yr
                \\  jne br{d}
                \\
            , .{ index, open }),
        };
    }

    try out.print(
        \\  call flush
        \\  jmp quit
        \\
    , .{});
}

const SupportedTargets = [_]Backend.Target{
    .linux_x86_64,
    .linux_x86_32,
    .windows_x86_64,
};

pub fn supported() []const Backend.Target {
    return &SupportedTargets;
}

pub fn supports(target: ?Backend.Target) bool {
    const t = target orelse return false;
    inline for (SupportedTargets) |s| {
        if (s == t) return true;
    }
    return false;
}
