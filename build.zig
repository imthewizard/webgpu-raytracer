const std = @import("std");
const builtin = @import("builtin");
// const Optimize = std.lang.Optimize;

pub fn build(b: *std.Build) void {
    // const target = b.standardTargetOptions(.{});
    const target = b.resolveTargetQuery(.{ .cpu_arch = .wasm32, .os_tag = .emscripten });
    const optimize = b.standardOptimizeOption(.{});

    const emscripten_sysroot_dir = b.option([]const u8, "emsysroot", "Path to the emscripten sysroot directory") orelse {
        std.log.err("Must provide emscripten sysroot folder (ex: -Demsysroot ../emsdk/upstream/emscripten/cache/sysroot )", .{});
        return;
    };
    // if (b.args == null) {
    //     std.log.err("Must provide emscripten sysroot folder (ex: --sysroot ../emsdk/upstream/emscripten/cache/sysroot )", .{});
    //     return;
    // }
    //
    // const emscripten_sysroot_dir = b.sysroot.?;


    const emscripten_dir = b.pathJoin(&.{ emscripten_sysroot_dir, "..", ".." });
    const emscripten_sysroot_include = b.pathJoin(&.{ emscripten_sysroot_dir, "include" });
    const emscripten_emdawnwebgpu_include = b.pathJoin(&.{ emscripten_dir, "cache", "ports", "emdawnwebgpu", "emdawnwebgpu_pkg", "webgpu", "include" });

    const mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    mod.addSystemIncludePath(.{ .cwd_relative = emscripten_sysroot_include });
    mod.addSystemIncludePath(.{ .cwd_relative = emscripten_emdawnwebgpu_include });

    const lib = b.addLibrary(.{
        .name = "webgpu_raytracer",
        .root_module = mod,
        .linkage = .static,
    });

    const wf = b.addWriteFiles();
    wf.step.dependOn(&lib.step);

    const emcc = b.addSystemCommand(&.{b.pathJoin(&.{ emscripten_dir, "emcc" })});
    emcc.addFileArg(lib.getEmittedBin());
    emcc.addArgs(&.{
        getOptimizationFlag(),
        "-sASYNCIFY",
        getAssertionFlag(),
        "--use-port=emdawnwebgpu",
    });
    emcc.addArg("-o");
    emcc.addFileArg(wf.getDirectory().path(b, b.fmt("{s}.html", .{lib.name})));
    emcc.step.dependOn(&wf.step);

    const install_dir = b.addInstallDirectory(.{
        .source_dir = wf.getDirectory(),
        .install_dir = .bin,
        .install_subdir = "",
    });
    install_dir.step.dependOn(&emcc.step);
    b.getInstallStep().dependOn(&install_dir.step);
}

fn getOptimizationFlag() []const u8 {
    if (builtin.mode == .small) {
        return "-Oz";
    } else if (builtin.mode == .safe) {
        return "-O2";
    } else if (builtin.mode == .fast) {
        return "-O3";
    }
    return "-O0";
}

fn getAssertionFlag() []const u8 {
    if (builtin.mode == .debug) {
        return "-sASSERTIONS=2";
    }
    return ""; // default
}
