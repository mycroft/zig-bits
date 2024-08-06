const std = @import("std");

fn cat(reader: anytype, writer: anytype) !void {
    var buffer: [256]u8 = undefined;

    while (true) {
        const s = try reader.readAll(&buffer);
        if (s == 0) {
            break;
        }

        _ = try writer.write(buffer[0..s]);
    }
}

pub fn main() !void {
    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();

    if (std.os.argv.len > 1) {
        const filename = std.mem.span(std.os.argv[1]);
        var file = try std.fs.cwd().openFile(filename, .{ .mode = .read_only });
        defer file.close();

        try cat(file.reader(), stdout);
    } else {
        try cat(stdin, stdout);
    }
}
