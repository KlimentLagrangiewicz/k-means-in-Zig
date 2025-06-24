const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = .ReleaseFast;

    const kmeans_module = b.addModule("k-means", .{
        .root_source_file = .{ .cwd_relative = "src/k-means.zig" },
        .optimize = optimize,
        .target = target,
        .link_libc = true,
    });

    const help_module = b.addModule("help", .{
        .root_source_file = .{ .cwd_relative = "src/help.zig" },
        .optimize = optimize,
        .target = target,
        .link_libc = true,
    });

    const main_module = b.addModule("main", .{
        .root_source_file = .{ .cwd_relative = "src/main.zig" },
        .optimize = optimize,
        .target = target,
        .link_libc = true,
        .imports = &.{
            .{ .name = "help", .module = help_module },
            .{ .name = "k-means", .module = kmeans_module },
        },
    });

    const exe: *std.Build.Step.Compile = b.addExecutable(.{
        .name = "kmeans",
        .root_module = main_module,
    });
    b.installArtifact(exe);

    const run_cmd: *std.Build.Step.Run = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step: *std.Build.Step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const kmeans_module_tests = b.addTest(.{
        .target = target,
        .optimize = optimize,
        .root_module = b.createModule(.{
            .root_source_file = .{ .cwd_relative = "tests/tests_kmeans.zig" },
            .optimize = optimize,
            .target = target,
            .link_libc = true,
            .imports = &.{
                .{ .name = "k-means", .module = kmeans_module },
            },
        }),
    });

    const help_module_tests = b.addTest(.{
        .target = target,
        .optimize = optimize,
        .root_module = b.createModule(.{
            .root_source_file = .{ .cwd_relative = "tests/tests_help.zig" },
            .optimize = optimize,
            .target = target,
            .link_libc = true,
            .imports = &.{
                .{ .name = "help", .module = help_module },
            },
        }),
    });

    const kmeans_private_tests = b.addTest(.{
        .target = target,
        .optimize = optimize,
        .root_module = kmeans_module,
    });

    const test_step = b.step("test", "Run all unit tests");
    test_step.dependOn(&b.addRunArtifact(kmeans_module_tests).step);
    test_step.dependOn(&b.addRunArtifact(help_module_tests).step);
    test_step.dependOn(&b.addRunArtifact(kmeans_private_tests).step);
}
