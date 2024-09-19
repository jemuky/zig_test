const std = @import("std");
const debug = std.log.debug;
const info = std.log.info;
const warn = std.log.warn;
const err = std.log.err;
const alloc = std.heap.page_allocator;
const z = @cImport({
    @cInclude("zip.h");
});

pub fn main() !u8 {
    // return default_compression();
    // return extract();
    const i: i32 = 1234;
    debug("ctn={any}\n", .{@typeInfo(@TypeOf(i))});
    return 0;
}

fn cint_to_u8(cint: c_int) u8 {
    return @intCast(std.math.absCast(cint));
}

fn default_compression() !u8 {
    var ret: c_int = 0;

    const zip = z.zip_open("foo.zip", z.ZIP_DEFAULT_COMPRESSION_LEVEL, 'w');
    defer z.zip_close(zip);

    debug("zip == null? {}", .{zip == null});

    ret = z.zip_entry_open(zip, "foo-1.txt");
    if (ret != 0) {
        var dir = std.fs.cwd();
        err("zip_entry_open sl.h failed: {}, cwd={s}", .{ ret, try dir.realpathAlloc(alloc, ".") });
        defer dir.close();
        return cint_to_u8(ret);
    }
    const buf = "some data here...";
    ret = z.zip_entry_write(zip, buf, buf.len);
    if (ret != 0) {
        err("zip_entry_write failed: {}", .{ret});
        // return cint_to_u8(ret);
    }
    _ = z.zip_entry_close(zip);

    ret = z.zip_entry_open(zip, "foo-2.txt");
    if (ret != 0) {
        err("zip_entry_open run.bat failed: {}", .{ret});
        return cint_to_u8(ret);
    }
    ret = z.zip_entry_fwrite(zip, "foo-2.1.txt");
    if (ret != 0) {
        err("zip_entry_fwrite foo-2.1 failed: {}", .{ret});
        // return cint_to_u8(ret);
    }
    ret = z.zip_entry_fwrite(zip, "foo-2.2.txt");
    if (ret != 0) {
        err("zip_entry_fwrite foo-2.2 failed: {}", .{ret});
        // return cint_to_u8(ret);
    }
    ret = z.zip_entry_fwrite(zip, "foo-2.3.txt");
    if (ret != 0) {
        err("zip_entry_fwrite foo-2.3 failed: {}", .{ret});
        // return cint_to_u8(ret);
    }
    _ = z.zip_entry_close(zip);
    return 0;
}

fn extract() !u8 {
    comptime var i: isize = 0;
    const ts = struct {
        fn on_extract_entry(filename: [*c]const u8, arg: ?*anyopaque) callconv(.C) c_int {
            const n = @as(*c_int, @alignCast(@ptrCast(arg))).*;
            i += 1;
            debug("Extracted: {s} ({} of {})", .{ filename, i, n });
            return 0;
        }
    };
    var opq: usize = 2;
    const arg = @as(*anyopaque, @alignCast(@ptrCast(&opq)));
    _ = z.zip_extract("foo.zip", "foo", ts.on_extract_entry, arg);
    return 0;
}
