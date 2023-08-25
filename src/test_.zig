const std = @import("std");
const alloc = @import("std").heap.page_allocator;
const expect = @import("std").testing.expect;
const testing = @import("std").testing;
const ArrayList = std.ArrayList;
usingnamespace @import("std");

const Err = error{ OOM, Oops };
const Err2 = error{ OAM, OCM };

fn fail_func2() Err!i32 {
    return error.OOM;
}

const print = std.debug.print;

test "buf" {
    var f1 = std.fs.cwd().makeOpenPath("frame", .{}) catch @panic("makeOpenPath failed");
    var f = if (f1.openFile("frame-1.pgm", std.fs.File.OpenFlags{ .mode = .read_write })) |data| blk: {
        break :blk data;
    } else |e| blk: {
        if (e != error.FileNotFound) {
            @panic("openFile failed");
        } else {
            break :blk f1.createFile("frame-1.pgm", .{}) catch @panic("createFile failed");
        }
    };
    var buf: [18]u8 = undefined;
    if (f.read(&buf)) |_| {} else |err| {
        print("read failed, err={}", .{err});
        return;
    }
    print("buf={s}\n", .{buf});
}
pub inline fn min(a: i32, b: i32) i32 {
    return comptime if (a < b) a else b;
}

// test "LinkedList" {
//     const List = LinkedList(u8);

//     var list = List{};
//     var a = List.Node{ .data = 97 };
//     var b = List.Node{ .data = 101 };
//     list.push(&a);
//     list.push(&b);
//     list.printSelf();
//     list.delete(&b);
//     list.printSelf();
//     print("c={any}\n", .{list.pop().?.data});
//     list.printSelf();
// }

const builtin = @import("builtin");
fn isTest() bool {
    return builtin.is_test;
}

pub fn LinkedList(comptime T: type) type {
    return struct {
        // Please implement the doubly linked `Node` (replacing each `void`).
        pub const Node = struct {
            prev: ?*Node = null,
            next: ?*Node = null,
            data: T,
        };

        const Self = @This();

        // Please implement the fields of the linked list (replacing each `void`).
        first: ?*Node = null,
        last: ?*Node = null,
        len: usize = 0,

        // Please implement the below methods.
        // You need to add the parameters to each method.

        fn printSelf(self: *const Self) void {
            var it = self.first;
            print("len={}, data: ", .{self.len});
            while (it != null) {
                print("{} ", .{it.?.data});
                it = it.?.next;
            }
            print("\n", .{});
        }

        fn printSelfRev(self: *const Self) void {
            var it = self.last;
            print("len={}, data: ", .{self.len});
            while (it != null) {
                print("{} ", .{it.?.data});
                it = it.?.prev;
            }
            print("\n", .{});
        }

        // insert value at back
        pub fn push(self: *Self, n: *Node) void {
            if (self.last == null) {
                self.last = n;
                self.first = n;
                self.len = 1;
                return;
            }
            // 设置n的前置节点
            n.prev = self.last;
            // 设置原last的后置节点
            self.last.?.next = n;
            // 设置last节点为新节点
            self.last = n;
            self.len += 1;
        }

        // remove value at back)
        pub fn pop(self: *Self) ?*Node {
            if (self.last == null) return null;
            const last = self.last;

            defer self.len -= 1;
            defer last.?.prev = null;
            defer last.?.next = null;

            print("self={any}\n", .{self});

            if (self.len == 1) {
                self.first = null;
                self.last = null;
                return last;
            }
            self.last = self.last.?.prev;
            self.last.?.next = null;
            return last;
        }

        // remove value at front
        pub fn shift(self: *Self) ?*Node {
            if (self.first == null) return null;
            const first = self.first;

            defer self.len -= 1;
            defer first.?.prev = null;
            defer first.?.next = null;

            if (self.len == 1) {
                self.first = null;
                self.last = null;
                return first;
            }
            self.first = self.first.?.next;
            self.first.?.prev = null;
            return first;
        }

        // insert value at front
        pub fn unshift(self: *Self, n: *Node) void {
            if (self.first == null) {
                self.last = n;
                self.first = n;
                self.len = 1;
                return;
            }
            // 设置n的后置节点
            n.next = self.first;
            // 设置原first的前置节点
            self.first.?.prev = n;
            // 设置first节点为新节点
            self.first = n;
            self.len += 1;
        }

        pub fn delete(self: *Self, n: *Node) void {
            var it = self.first;
            while (it != null) {
                defer it = it.?.next;
                if (it.?.data != n.data) continue;
                if (it.?.prev != null) it.?.prev.?.next = it.?.next else self.first = it.?.next;
                if (it.?.next != null) it.?.next.?.prev = it.?.prev else self.last = it.?.prev;
                self.len -= 1;
                break;
            }
        }
    };
}
