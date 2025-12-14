const std = @import("std");

const Backend = @import("../Backend.zig");
const Ins = @import("../instructions.zig").Ins;

pub fn compile(_: std.mem.Allocator, out: *std.Io.Writer, maybe_target: ?Backend.Target, instructions: []Ins) !void {
    if (maybe_target) |_| return error.UnsupportedTarget;

    for (instructions, 0..) |ins, i| try ins.debug(out, i);
}

pub fn supports(target: ?Backend.Target) bool {
    return target == null;
}

pub fn supported() []const Backend.Target {
    return &.{};
}
