const std = @import("std");

const Entry = struct {
    name: []const u8,
    n: u32,
};

fn compare(_: void, lhs: Entry, rhs: Entry) bool {
    return lhs.n < rhs.n;
}

fn read_dir(allocator: std.mem.Allocator, path: []const u8, entries: *std.ArrayList(Entry)) !void {
    var dir = try std.fs.cwd().openDir(path, .{ .iterate = true });
    var it = dir.iterate();

    while (try it.next()) |entry| {
        const stat = try dir.statFile(entry.name);

        const v = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ path, entry.name });

        if (stat.kind == std.fs.File.Kind.directory) {
            try read_dir(allocator, v, entries);
            allocator.free(v);
        } else if (stat.kind == std.fs.File.Kind.file) {
            try entries.append(Entry{ .name = v, .n = std.crypto.random.int(u32) });
        }
    }
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    std.io.getStdIn().close();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);

    const allocator = gpa.allocator();

    var entries = std.ArrayList(Entry).init(allocator);
    defer entries.deinit();

    try read_dir(allocator, ".", &entries);

    std.mem.sort(Entry, entries.items, {}, compare);

    for (entries.items) |entry| {
        try stdout.print("{s}\n", .{entry.name});
        allocator.free(entry.name);
    }
}
