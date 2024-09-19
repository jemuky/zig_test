const std = @import("std");
const debug = std.log.debug;
const info = std.log.info;
const warn = std.log.warn;
const err = std.log.err;
const alloc = std.heap.page_allocator;

const c = @cImport({
    @cInclude("curl/curl.h");
});

pub fn main() !void {
    _ = std.os.windows.kernel32.SetConsoleOutputCP(65001);
    debug("version_info={s}", .{c.curl_version()});

    const curl = c.curl_easy_init();
    if (curl == null) {
        err("curl_easy_init failed", .{});
        return;
    }
    defer c.curl_easy_cleanup(curl);
    var code = c.curl_easy_setopt(curl, c.CURLOPT_URL, "https://www.baidu.com");
    warn("curl_easy_setopt1 code={}", .{code});
    code = c.curl_easy_setopt(curl, c.CURLOPT_FOLLOWLOCATION, @as(i32, 1));
    warn("curl_easy_setopt2 code={}", .{code});
    code = c.curl_easy_setopt(curl, c.CURLOPT_CAINFO, "conf/curl-ca-bundle.crt");

    // var buf = try alloc.alloc(u8, 3000);
    // defer alloc.free(buf);
    // code = c.curl_easy_setopt(curl, c.CURLOPT_WRITEDATA, buf);
    // warn("curl_easy_setopt3 code={}", .{code});

    const res = c.curl_easy_perform(curl);
    if (res != c.CURLE_OK) err("curl_easy_perform failed, err={s}", .{c.curl_easy_strerror(res)});
    // warn("buf={s}", .{buf});
    debug("success", .{});
}
