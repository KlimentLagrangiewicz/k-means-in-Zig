const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = .ReleaseSafe });

    const kmeansMod = b.addModule("k-means", .{
        .root_source_file = .{ .cwd_relative = "src/k-means.zig" },
        .optimize = optimize,
        .target = target,
        .link_libc = true,
    });

    const helpMod = b.addModule("help", .{
        .root_source_file = .{ .cwd_relative = "src/help.zig" },
        .optimize = optimize,
        .target = target,
        .link_libc = true,
    });

    const mainMod = b.addModule("main", .{
        .root_source_file = .{ .cwd_relative = "src/main.zig" },
        .optimize = optimize,
        .target = target,
        .link_libc = true,
        .imports = &.{
            .{ .name = "help", .module = helpMod },
            .{ .name = "k-means", .module = kmeansMod },
        },
    });

    const exe: *std.Build.Step.Compile = b.addExecutable(.{
        .name = "kmeans",
        .root_module = mainMod,
    });
    b.installArtifact(exe);

    const run_cmd: *std.Build.Step.Run = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step: *std.Build.Step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const kmeansModTests = b.addTest(.{
        .target = target,
        .optimize = optimize,
        .root_module = b.createModule(.{
            .root_source_file = .{ .cwd_relative = "tests/tests_kmeans.zig" },
            .optimize = optimize,
            .target = target,
            .link_libc = true,
            .imports = &.{
                .{ .name = "k-means", .module = kmeansMod },
            },
        }),
    });

    const helpModTests = b.addTest(.{
        .target = target,
        .optimize = optimize,
        .root_module = b.createModule(.{
            .root_source_file = .{ .cwd_relative = "tests/tests_help.zig" },
            .optimize = optimize,
            .target = target,
            .link_libc = true,
            .imports = &.{
                .{ .name = "help", .module = helpMod },
            },
        }),
    });

    const kmeansPrivateTests = b.addTest(.{
        .target = target,
        .optimize = optimize,
        .root_module = kmeansMod,
    });

    const test_step = b.step("test", "Run all unit tests");
    test_step.dependOn(&b.addRunArtifact(kmeansModTests).step);
    test_step.dependOn(&b.addRunArtifact(helpModTests).step);
    test_step.dependOn(&b.addRunArtifact(kmeansPrivateTests).step);
}