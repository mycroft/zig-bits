const std = @import("std");
const net = std.net;
const print = std.debug.print;

const Passwd = struct {
    username: []const u8,
    uid: u32,
    gid: u32,
    gecos: []const u8,
    path: []const u8,
    shell: []const u8,
};

const ParsingError = error{
    Read,
    NoEntry,
};

fn get_server_socket() !net.Server {
    const loopback = try net.Ip4Address.parse("127.0.0.1", 79); // 79
    const localhost = net.Address{ .in = loopback };
    const server = try localhost.listen(.{
        .reuse_port = true,
    });

    return server;
}

fn concat_free(allocator: std.mem.Allocator, a: []const u8, b: []const u8) ![]u8 {
    const result = try allocator.alloc(u8, a.len + b.len);
    @memcpy(result[0..a.len], a);
    @memcpy(result[a.len..], b);

    allocator.free(a);

    return result;
}

fn getpwent(allocator: std.mem.Allocator, username: []const u8) !?Passwd {
    const passwd = try std.fs.openFileAbsolute("/etc/passwd", .{ .mode = .read_only });
    defer passwd.close();

    const file_buffer = try passwd.readToEndAlloc(allocator, 4096 * 16);
    defer allocator.free(file_buffer);

    var iter = std.mem.split(u8, file_buffer, "\n");

    while (iter.next()) |entry| {
        var entryIter = std.mem.split(u8, entry, ":");

        const entry_username = entryIter.next().?;
        if (!std.mem.eql(u8, entry_username, username)) {
            continue;
        }

        _ = entryIter.next(); // password aka 'x'

        const p = Passwd{
            .username = try allocator.dupe(u8, entry_username),
            .uid = try std.fmt.parseInt(u32, entryIter.next().?, 10),
            .gid = try std.fmt.parseInt(u32, entryIter.next().?, 10),
            .gecos = try allocator.dupe(u8, entryIter.next().?),
            .path = try allocator.dupe(u8, entryIter.next().?),
            .shell = try allocator.dupe(u8, entryIter.next().?),
        };

        return p;
    }

    return ParsingError.Read;
}

fn get_plan(allocator: std.mem.Allocator, username: []const u8) ![]u8 {
    print("user: {s}\n", .{username});

    var res = try allocator.dupe(u8, ""); // bruh

    const passwd = try getpwent(allocator, username);
    if (passwd == null) {
        res = try concat_free(allocator, res, "No passwd entry found\n");
    } else {
        const passwd_str = try std.fmt.allocPrint(allocator, "User: {s}\tGecos: {s}\tShell: {s}\n", .{ passwd.?.username, passwd.?.gecos, passwd.?.shell });
        defer allocator.free(passwd_str);

        const passwd_str2 = try std.fmt.allocPrint(allocator, "Uid: {d}\tGid: {d}\tPath: {s}\n", .{ passwd.?.uid, passwd.?.gid, passwd.?.path });
        defer allocator.free(passwd_str2);
        res = try concat_free(allocator, res, passwd_str);
        res = try concat_free(allocator, res, passwd_str2);
    }

    res = try concat_free(allocator, res, "Plan:\n");

    const homepath = try std.fmt.allocPrint(allocator, "/home/{s}/.plan", .{username});
    defer allocator.free(homepath);

    const file = std.fs.openFileAbsolute(homepath, .{ .mode = .read_only }) catch {
        return allocator.dupe(u8, "no plan");
    };
    defer file.close();

    const buffer = try file.readToEndAlloc(allocator, 4096);
    defer allocator.free(buffer);

    return try concat_free(allocator, res, buffer);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var server = try get_server_socket();
    defer server.deinit();

    const addr = server.listen_address;
    print("Listening on {}, access this port to end the program\n", .{addr.getPort()});

    while (true) {
        var client = try server.accept();
        defer client.stream.close();

        const message = try client.stream.reader().readUntilDelimiterOrEofAlloc(allocator, '\n', 1024) orelse {
            continue;
        };
        defer allocator.free(message);

        const username = std.mem.trim(u8, message, &std.ascii.whitespace);

        const plan = get_plan(allocator, username) catch |err| {
            print("got error: {any}\n", .{err});
            continue;
        };
        defer allocator.free(plan);

        _ = try client.stream.write(plan);
    }
}
