const std = @import("std");

fn get_cwd(allocator: std.mem.Allocator) ![]u8 {
    return try std.fs.cwd().realpathAlloc(allocator, ".");
}

fn compareStrings(_: void, lhs: []const u8, rhs: []const u8) bool {
    return std.mem.order(u8, lhs, rhs).compare(std.math.CompareOperator.lt);
}

pub fn main() !void {
    // getting an allocator that'll be used in realpathAlloc
    // const allocator = std.heap.page_allocator;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);

    const allocator = gpa.allocator();

    const stdout = std.io.getStdOut().writer();
    // const stderr = std.io.getStdErr().writer();

    var opt_long = false;
    var opt_hidden = false;
    var wd = try get_cwd(allocator);

    for (std.os.argv[1..]) |arg| {
        const argf = std.mem.span(arg);

        if (std.mem.eql(u8, argf, "-l")) {
            opt_long = true;
        } else if (std.mem.eql(u8, argf, "-a")) {
            opt_hidden = true;
        } else {
            allocator.free(wd);
            wd = try allocator.dupe(u8, argf);
        }
    }
    defer allocator.free(wd);

    // try stderr.print("current dir: {s}\n", .{wd});

    // our call to openDir with the iterate flag
    var iterable_dir = try std.fs.openDirAbsolute(wd, .{ .iterate = true });

    var it = iterable_dir.iterate();

    var entries = std.ArrayList([]const u8).init(allocator);
    defer entries.deinit();

    while (try it.next()) |entry| {
        if (!opt_hidden and entry.name[0] == '.') {
            continue;
        }

        try entries.append(try allocator.dupe(u8, entry.name));
    }

    std.mem.sort([]const u8, entries.items, {}, compareStrings);

    for (entries.items) |entry| {
        defer allocator.free(entry);

        const stat = iterable_dir.statFile(entry) catch {
            continue;
        };

        const file_type: u8 = switch (stat.kind) {
            std.fs.File.Kind.directory => 'd',
            std.fs.File.Kind.file => '.',
            std.fs.File.Kind.sym_link => 's',
            else => '?',
        };

        if (opt_long) {
            try stdout.print("{c} {d:8} {o} {s}\n", .{ file_type, stat.size, stat.mode % 0o1000, entry });
        } else {
            try stdout.print("{s}\n", .{entry});
        }
    }
}
