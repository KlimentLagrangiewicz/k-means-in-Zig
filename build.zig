const std = @import("std");

pub fn build(b: *std.Build) void {
    const exe: *std.Build.Step.Compile = b.addExecutable(.{
        .name = "kmeans",
        .root_source_file = .{ .cwd_relative = "src/main.zig" },
        .target = b.standardTargetOptions(.{}),
        .optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = std.builtin.OptimizeMode.ReleaseSafe }),
        .link_libc = true,
    });

    b.installArtifact(exe);

    const run_cmd: *std.Build.Step.Run = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step: *std.Build.Step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
