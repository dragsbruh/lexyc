const std = @import("std");

const tokenize = @import("instructions.zig").tokenize;
const Backend = @import("Backend.zig");

pub fn main() !u8 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    const args_alloc = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args_alloc);

    if (args_alloc.len > 1 and std.mem.eql(u8, args_alloc[1], "help")) {
        std.debug.print("usage: `lexyc <file> <backend> [out-file]`\n", .{});
        std.debug.print("available backends and their supported targets:\n", .{});

        const t = @typeInfo(Backend.Type);
        inline for (t.@"enum".fields) |f| {
            std.debug.print("  {s}\n", .{f.name});

            const backend_type: Backend.Type = @enumFromInt(f.value);
            const supported_targets = if (backend_type == .interpreter) .{} else Backend.get(backend_type).supported();

            for (supported_targets) |target| std.debug.print("    {s}\n", .{@tagName(target)});
        }

        return 0;
    }

    if (args_alloc.len < 3) {
        std.debug.print("usage: `lexyc <file> <backend> [out-file]`\n", .{});
        std.debug.print("see `lexyc help` for list of available targets\n", .{});
        return 1;
    }

    const file_path = args_alloc[1];
    const backend_str = args_alloc[2];
    const out_path = if (args_alloc.len > 3) args_alloc[3] else null;

    var iter = std.mem.splitScalar(u8, backend_str, '-');

    const first = iter.first();
    const backend_type = std.meta.stringToEnum(Backend.Type, first) orelse {
        std.debug.print("error: unknown backend `{s}`. see `lexyc help` for list of backends.\n", .{first});
        return 1;
    };

    const target = if (iter.next()) |t_str| std.meta.stringToEnum(Backend.Target, t_str) orelse {
        std.debug.print("error: unknown target `{s}`. see `lexyc help` for list of targets.\n", .{t_str});
        return 1;
    } else null;

    const source = std.fs.cwd().readFileAlloc(allocator, file_path, std.math.maxInt(usize)) catch |err| {
        std.debug.print("error: couldnt read file: {}\n", .{err});
        return 1;
    };
    defer allocator.free(source);

    const out_file = if (out_path) |path| if (std.mem.eql(u8, path, "-"))
        std.fs.File.stdout()
    else
        std.fs.cwd().createFile(path, .{}) catch |err| {
            std.debug.print("error: couldnt create out file: {}\n", .{err});
            return 1;
        } else std.fs.File.stdout();
    var writer = out_file.writer(&.{});

    defer writer.interface.flush() catch @panic("flush error");

    defer if (out_path) |_| out_file.close();

    const instructions = switch (try tokenize(allocator, source, null)) {
        .Error => |err| {
            std.debug.print("error in code: {s} at position {d}\n", .{ @tagName(err.type), err.index });
            return 1;
        },
        .Result => |res| res.instructions,
    };
    defer allocator.free(instructions);

    const backend = Backend.get(backend_type);
    if (!backend.supports(target)) {
        std.debug.print("error: target `{s}` is not supported by backend `{s}`\n", .{ if (target) |t_str| @tagName(t_str) else "none", @tagName(backend_type) });
        return 1;
    }

    try backend.compile(allocator, &writer.interface, target, instructions);

    return 0;
}
