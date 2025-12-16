const std = @import("std");

pub fn getExe(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) *std.Build.Step.Compile {
    return b.addExecutable(.{
        .name = "lexyc",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .root_source_file = b.path("src/main.zig"),
        }),
    });
}

pub fn crossCompile(b: *std.Build, optimize: std.builtin.OptimizeMode, targets: []const std.Target.Query, step: *std.Build.Step) !void {
    for (targets) |t| {
        const target_exe = getExe(b, b.resolveTargetQuery(t), optimize);

        const target_output = b.addInstallArtifact(target_exe, .{
            .dest_dir = .{
                .override = .{
                    .custom = try t.zigTriple(b.allocator),
                },
            },
        });

        step.dependOn(&target_output.step);
    }
}

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = getExe(b, target, optimize);
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    if (b.args) |args| run_cmd.addArgs(args);

    const run_step = b.step("run", "run lexyc");
    run_step.dependOn(&run_cmd.step);

    const cross_step = b.step("cross", "cross compile to multiple targets");
    try crossCompile(b, optimize, sane_targets, cross_step);

    const exotic_step = b.step("exotic", "cross compile to exotic targets");
    try crossCompile(b, optimize, exotic_targets, exotic_step);
}

const sane_targets: []const std.Target.Query = &.{
    .{ .cpu_arch = .aarch64, .os_tag = .macos },
    .{ .cpu_arch = .x86_64, .os_tag = .macos },

    .{ .cpu_arch = .x86, .os_tag = .freebsd },
    .{ .cpu_arch = .x86_64, .os_tag = .freebsd },
    .{ .cpu_arch = .aarch64, .os_tag = .freebsd },
    .{ .cpu_arch = .riscv64, .os_tag = .freebsd },

    .{ .cpu_arch = .arm, .os_tag = .linux },
    .{ .cpu_arch = .mips, .os_tag = .linux },
    .{ .cpu_arch = .mips64, .os_tag = .linux },
    .{ .cpu_arch = .x86, .os_tag = .linux },
    .{ .cpu_arch = .x86_64, .os_tag = .linux },
    .{ .cpu_arch = .aarch64, .os_tag = .linux },
    .{ .cpu_arch = .riscv64, .os_tag = .linux },
    .{ .cpu_arch = .riscv32, .os_tag = .linux },
    .{ .cpu_arch = .powerpc64, .os_tag = .linux },
    .{ .cpu_arch = .powerpc64le, .os_tag = .linux },
    .{ .cpu_arch = .loongarch64, .os_tag = .linux },
    .{ .cpu_arch = .s390x, .os_tag = .linux },
    .{ .cpu_arch = .sparc64, .os_tag = .linux },

    .{ .cpu_arch = .x86, .os_tag = .windows },
    .{ .cpu_arch = .x86_64, .os_tag = .windows },
    .{ .cpu_arch = .aarch64, .os_tag = .windows },

    .{ .cpu_arch = .arm, .os_tag = .freestanding },
    .{ .cpu_arch = .x86, .os_tag = .freestanding },
    .{ .cpu_arch = .x86_64, .os_tag = .freestanding },
    .{ .cpu_arch = .aarch64, .os_tag = .freestanding },
    .{ .cpu_arch = .riscv32, .os_tag = .freestanding }, // thank you i will take my nobel price
    .{ .cpu_arch = .riscv64, .os_tag = .freestanding },
    .{ .cpu_arch = .hexagon, .os_tag = .freestanding },
};

const exotic_targets: []const std.Target.Query = &.{
    .{ .cpu_arch = .aarch64, .os_tag = .macos },
    .{ .cpu_arch = .x86_64, .os_tag = .macos },

    .{ .cpu_arch = .x86, .os_tag = .windows },
    .{ .cpu_arch = .x86_64, .os_tag = .windows },
    .{ .cpu_arch = .aarch64, .os_tag = .windows },
    .{ .cpu_arch = .thumb, .os_tag = .windows },

    .{ .cpu_arch = .x86, .os_tag = .freebsd },
    .{ .cpu_arch = .x86_64, .os_tag = .freebsd },
    .{ .cpu_arch = .aarch64, .os_tag = .freebsd },
    .{ .cpu_arch = .arm, .os_tag = .freebsd },
    .{ .cpu_arch = .powerpc, .os_tag = .freebsd },
    .{ .cpu_arch = .powerpc64, .os_tag = .freebsd },
    .{ .cpu_arch = .powerpc64le, .os_tag = .freebsd },
    .{ .cpu_arch = .riscv64, .os_tag = .freebsd },

    .{ .cpu_arch = .x86, .os_tag = .netbsd },
    .{ .cpu_arch = .x86_64, .os_tag = .netbsd },
    .{ .cpu_arch = .aarch64, .os_tag = .netbsd },
    .{ .cpu_arch = .arm, .os_tag = .netbsd },
    .{ .cpu_arch = .armeb, .os_tag = .netbsd },
    .{ .cpu_arch = .mips, .os_tag = .netbsd },
    .{ .cpu_arch = .mipsel, .os_tag = .netbsd },
    .{ .cpu_arch = .powerpc, .os_tag = .netbsd },

    .{ .cpu_arch = .x86, .os_tag = .linux },
    .{ .cpu_arch = .x86_64, .os_tag = .linux },
    .{ .cpu_arch = .aarch64, .os_tag = .linux },
    .{ .cpu_arch = .aarch64_be, .os_tag = .linux },
    .{ .cpu_arch = .arm, .os_tag = .linux },
    .{ .cpu_arch = .armeb, .os_tag = .linux },
    .{ .cpu_arch = .thumb, .os_tag = .linux },
    .{ .cpu_arch = .thumbeb, .os_tag = .linux },
    .{ .cpu_arch = .mips, .os_tag = .linux },
    .{ .cpu_arch = .mipsel, .os_tag = .linux },
    .{ .cpu_arch = .mips64, .os_tag = .linux },
    .{ .cpu_arch = .mips64el, .os_tag = .linux },
    .{ .cpu_arch = .loongarch64, .os_tag = .linux },
    .{ .cpu_arch = .powerpc, .os_tag = .linux },
    .{ .cpu_arch = .powerpc64, .os_tag = .linux },
    .{ .cpu_arch = .powerpc64le, .os_tag = .linux },
    .{ .cpu_arch = .powerpcle, .os_tag = .linux },
    .{ .cpu_arch = .riscv32, .os_tag = .linux },
    .{ .cpu_arch = .riscv64, .os_tag = .linux },
    .{ .cpu_arch = .s390x, .os_tag = .linux },
    .{ .cpu_arch = .sparc64, .os_tag = .linux },
    .{ .cpu_arch = .hexagon, .os_tag = .linux },

    .{ .cpu_arch = .x86, .os_tag = .freestanding },
    .{ .cpu_arch = .x86_64, .os_tag = .freestanding },
    .{ .cpu_arch = .aarch64, .os_tag = .freestanding },
    .{ .cpu_arch = .aarch64_be, .os_tag = .freestanding },
    .{ .cpu_arch = .arm, .os_tag = .freestanding },
    .{ .cpu_arch = .armeb, .os_tag = .freestanding },
    .{ .cpu_arch = .thumb, .os_tag = .freestanding },
    .{ .cpu_arch = .thumbeb, .os_tag = .freestanding },
    .{ .cpu_arch = .mips, .os_tag = .freestanding },
    .{ .cpu_arch = .mipsel, .os_tag = .freestanding },
    .{ .cpu_arch = .mips64, .os_tag = .freestanding },
    .{ .cpu_arch = .mips64el, .os_tag = .freestanding },
    .{ .cpu_arch = .loongarch64, .os_tag = .freestanding },
    .{ .cpu_arch = .powerpc, .os_tag = .freestanding },
    .{ .cpu_arch = .powerpc64, .os_tag = .freestanding },
    .{ .cpu_arch = .powerpc64le, .os_tag = .freestanding },
    .{ .cpu_arch = .powerpcle, .os_tag = .freestanding },
    .{ .cpu_arch = .riscv32, .os_tag = .freestanding },
    .{ .cpu_arch = .riscv64, .os_tag = .freestanding },
    .{ .cpu_arch = .s390x, .os_tag = .freestanding },
    .{ .cpu_arch = .sparc64, .os_tag = .freestanding },
    .{ .cpu_arch = .hexagon, .os_tag = .freestanding },

    .{ .cpu_arch = .wasm32, .os_tag = .wasi },
    .{ .cpu_arch = .wasm64, .os_tag = .wasi },

    .{ .cpu_arch = .x86, .os_tag = .other },
    .{ .cpu_arch = .x86_64, .os_tag = .other },
    .{ .cpu_arch = .aarch64, .os_tag = .other },
    .{ .cpu_arch = .aarch64_be, .os_tag = .other },
    .{ .cpu_arch = .arm, .os_tag = .other },
    .{ .cpu_arch = .armeb, .os_tag = .other },
    .{ .cpu_arch = .thumb, .os_tag = .other },
    .{ .cpu_arch = .thumbeb, .os_tag = .other },
    .{ .cpu_arch = .mips, .os_tag = .other },
    .{ .cpu_arch = .mipsel, .os_tag = .other },
    .{ .cpu_arch = .mips64, .os_tag = .other },
    .{ .cpu_arch = .mips64el, .os_tag = .other },
    .{ .cpu_arch = .loongarch64, .os_tag = .other },
    .{ .cpu_arch = .powerpc, .os_tag = .other },
    .{ .cpu_arch = .powerpc64, .os_tag = .other },
    .{ .cpu_arch = .powerpc64le, .os_tag = .other },
    .{ .cpu_arch = .powerpcle, .os_tag = .other },
    .{ .cpu_arch = .riscv32, .os_tag = .other },
    .{ .cpu_arch = .riscv64, .os_tag = .other },
    .{ .cpu_arch = .s390x, .os_tag = .other },
    .{ .cpu_arch = .sparc64, .os_tag = .other },
    .{ .cpu_arch = .hexagon, .os_tag = .other },
};
