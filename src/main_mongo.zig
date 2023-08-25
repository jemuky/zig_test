const std = @import("std");
const debug = std.log.debug;
const info = std.log.info;
const warn = std.log.warn;
const err = std.log.err;
const alloc = std.heap.page_allocator;
const redis = @cImport({
    @cInclude("mongoc/mongoc.h");
});

pub fn main() !u8 {
    debug("mongo start!", .{});
    return 0;
}
