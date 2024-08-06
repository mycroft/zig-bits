const std = @import("std");
const base64 = std.base64.standard;

const buffer_size = 4096;

fn encode(reader: anytype, writer: anytype) !void {
    var buffer: [buffer_size * 3]u8 = undefined;
    var encoded: [buffer_size * 5]u8 = undefined;

    const b64_encoder = base64.Encoder;

    while (true) {
        const read_size = try reader.readAll(&buffer);
        if (read_size == 0) {
            break;
        }

        const b64_size = b64_encoder.calcSize(read_size);
        _ = b64_encoder.encode(&encoded, buffer[0..read_size]);
        _ = try writer.write(encoded[0..b64_size]);
    }
}

fn decode(reader: anytype, writer: anytype) !void {
    var encoded: [buffer_size * 4]u8 = undefined;
    var decoded: [buffer_size * 3]u8 = undefined;

    const b64_decoder = base64.Decoder;

    while (true) {
        const read_size = try reader.readAll(&encoded);
        if (read_size == 0) {
            break;
        }

        const trimmed = std.mem.trim(
            u8,
            encoded[0..read_size],
            &std.ascii.whitespace,
        );

        const dec_size = try b64_decoder.calcSizeForSlice(trimmed);
        _ = try b64_decoder.decode(&decoded, trimmed);
        _ = try writer.write(decoded[0..dec_size]);
    }
}

pub fn main() !void {
    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();

    var is_encode = true;
    var filename: []const u8 = "";

    const allocator = std.heap.page_allocator;
    var args = try std.process.argsWithAllocator(allocator);
    _ = args.skip();

    while (args.next()) |arg| {
        if (std.mem.eql(u8, "-e", arg)) {
            is_encode = true;
        } else if (std.mem.eql(u8, "-d", arg)) {
            is_encode = false;
        } else {
            filename = arg;
        }
    }

    if (filename.len > 0) {
        var file = try std.fs.cwd().openFile(filename, .{ .mode = .read_only });
        defer file.close();

        if (is_encode) {
            try encode(file.reader(), stdout);
        } else {
            try decode(file.reader(), stdout);
        }
    } else {
        if (is_encode) {
            try encode(stdin, stdout);
        } else {
            try decode(stdin, stdout);
        }
    }
}
