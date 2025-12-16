const std = @import("std");

const Instruction = @This();

type: Type,
pos: Position,

pub const Position = struct {
    index: usize = 0,
    len: usize = 1,
    line: usize = 0,
    line_index: usize = 0,
};

pub const Type = union(enum) {
    inc: usize, // number of times to do this operation
    dec: usize, // same
    open: usize, // index of matching close
    close: usize, // index of matching open
    swap,
    print,
};

pub const EatResult = union(enum) {
    pub const SyntaxError = struct {
        pub const ErrType = enum { unmatched_open, unmatched_close, unknown_symbol };

        type: ErrType,
        pos: Instruction.Position,
    };

    pub const Singular = struct {
        /// if token is null, and repeat is true, repeat previous instruction
        /// else if token is null, call again
        instruction: ?Instruction = null,
        repeat: bool = false,
    };

    ok: []Instruction,
    err: SyntaxError,
};

pub fn debug(self: @This(), writer: *std.Io.Writer, index: usize) !void {
    switch (self.type) {
        .open, .close => |matching_index| try writer.print("{d}: {s} -> {d}\n", .{ index, @tagName(self.type), matching_index }),
        .inc, .dec => |amount| try writer.print("{d}: {s} * {d}\n", .{ index, @tagName(self.type), amount }),
        else => try writer.print("{d}: {s}\n", .{ index, @tagName(self.type) }),
    }
}

pub fn eatAll(allocator: std.mem.Allocator, source: []const u8) !EatResult {
    var instructions = std.ArrayList(Instruction).empty;
    var brackets = std.ArrayList(usize).empty;

    defer {
        instructions.deinit(allocator);
        brackets.deinit(allocator);
    }

    var pos = Instruction.Position{};
    var ins_index: usize = 0;

    while (true) {
        const current = if (pos.index >= source.len) break else source[pos.index];
        const prev = if (ins_index > 0) instructions.items[ins_index - 1].type else null;

        defer {
            switch (current) {
                '\n' => {
                    pos.line += 1;
                    pos.line_index = 0;
                },
                '\r' => {},
                else => {
                    pos.line_index += 1;
                },
            }
            pos.index += 1;
        }

        const result: EatResult.Singular = switch (current) {
            ' ', '\t', '\r', '\n' => continue,
            '+' => switch (prev orelse .swap) {
                .inc => .{ .repeat = true },
                else => .{ .instruction = .{
                    .type = .{ .inc = 1 },
                    .pos = pos,
                } },
            },
            '-' => switch (prev orelse .swap) {
                .dec => .{ .repeat = true },
                else => .{ .instruction = .{
                    .type = .{ .dec = 1 },
                    .pos = pos,
                } },
            },
            's' => .{ .instruction = .{
                .type = .swap,
                .pos = pos,
            } },
            'o' => .{ .instruction = .{
                .type = .print,
                .pos = pos,
            } },
            '[' => blk: {
                try brackets.append(allocator, ins_index);
                break :blk .{
                    .instruction = .{
                        .type = .{ .open = 0 }, // FIXME
                        .pos = pos,
                    },
                };
            },
            ']' => blk: {
                const open = brackets.pop() orelse return EatResult{ .err = .{ .type = .unmatched_close, .pos = pos } };
                instructions.items[open].type.open = ins_index;
                break :blk .{
                    .instruction = .{
                        .type = .{ .close = open }, // FIXME
                        .pos = pos,
                    },
                };
            },
            else => return EatResult{ .err = .{ .type = .unknown_symbol, .pos = pos } },
        };

        if (result.repeat) {
            var last = &instructions.items[instructions.items.len - 1];
            last.pos.len += 1;
            switch (last.type) {
                .inc => last.type.inc += 1,
                .dec => last.type.dec += 1,
                else => unreachable,
            }
        } else if (result.instruction) |instruction| {
            try instructions.append(allocator, instruction);
            ins_index += 1;
        }
    }

    if (brackets.items.len != 0) return EatResult{ .err = .{
        .type = .unmatched_open,
        .pos = instructions.items[brackets.items[brackets.items.len - 1]].pos,
    } };

    return .{ .ok = try instructions.toOwnedSlice(allocator) };
}
