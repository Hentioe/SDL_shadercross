const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const dxc = b.option(bool, "dxc", "Enable HLSL compilation via DXC") orelse true;

    // SDL_shadercross is consumed as a Zig module: the consumer compiles its C
    // source together with SDL, so no library artifact is produced here. The
    // third-party libraries can be supplied through the Zig build graph (for
    // example with
    // `dep.module("SDL_shadercross").linkLibrary(sdl.artifact("SDL3"))`).
    // Setting the corresponding option to false disables the system-library
    // fallback so that only the caller-provided libraries are used.
    const link_system_sdl = b.option(bool, "link_system_sdl", "Fall back to the system SDL3 library when SDL is not provided by the caller") orelse true;
    const link_system_spirv_cross = b.option(bool, "link_system_spirv_cross", "Fall back to the system SPIRV-Cross library when it is not provided by the caller") orelse true;
    const link_system_dxc = b.option(bool, "link_system_dxc", "Fall back to the system DXC library when it is not provided by the caller") orelse true;

    const mod = b.addModule("SDL_shadercross", .{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    mod.addIncludePath(b.path("include"));
    mod.addCSourceFile(.{
        .file = b.path("src/SDL_shadercross.c"),
        .flags = &.{"-std=gnu99"},
    });

    if (link_system_sdl) mod.linkSystemLibrary("sdl3", .{});
    if (link_system_spirv_cross) mod.linkSystemLibrary("spirv-cross-c-shared", .{});
    if (dxc) {
        mod.addCMacro("SDL_SHADERCROSS_DXC", "1");
        if (link_system_dxc) mod.linkSystemLibrary("dxcompiler", .{ .use_pkg_config = .no });
    }
}
