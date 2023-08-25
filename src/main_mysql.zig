const std = @import("std");
const debug = std.log.debug;
const info = std.log.info;
const warn = std.log.warn;
const err = std.log.err;
const alloc = std.heap.page_allocator;
const mysql = @cImport({
    @cInclude("mysql.h");
});

pub fn main() !u8 {
    debug("mysql_init", .{});
    debug("client version={s}", .{mysql.mysql_get_client_info()});
    var conn = mysql.mysql_init(null);

    if (conn == null) {
        err("mysql_init failed, {s}", .{mysql.mysql_error(conn)});
        return 1;
    }
    defer mysql.mysql_close(conn);

    if (mysql.mysql_real_connect(conn, "127.0.0.1", "root", "", null, 3306, null, 0) == null) {
        err("mysql_real_connect failed, {s}", .{mysql.mysql_error(conn)});
        return 1;
    }
    // if (mysql.mysql_query(conn, "CREATE DATABASE testdb") > 0) {
    //     err("mysql create database failed, {s}", .{mysql.mysql_error(conn)});
    //     return 1;
    // }
    if (mysql.mysql_query(conn, "USE testdb") > 0) {
        err("mysql use database failed, {s}", .{mysql.mysql_error(conn)});
        return 1;
    }
    // if (mysql.mysql_query(conn, "CREATE TABLE cars(id INT PRIMARY KEY AUTO_INCREMENT, name VARCHAR(255), price INT)") > 0) {
    //     err("mysql create table failed, {s}", .{mysql.mysql_error(conn)});
    //     return 1;
    // }
    // debug("create cars suc", .{});

    if (mysql.mysql_query(conn, "INSERT INTO cars(name, price) VALUES('Baoma', 52542)") > 0) {
        err("mysql insert failed, {s}", .{mysql.mysql_error(conn)});
        return 1;
    }
    debug("insert car suc", .{});

    if (mysql.mysql_query(conn, "SELECT * FROM cars") > 0) {
        err("mysql select failed, {s}", .{mysql.mysql_error(conn)});
        return 1;
    }
    const result = mysql.mysql_store_result(conn);
    if (result == null) {
        err("mysql_store_result failed, {s}", .{mysql.mysql_error(conn)});
        return 1;
    }
    const num_fields = mysql.mysql_num_fields(result);

    var row = mysql.mysql_fetch_row(result);

    while (row != null) {
        var i: usize = 0;
        while (i < num_fields) : (i += 1) {
            debug("{s}  ", .{row[i]});
        }

        row = mysql.mysql_fetch_row(result);
    }

    return 0;
}
