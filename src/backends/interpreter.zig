const std = @import("std");

const Ins = @import("../instructions.zig").Ins;
const Backend = @import("../Backend.zig");

index: usize,
instructions: []const Ins,

x: usize,
y: usize,

pub fn new(instructions: []const Ins) @This() {
    return .{
        .index = 0,
        .instructions = instructions,
        .x = 0,
        .y = 0,
    };
}

pub fn step(self: *@This(), out: *std.Io.Writer) !bool {
    const current = self.instructions[self.index];

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
            try out.writeInt(@TypeOf(self.x), self.x, .little);
        },
        .zero => self.x = 0,
    }

    self.index += 1;

    return self.index < self.instructions.len;
}

pub fn complete(self: *@This(), out: *std.Io.Writer) !void {
    while (try self.step(out)) {}
}

pub fn compile(_: std.mem.Allocator, out: *std.Io.Writer, maybe_target: ?Backend.Target, instructions: []Ins) !void {
    if (maybe_target) |_| return error.UnsupportedTarget;

    var interpreter = new(instructions);
    try interpreter.complete(out);
}

pub fn supports(target: ?Backend.Target) bool {
    return target == null;
}

pub fn supported() []const Backend.Target {
    return &.{};
}
