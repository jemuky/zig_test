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
    const conn = redis.redisConnect("127.0.0.1", 6379);
    if (conn.*.err != 0) {
        err("error: {s}", .{conn.*.errstr});
        return 1;
    }
    defer redis.redisFree(conn);

    // PINGs
    const a = redis.redisCommand(conn, "SET %s %s", "setkey", "123");
    const reply: *redis.redisReply = @alignCast(@ptrCast(a.?));
    err("RESPONSE1={s}", .{reply.*.str});

    const b = redis.redisCommand(conn, "GET %s", "setkey");
    const reply2: *redis.redisReply = @alignCast(@ptrCast(b.?));
    err("RESPONSE2={s}", .{reply2.*.str});
    defer redis.freeReplyObject(reply);

    return 0;
}
