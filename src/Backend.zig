const std = @import("std");

const Backend = @This();

pub const backends = struct {
    const nasm_b = @import("backends/nasm.zig");

    const nasm = Backend{
        .compile = nasm_b.compile,
        .supported = nasm_b.supported,
        .supports = nasm_b.supports,
    };

    const interpreter_b = @import("backends/interpreter.zig");

    const interpreter = Backend{
        .compile = interpreter_b.compile,
        .supported = interpreter_b.supported,
        .supports = interpreter_b.supports,
    };

    const debug_b = @import("backends/debug.zig");

    const debug = Backend{
        .compile = debug_b.compile,
        .supported = debug_b.supported,
        .supports = debug_b.supports,
    };
};

pub const Ins = @import("instructions.zig").Ins;

pub const Target = enum {
    linux_x86_64,
    linux_x86_32,
    windows_x86_64,
    windows_x86_32,
    debug, // debug is a special target, i only plan to use it with interpreter-debug to get detailed information per-step
};
pub const Type = enum { nasm, interpreter, debug };

compile: *const fn (allocator: std.mem.Allocator, writer: *std.Io.Writer, target: ?Target, instructions: []Ins) anyerror!void,
supports: *const fn (target: ?Target) bool,
supported: *const fn () []const Target,

/// except interpretr
pub fn get(backend: Type) @This() {
    return switch (backend) {
        .nasm => backends.nasm,
        .debug => backends.debug,
        .interpreter => backends.interpreter,
    };
}
