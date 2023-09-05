const std = @import("std");
const LazyPath = std.Build.LazyPath;
// const ffmpeg = @import("libs/ffmpeg/build.zig");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) !void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "z_test",
        // In this case the main source file is merely a path, however, in more\
        // complicated build scripts, this could be a generated file.
        .root_source_file = .{ .path = "src/main_zip.zig" },
        .target = target,
        .optimize = optimize,
    });

    exe.linkLibC();
    // linkFFMPEG(exe);
    // linkMysql(exe);
    // linkRedis(exe);
    // linkStaticLib(exe);
    // linkMongo(exe);
    linkZip(exe);

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(exe);

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = b.addRunArtifact(exe);

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    const unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/test_.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}

// 在此外还需拷入ffmpeg的bin下的dll文件，如avcodec-60.dll等
// 直接下载编译好的：http://ffmpeg.org/download.html，选择windows版本
fn linkFFMPEG(exe: *std.Build.Step.Compile) void {
    exe.addSystemIncludePath(std.Build.LazyPath{
        .path = "D:\\program\\ffmpeg\\ffmpeg-shared\\include",
    });
    exe.addLibraryPath(std.Build.LazyPath{
        .path = "D:\\program\\ffmpeg\\ffmpeg-shared\\lib",
    });

    exe.linkSystemLibrary("avformat");
    exe.linkSystemLibrary("avcodec");
    exe.linkSystemLibrary("avutil");
    exe.linkSystemLibrary("swscale");
    exe.linkSystemLibrary("swresample");
}

// 此外还需拷入libmysql.dll
// 安装mysql-svr
fn linkMysql(exe: *std.Build.Step.Compile) void {
    exe.addSystemIncludePath(std.Build.LazyPath{
        .path = "D:\\program\\mysql-8.0.34-winx64\\include",
    });

    exe.addLibraryPath(std.Build.LazyPath{
        .path = "D:\\program\\mysql-8.0.34-winx64\\lib",
    });

    // 引入动态库需要这样
    exe.linkSystemLibrary("libmysql");
    // 引入静态库会产生和系统的符号重复的问题，可以不引libc，不过需要什么系统库再引
    // lld-link: duplicate symbol: atexit
}

// 此外还需拷入hiredis.dll
// hiredis: https://github.com/redis/hiredis.git
fn linkRedis(exe: *std.Build.Step.Compile) void {
    exe.addSystemIncludePath(std.Build.LazyPath{
        .path = "D:\\space\\scode\\hiredis",
    });
    exe.addLibraryPath(std.Build.LazyPath{
        .path = "D:\\space\\scode\\hiredis\\build\\Release",
    });

    exe.linkSystemLibrary("hiredis");
}

// mongo比较麻烦，可以先用c绑定，再用zig调用
// mongo-c-driver: https://github.com/mongodb/mongo-c-driver
fn linkMongo(exe: *std.Build.Step.Compile) void {
    _ = exe;
}

// 静态链接
fn linkStaticLib(exe: *std.Build.Step.Compile) void {
    exe.addIncludePath(std.Build.LazyPath{
        .path = ".",
    });

    exe.addObjectFile(std.Build.LazyPath{
        .path = "sl.lib",
    });
}

// https://github.com/kuba--/zip
fn linkZip(exe: *std.Build.Step.Compile) void {
    exe.addIncludePath(LazyPath{
        .path = "D:\\space\\scode\\zip\\src",
    });
    exe.addLibraryPath(std.Build.LazyPath{
        .path = "D:\\space\\scode\\zip\\build\\Release",
    });
    exe.linkSystemLibrary("zip");
}
