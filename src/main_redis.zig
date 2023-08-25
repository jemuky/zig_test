const std = @import("std");
const debug = std.log.debug;
const info = std.log.info;
const warn = std.log.warn;
const err = std.log.err;
const alloc = std.heap.page_allocator;
const redis = @cImport({
    @cInclude("hiredis.h");
});

pub fn main() !u8 {
    debug("start", .{});
    var conn = redis.redisConnect("127.0.0.1", 6379);
    if (conn.*.err != 0) {
        err("error: {s}", .{conn.*.errstr});
        return 1;
    }
    defer redis.redisFree(conn);

    // PINGs
    var a = redis.redisCommand(conn, "SET %s %s", "setkey", "123");
    var reply: *redis.redisReply = @alignCast(@ptrCast(a.?));
    err("RESPONSE1={s}", .{reply.*.str});

    var b = redis.redisCommand(conn, "GET %s", "setkey");
    var reply2: *redis.redisReply = @alignCast(@ptrCast(b.?));
    err("RESPONSE2={s}", .{reply2.*.str});
    defer redis.freeReplyObject(reply);

    return 0;
}
