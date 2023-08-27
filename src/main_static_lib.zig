const std = @import("std");
const debug = std.log.debug;
const info = std.log.info;
const warn = std.log.warn;
const err = std.log.err;
const alloc = std.heap.page_allocator;
const sl = @cImport({
    @cInclude("sl.h");
});

pub fn main() !u8 {
    _ = std.os.windows.kernel32.SetConsoleOutputCP(65001);
    var args = try std.process.argsWithAllocator(alloc);
    defer args.deinit();

    var arg_list = std.ArrayList([]const u8).init(alloc);
    defer arg_list.deinit();
    var arg = args.next();
    while (arg != null) {
        try arg_list.append(arg.?);
        debug("{s}", .{arg.?});
        arg = args.next();
    }
    if (arg_list.items.len < 2) {
        err("You need to specify a media file.", .{});
        return 2;
    }
    return @intCast(sl.smain(@intCast(arg_list.items.len), @ptrCast(arg_list.items)));
}
