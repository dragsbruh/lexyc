const std = @import("std");

const Ins = @import("../instructions.zig").Ins;
const Backend = @import("../Backend.zig");

index: usize,
instructions: []const Ins,

x: usize,
y: usize,

write_debug: bool,

pub fn new(instructions: []const Ins) @This() {
    return .{
        .index = 0,
        .instructions = instructions,
        .x = 0,
        .y = 0,
        .write_debug = false,
    };
}

pub fn debug(self: @This(), out: *std.Io.Writer) !void {
    try out.print("\tdbg: x=`{d}`,y=`{d}`\n", .{ self.x, self.y });
}

pub fn step(self: *@This(), out: *std.Io.Writer) !bool {
    const current = self.instructions[self.index];

    if (self.write_debug) {
        try current.debug(out, self.index);
        try self.debug(out);
    }

    switch (current) {
        .inc => |amount| self.x += amount,
        .dec => |amount| self.x -= amount,
        .swap => {
            const tmp = self.x;
            self.x = self.y;
            self.y = tmp;
        },
        .open => |match| {
            if (self.x == self.y) self.index = match;
        },
        .close => |match| {
            if (self.x != self.y) self.index = match;
        },
        .print => {
            if (!self.write_debug) try out.writeInt(@TypeOf(self.x), self.x, .little);
        },
        .zero => self.x = 0,
    }

    self.index += 1;

    return self.index < self.instructions.len;
}

pub fn complete(self: *@This(), out: *std.Io.Writer) !void {
    while (try self.step(out)) {}

    if (self.write_debug) try self.debug(out);
}

pub fn compile(_: std.mem.Allocator, out: *std.Io.Writer, maybe_target: ?Backend.Target, instructions: []Ins) !void {
    const is_debug = if (maybe_target) |target| blk: {
        if (target != .debug) return error.UnsupportedTarget;
        break :blk true;
    } else false;

    var interpreter = new(instructions);
    interpreter.write_debug = is_debug;
    try interpreter.complete(out);
}

pub fn supports(target: ?Backend.Target) bool {
    return if (target) |t| t == .debug else true;
}

pub fn supported() []const Backend.Target {
    return &.{.debug};
}
