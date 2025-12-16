const std = @import("std");
const Instruction = @import("../Instruction.zig");

const Backend = @import("../Backend.zig");

pub fn getGlue(target: Backend.Target) struct { []const u8, []const u8 } {
    inline for (supportedTargets) |t| {
        if (t == target) return comptime blk: {
            const path = std.fmt.comptimePrint("../abi/nasm/{s}.s", .{@tagName(t)});
            var iter = std.mem.splitSequence(u8, @embedFile(path), ";stub");

            const prologue = iter.first();
            const epilogue = iter.next() orelse @compileError(std.fmt.comptimePrint("missing `;stub` marker in {s}", .{path}));
            if (iter.next()) |_| @compileError(std.fmt.comptimePrint("duplicate `;stub` marker in {s}", .{path}));

            break :blk .{ prologue, epilogue };
        };
    }
    unreachable;
}

pub fn compile(_: std.mem.Allocator, out: *std.Io.Writer, maybe_target: ?Backend.Target, instructions: []Instruction) !void {
    const target = maybe_target orelse return error.RequiresTarget;
    if (!supports(target)) return error.UnsupportedTarget;

    const glue = getGlue(target);

    try out.writeAll(glue.@"0");

    for (instructions, 0..) |instruction, index| {
        try switch (instruction.type) {
            .inc => |amount| out.print("  add xr, {d}\n", .{amount}),
            .dec => |amount| out.print("  sub xr, {d}\n", .{amount}),
            .swap => out.print("  xchg xr, yr\n", .{}),
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

    try out.writeAll(glue.@"1");
}

const supportedTargets = [_]Backend.Target{
    .linux_x86_64,
    .linux_x86_32,
    .windows_x86_64,
};

pub fn supported() []const Backend.Target {
    return &supportedTargets;
}

pub fn supports(target: ?Backend.Target) bool {
    const t = target orelse return false;
    inline for (supportedTargets) |s| {
        if (s == t) return true;
    }
    return false;
}
