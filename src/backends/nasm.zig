const std = @import("std");
const Ins = @import("../instructions.zig").Ins;

const Backend = @import("../Backend.zig");

pub fn supported() []const Backend.Target {
    return &[_]Backend.Target{ .linux_x86_64, .linux_x86_32 };
}

pub fn compile(_: std.mem.Allocator, out: *std.Io.Writer, maybe_target: ?Backend.Target, instructions: []Ins) !void {
    const target = maybe_target orelse return error.RequiresTarget;

    switch (target) {
        .linux_x86_32 => try out.print(
            \\global _start
            // we arent using esi or ebp so good
            \\%define xr esi
            \\%define yr ebp
            \\%define bl edi
            \\%define buf_size 1024
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
            \\  cmp bl, buf_size
            \\  jng noflush
            \\  call flush
            \\  ret
            \\noflush:
            \\  mov dword [ outs + bl ], xr
            \\  add bl, 4
            \\  ret
            \\quit:
            \\  mov eax, 1
            \\  mov ebx, 0
            \\  int 0x80
            \\_start:
            \\
        , .{}),
        .linux_x86_64 => try out.print(
            \\global _start
            \\%define xr r12
            \\%define yr r13
            \\%define bl r14
            \\%define buf_size 1024
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
            \\  cmp bl, buf_size
            \\  jng noflush
            \\  call flush
            \\  ret
            \\noflush:
            \\  mov qword [ outs + bl ], xr
            \\  add bl, 8
            \\  ret
            \\quit:
            \\  mov rax, 60
            \\  mov rdi, 0
            \\  syscall
            \\_start:
            \\
        , .{}),
        else => return error.UnsupportedTarget,
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

pub fn supports(target: ?Backend.Target) bool {
    return target != null;
}
