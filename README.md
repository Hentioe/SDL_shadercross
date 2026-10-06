# SDL_shadercross (Zig port)

> [!WARNING]
> This port currently supports Zig **0.15.2** at most. Newer Zig versions are not supported.

`SDL_shadercross` translates shaders for use with SDL's GPU API. It takes SPIRV
or HLSL as input and produces DXBC, DXIL, SPIRV, MSL, or HLSL, and can return
compiled SDL GPU shader objects at runtime.

This repository is a Zig build of the library. It does **not** produce a
standalone `libSDL_shadercross`. Instead it exposes one Zig module,
`SDL_shadercross`, that you compile together with your own code (and, if you
want, together with SDL itself). Because everything is built in a single Zig
graph, there is no prebuilt static/shared library and no static-vs-shared
dependency mismatch.

## Add the dependency

From your project root:

```sh
zig fetch --save=SDL_shadercross git+https://github.com/Hentioe/SDL_shadercross
```

This writes the dependency and its hash into `build.zig.zon`.

## Use it

In `build.zig`:

```zig
const sdl_shadercross_dep = b.dependency("SDL_shadercross", .{
    .target = target,
    .optimize = optimize,
});

exe.root_module.addImport("SDL_shadercross", sdl_shadercross_dep.module("SDL_shadercross"));
```

`addImport` is all that is needed: the module's C source is compiled as part of
your executable and its dependencies are linked in. Unlike a library artifact,
there is nothing to `linkLibrary` for SDL_shadercross itself.

To call the API from your own code, include its public header:

```zig
exe.root_module.addIncludePath(sdl_shadercross_dep.path("include"));
```

Then in your Zig source file:

```zig
const c = @cImport({
    @cInclude("SDL3_shadercross/SDL_shadercross.h");
});
```

Include paths declared on a module are used only when compiling that module's
own sources; they are **not** inherited by the importing module. That is why the
`addIncludePath` line above is needed if your own files include the header.

## Build together with [castholm/SDL](https://github.com/castholm/SDL)

Add castholm/SDL as a dependency. Pick the commit that is compatible with your
Zig version:

```sh
zig fetch --save=SDL git+https://github.com/castholm/SDL
```

Then compile SDL_shadercross against it, so that SDL and SDL_shadercross end up
in the same build graph:

```zig
const sdl = b.dependency("SDL", .{ .target = target, .optimize = optimize });
const sdl_shadercross_dep = b.dependency("SDL_shadercross", .{
    .target = target,
    .optimize = optimize,
    .link_system_sdl = false, // SDL comes from the dependency above
});

// Give SDL_shadercross's C source SDL's headers and library.
sdl_shadercross_dep.module("SDL_shadercross").linkLibrary(sdl.artifact("SDL3"));

// Compile SDL_shadercross into your executable and expose its header.
exe.root_module.addImport("SDL_shadercross", sdl_shadercross_dep.module("SDL_shadercross"));
exe.root_module.addIncludePath(sdl_shadercross_dep.path("include"));

// Link SDL into your executable (this also provides SDL's headers to your code).
exe.linkLibrary(sdl.artifact("SDL3"));
```

SPIRV-Cross and DXC are still taken from the system by default. Supply them
through the graph the same way (with `link_system_spirv_cross = false` /
`link_system_dxc = false`) if you vendor them instead.

## Default behavior

All options are passed through `b.dependency("SDL_shadercross", .{ ... })`.

| Option | Default | Description |
| --- | --- | --- |
| `dxc` | `true` | Enable HLSL compilation via DXC. When `false`, DXC is not linked and HLSL-to-DXIL is unavailable. |
| `link_system_sdl` | `true` | Fall back to the system SDL3 library when SDL is not provided by the caller. |
| `link_system_spirv_cross` | `true` | Fall back to the system SPIRV-Cross C library. |
| `link_system_dxc` | `true` | Fall back to the system DXC library (only relevant when `dxc` is `true`). |

With the defaults you do not need to provide anything: your project links the
system `sdl3`, `spirv-cross-c-shared`, and `dxcompiler`.

Each `link_system_* = false` hands that dependency over to you. If you disable a
fallback without supplying the library through the module graph, compilation or
linking will fail with missing headers or unresolved symbols.

Running `zig build` in this repository produces no files; it exists only to
provide the module.

## Requirements

- Zig 0.15.2
- SDL3, SPIRV-Cross and DirectXShaderCompiler when using the system fallbacks.

## License

zlib. See `LICENSE.txt`.
