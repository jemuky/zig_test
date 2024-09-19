const std = @import("std");
const debug = std.log.debug;
const info = std.log.info;
const warn = std.log.warn;
const err = std.log.err;
const alloc = std.heap.page_allocator;
const g = @cImport({
    @cInclude("glad/glad.h");
    @cInclude("GLFW/glfw3.h");
});
// const localg = @cImport({
//     @cInclude("glad_loader.h");
// });

pub fn main() u8 {
    _ = g.glfwInit();
    defer g.glfwTerminate();
    g.glfwWindowHint(g.GLFW_CONTEXT_VERSION_MAJOR, 3);
    g.glfwWindowHint(g.GLFW_CONTEXT_VERSION_MINOR, 3);
    g.glfwWindowHint(g.GLFW_OPENGL_PROFILE, g.GLFW_OPENGL_CORE_PROFILE);

    const window = g.glfwCreateWindow(800, 600, "LearnOpenGL", null, null);
    if (window == null) {
        debug("Failed to create GLFW window", .{});
        g.glfwTerminate();
        return 1;
    }
    // 将窗口的上下文设置为当前线程上的主上下文
    g.glfwMakeContextCurrent(window);

    // init glad
    if (g.gladLoadGLLoader(&g.glfwGetProcAddress) != 0) {
        debug("Failed to initialize GLAD", .{});
        return 1;
    }

    // 渲染窗口大小
    g.glViewport(0, 0, 800, 600);
    // 每次调整窗口大小时通过注册它来调用该函数
    _ = g.glfwSetFramebufferSizeCallback(window, framebuffer_size_callback);
    // 继续绘制图像并处理用户输入，直到程序被明确告知停止为止
    while (g.glfwWindowShouldClose(window) != 0) {
        g.glfwSwapBuffers(window);
        g.glfwPollEvents();
    }
    return 0;
}

fn framebuffer_size_callback(window: ?*g.GLFWwindow, width: c_int, height: c_int) callconv(.C) void {
    _ = window;
    g.glViewport(0, 0, width, height);
}
