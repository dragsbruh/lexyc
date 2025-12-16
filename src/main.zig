const std = @import("std");

const Instruction = @import("Instruction.zig");
const Backend = @import("Backend.zig");

pub fn main() !u8 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    const args_alloc = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args_alloc);

    if (args_alloc.len > 1 and std.mem.eql(u8, args_alloc[1], "help")) {
        std.debug.print("{s}usage:{s} `lexyc <file> <backend> [out-file]`\n", .{ colors.white, colors.reset });
        std.debug.print("{s}available backends and their supported targets:{s}\n", .{ colors.white, colors.reset });

        const t = @typeInfo(Backend.Type);
        inline for (t.@"enum".fields) |f| {
            std.debug.print("  {s}\n", .{f.name});

            const backend_type: Backend.Type = @enumFromInt(f.value);
            const supported_targets = Backend.get(backend_type).supported();

            for (supported_targets) |target| std.debug.print("    {s}\n", .{@tagName(target)});
        }

        std.debug.print(
            \\{s}examples:{s}
            \\  lexyc file.xy nasm-linux_x86_64 -           # prints asm to stdout
            \\  lexyc file.xy nasm-linux_x86_32 file.s      # writes asm to file
            \\  lexyc file.xy interpreter -                 # interprets the code and prints to stdout
            \\  lexyc file.xy interpreter-debug debug.txt   # interprets the code and every step writes debug information to file
            \\  lexyc file.xy debug -                       # tokenizes the code and writes token debug information to stdout
            \\{s}notes:{s}
            \\  outfile is optional, it will default to stdout
            \\
        , .{ colors.white, colors.reset, colors.white, colors.reset });

        return 0;
    }

    if (args_alloc.len < 3) {
        std.debug.print("{s}usage:{s} `lexyc <file> <backend> [out-file]`\n", .{ colors.red, colors.reset });
        std.debug.print("see `lexyc help` for list of available targets\n", .{});
        return 1;
    }

    const file_path = args_alloc[1];
    const backend_str = args_alloc[2];
    const out_path = if (args_alloc.len > 3) args_alloc[3] else null;

    var iter = std.mem.splitScalar(u8, backend_str, '-');

    const first = iter.first();
    const backend_type = std.meta.stringToEnum(Backend.Type, first) orelse {
        std.debug.print("{s}error:{s} unknown backend `{s}`. see `lexyc help` for list of backends.\n", .{ colors.red, colors.reset, first });
        return 1;
    };

    const target = if (iter.next()) |t_str| std.meta.stringToEnum(Backend.Target, t_str) orelse {
        std.debug.print("{s}error:{s} unknown target `{s}`. see `lexyc help` for list of targets.\n", .{ colors.red, colors.reset, t_str });
        return 1;
    } else null;

    const source = std.fs.cwd().readFileAlloc(allocator, file_path, std.math.maxInt(usize)) catch |err| {
        std.debug.print("{s}error:{s} couldnt read file: {}\n", .{ colors.red, colors.reset, err });
        return 1;
    };
    defer allocator.free(source);

    const out_file = if (out_path) |path| if (std.mem.eql(u8, path, "-"))
        std.fs.File.stdout()
    else
        std.fs.cwd().createFile(path, .{}) catch |err| {
            std.debug.print("{s}error:{s} couldnt create out file: {}\n", .{ colors.red, colors.reset, err });
            return 1;
        } else std.fs.File.stdout();
    var writer = out_file.writer(&.{});

    defer writer.interface.flush() catch @panic("flush error");

    defer if (out_path) |_| out_file.close();

    const instructions = switch (try Instruction.eatAll(allocator, source)) {
        .err => |err| {
            const msg = switch (err.type) {
                .unmatched_close => "this closing bracket does not have a matching open bracket",
                .unmatched_open => "this opening bracket was not closed",
                .unknown_symbol => "unknown symbol",
            };
            std.debug.print("{s}error:{s} {s}\n", .{ colors.red, colors.reset, msg });
            prettyPrint(source, err.pos, msg, 3);
            return 1;
        },
        .ok => |instructions| instructions,
    };
    defer allocator.free(instructions);

    const backend = Backend.get(backend_type);
    if (!backend.supports(target)) {
        std.debug.print("{s}error:{s} target `{s}` is not supported by backend `{s}`\n", .{ colors.red, colors.reset, if (target) |t_str| @tagName(t_str) else "none", @tagName(backend_type) });
        return 1;
    }

    try backend.compile(allocator, &writer.interface, target, instructions);

    return 0;
}

fn prettyPrint(source: []const u8, pos: Instruction.Position, msg: []const u8, context: usize) void {
    var iter = std.mem.SplitIterator(u8, .scalar){
        .delimiter = '\n',
        .buffer = source,
        .index = 0,
    };

    var line_index: usize = 0;
    while (iter.next()) |line| {
        const start_line = if (pos.line > context) pos.line - context else 0;
        const end_line = pos.line + context;
        if (line_index <= end_line and line_index >= start_line) {
            std.debug.print("{s}{d}{s}: {s}\n", .{ colors.blue, line_index + 1, colors.reset, line });
            if (line_index == pos.line) {
                // round(log10(x) + 1) is a good approximation for finding number of digits, this is probably well established but im glad i found it out on my own
                // +2 to account for space and colon
                for (0..std.math.log10(line_index + 1) + pos.line_index + 3) |_| std.debug.print(" ", .{});
                for (0..pos.len) |_| std.debug.print("{s}^{s}", .{ colors.red, colors.reset });
                std.debug.print(" {s}{s}{s}\n", .{ colors.white, msg, colors.reset });
            }
        }
        line_index += 1;
    }
}

const colors = struct {
    pub const blue = "\x1b[94m";
    pub const red = "\x1b[91m";
    pub const white = "\x1b[1;97m";
    pub const reset = "\x1b[0m";
};
