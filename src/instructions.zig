const std = @import("std");

pub const Ins = union(enum) {
    inc: usize, // number of times to do this operation
    dec: usize, // same
    swap,
    open: usize, // index of matching close
    close: usize, // index of matching open
    print,
    zero,

    pub fn debug(self: @This(), writer: *std.Io.Writer, index: usize) !void {
        switch (self) {
            .open, .close => |matching_index| try writer.print("{d}: {s} -> {d}\n", .{ index, @tagName(self), matching_index }),
            .inc, .dec => |amount| try writer.print("{d}: {s} * {d}\n", .{ index, @tagName(self), amount }),
            else => try writer.print("{d}: {s}\n", .{ index, @tagName(self) }),
        }
    }
};

pub const TokenizeResult = union(enum) {
    const TokenErr = struct {
        pub const Type = enum { unmatched_close, unmatched_open, unknown_token };

        type: Type,
        index: usize,
    };

    const ResultOK = struct {
        close_ins_index: ?usize,
        close_source_index: ?usize,
        instructions: []Ins,
    };

    Error: TokenErr,
    Result: ResultOK,
};

pub fn tokenize(allocator: std.mem.Allocator, source: []const u8, open_index: ?usize) !TokenizeResult {
    var instructions = std.ArrayList(Ins).empty;
    defer instructions.deinit(allocator);

    var index: usize = open_index orelse 0;

    while (index < source.len) {
        defer index += 1;
        const current = source[index];

        switch (current) {
            ' ', '\t', '\n' => {},

            '+', '-' => {
                const kind = switch (current) {
                    '+' => Ins{ .inc = 1 },
                    '-' => Ins{ .dec = 1 },
                    else => unreachable,
                };

                if (instructions.items.len > 0) {
                    var last = &instructions.items[instructions.items.len - 1];

                    if (std.meta.activeTag(last.*) == std.meta.activeTag(kind)) {
                        switch (last.*) {
                            .inc => last.inc += 1,
                            .dec => last.dec += 1,
                            else => unreachable,
                        }

                        continue;
                    }
                }

                try instructions.append(allocator, kind);
            },

            's' => try instructions.append(allocator, .swap),
            'o' => try instructions.append(allocator, .print),
            '0' => try instructions.append(allocator, .zero),

            '[' => {
                const result = try tokenize(allocator, source, index + 1);
                const ok = switch (result) {
                    .Error => return result,
                    .Result => |ins| ins,
                };
                defer allocator.free(ok.instructions);

                try instructions.append(allocator, Ins{ .open = (ok.close_ins_index orelse unreachable) + index + 1 });

                index = ok.close_source_index orelse unreachable;

                const new = try instructions.addManyAsSlice(allocator, ok.instructions.len);
                @memcpy(new, ok.instructions);

                continue;
            },

            ']' => {
                if (open_index) |oi| {
                    try instructions.append(allocator, Ins{ .close = oi - 1 });
                    return .{ .Result = .{
                        .close_ins_index = instructions.items.len - 1,
                        .close_source_index = index + 1,
                        .instructions = try instructions.toOwnedSlice(allocator),
                    } };
                } else {
                    return .{ .Error = .{ .index = index, .type = .unmatched_close } };
                }
            },

            else => return .{ .Error = .{ .index = index, .type = .unknown_token } },
        }
    }

    if (open_index) |_| return .{ .Error = .{ .index = index, .type = .unmatched_open } };

    return .{ .Result = .{
        .close_ins_index = null,
        .close_source_index = null,
        .instructions = try instructions.toOwnedSlice(allocator),
    } };
}
