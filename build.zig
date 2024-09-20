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
        .root_source_file = b.path("src/main_curl.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe.linkLibC();
    // exe.linkLibCpp();
    // linkFFMPEG(exe);
    // linkMysql(exe);
    // linkRedis(exe);
    // linkStaticLib(exe);
    // linkMongo(exe);
    // linkZip(exe);
    linkCurl(exe, b);
    // linkGlfw(exe);

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
        .root_source_file = b.path("src/test_.zig"),
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

/// 在此外还需拷入ffmpeg的bin下的dll文件，如avcodec-60.dll等
/// 直接下载编译好的：http://ffmpeg.org/download.html，选择windows版本
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

/// 此外还需拷入libmysql.dll
/// 安装mysql-svr
fn linkMysql(exe: *std.Build.Step.Compile) void {
    exe.addSystemIncludePath(LazyPath{ .cwd_relative = "D:\\program\\mysql-8.0.34-winx64\\include" });

    exe.addLibraryPath(LazyPath{ .cwd_relative = "D:\\program\\mysql-8.0.34-winx64\\lib" });

    // 引入动态库需要这样
    exe.linkSystemLibrary("libmysql");
    // 引入静态库会产生和系统的符号重复的问题，可以不引libc，不过需要什么系统库再引
    // lld-link: duplicate symbol: atexit
}

/// 此外还需拷入hiredis.dll
/// hiredis: https://github.com/redis/hiredis.git
fn linkRedis(exe: *std.Build.Step.Compile) void {
    exe.addSystemIncludePath(std.Build.LazyPath{
        .path = "D:\\space\\scode\\hiredis",
    });
    exe.addLibraryPath(std.Build.LazyPath{
        .path = "D:\\space\\scode\\hiredis\\build\\Release",
    });

    exe.linkSystemLibrary("hiredis");
}

/// mongo比较麻烦，可以先用c实现方法，再用zig调用
/// mongo-c-driver: https://github.com/mongodb/mongo-c-driver
fn linkMongo(exe: *std.Build.Step.Compile) void {
    exe.addSystemIncludePath(std.Build.LazyPath{
        .path = "D:\\psoft\\mongo\\src\\libmongoc\\src",
    });
    exe.addSystemIncludePath(std.Build.LazyPath{
        .path = "D:\\psoft\\mongo\\src\\libbson\\src",
    });
    exe.addSystemIncludePath(std.Build.LazyPath{
        .path = "D:\\psoft\\mongo\\out\\src\\libbson\\src",
    });
    exe.addSystemIncludePath(std.Build.LazyPath{
        .path = "D:\\psoft\\mongo\\out\\src\\libmongoc\\src\\mongoc",
    });
    exe.addLibraryPath(std.Build.LazyPath{
        .path = "D:\\psoft\\mongo\\out\\src\\libmongoc\\Release",
    });
    exe.addLibraryPath(std.Build.LazyPath{
        .path = "D:\\psoft\\mongo\\out\\src\\libbson\\Release",
    });
    // exe.addObjectFile(std.Build.LazyPath{
    //     .path = "D:\\psoft\\mongo\\out\\src\\libmongoc\\Release\\mongoc-static-1.0.lib",
    // });
    // exe.addObjectFile(std.Build.LazyPath{
    //     .path = "D:\\psoft\\mongo\\out\\src\\libbson\\Release\\bson-static-1.0.lib",
    // });

    exe.linkSystemLibrary("mongoc-1.0");
    exe.linkSystemLibrary("bson-1.0");
}

/// 静态链接
fn linkStaticLib(exe: *std.Build.Step.Compile) void {
    exe.addIncludePath(std.Build.LazyPath{
        .path = ".",
    });

    exe.addObjectFile(std.Build.LazyPath{
        .path = "sl.lib",
    });
}

/// https://github.com/kuba--/zip
fn linkZip(exe: *std.Build.Step.Compile) void {
    exe.addIncludePath(LazyPath{
        .path = "D:\\space\\scode\\zip\\src",
    });
    exe.addLibraryPath(std.Build.LazyPath{
        .path = "D:\\space\\scode\\zip\\build\\Release",
    });
    exe.linkSystemLibrary("zip");
}

/// https://curl.se/libcurl/
/// 在上面链接的下载页下载编译好的lib
/// 注意：这里需要libcurl-x64.dll(下载的bin目录下)在根目录，看起来某个静态库链接了这个动态库(知道这个关系通过dumpbin /dependents [此项目编译后文件exe]或者ldd)
/// 看起来上面的都不需要增加addLibraryPath，而静态链接库只能放在项目目录下，动态链接库只能放在项目根目录下或环境变量path中
fn linkCurl(exe: *std.Build.Step.Compile, b: *std.Build) void {
    exe.addSystemIncludePath(.{
        .cwd_relative = "D:\\space\\scode\\curl-8.8.0\\include",
    });
    exe.addObjectFile(b.path("curl_lib/libbrotlicommon.a"));
    exe.addObjectFile(b.path("curl_lib/libbrotlidec.a"));
    exe.addObjectFile(b.path("curl_lib/libcrypto.a"));
    exe.addObjectFile(b.path("curl_lib/libcurl.dll.a"));
    exe.addObjectFile(b.path("curl_lib/libnghttp2.a"));
    exe.addObjectFile(b.path("curl_lib/libnghttp3.a"));
    exe.addObjectFile(b.path("curl_lib/libngtcp2.a"));
    exe.addObjectFile(b.path("curl_lib/libngtcp2_crypto_quictls.a"));
    exe.addObjectFile(b.path("curl_lib/libssh2.a"));
    exe.addObjectFile(b.path("curl_lib/libssl.a"));
    exe.addObjectFile(b.path("curl_lib/libz.a"));
    exe.addObjectFile(b.path("curl_lib/libzstd.a"));
}

/// 使用zig调用时g.gladLoadGLLoader(&g.glfwGetProcAddress)总是返回非0，使用c调用这个再供zig调用也是
/// 故改为使用cpp调用
/// 此处只能用msvc，若使用gnu则libCpp会找不到msvcrt-os.lib下的sprintf_s函数，libc会找不到更多
fn linkGlfw(exe: *std.Build.Step.Compile) void {
    exe.addCSourceFiles(&[_][]const u8{"src/glad.c"}, &[_][]const u8{});
    exe.addIncludePath(LazyPath{
        .path = "glfw_inc",
    });
    exe.addObjectFile(.{ .path = "glfw_lib/glfw3.lib" });
    exe.linkSystemLibrary("opengl32");
    exe.linkSystemLibrary("KERNEL32");
    exe.linkSystemLibrary("user32");
    exe.linkSystemLibrary("gdi32");
    exe.linkSystemLibrary("shell32");
}
