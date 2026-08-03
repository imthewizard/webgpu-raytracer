const std = @import("std");

pub fn build(b: *std.Build) void {
    const wasm_target = b.resolveTargetQuery(.{ .cpu_arch = .wasm32, .os_tag = .freestanding });
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = wasm_target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "webgpu_raytracer",
        .root_module = mod,
    });
    exe.rdynamic = true;
    exe.entry = .disabled;

    b.installArtifact(exe);
}
