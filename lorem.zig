const std = @import("std");
const Allocator = std.mem.Allocator;

fn concat(allocator: Allocator, a: []const u8, b: []const u8) ![]u8 {
    const result = try allocator.alloc(u8, a.len + b.len);
    @memcpy(result[0..a.len], a);
    @memcpy(result[a.len..], b);

    return result;
}

fn generate(allocator: std.mem.Allocator, num: usize, is_first: bool) ![]const u8 {
    const words = [_][]const u8{ "alias", "consequatur", "aut", "perferendis", "sit", "voluptatem", "accusantium", "doloremque", "aperiam", "eaque", "ipsa", "quae", "ab", "illo", "inventore", "veritatis", "et", "quasi", "architecto", "beatae", "vitae", "dicta", "sunt", "explicabo", "aspernatur", "aut", "odit", "aut", "fugit", "sed", "quia", "consequuntur", "magni", "dolores", "eos", "qui", "ratione", "voluptatem", "sequi", "nesciunt", "neque", "dolorem", "ipsum", "quia", "dolor", "sit", "amet", "consectetur", "adipisci", "velit", "sed", "quia", "non", "numquam", "eius", "modi", "tempora", "incidunt", "ut", "labore", "et", "dolore", "magnam", "aliquam", "quaerat", "voluptatem", "ut", "enim", "ad", "minima", "veniam", "quis", "nostrum", "exercitationem", "ullam", "corporis", "nemo", "enim", "ipsam", "voluptatem", "quia", "voluptas", "sit", "suscipit", "laboriosam", "nisi", "ut", "aliquid", "ex", "ea", "commodi", "consequatur", "quis", "autem", "vel", "eum", "iure", "reprehenderit", "qui", "in", "ea", "voluptate", "velit", "esse", "quam", "nihil", "molestiae", "et", "iusto", "odio", "dignissimos", "ducimus", "qui", "blanditiis", "praesentium", "laudantium", "totam", "rem", "voluptatum", "deleniti", "atque", "corrupti", "quos", "dolores", "et", "quas", "molestias", "excepturi", "sint", "occaecati", "cupiditate", "non", "provident", "sed", "ut", "perspiciatis", "unde", "omnis", "iste", "natus", "error", "similique", "sunt", "in", "culpa", "qui", "officia", "deserunt", "mollitia", "animi", "id", "est", "laborum", "et", "dolorum", "fuga", "et", "harum", "quidem", "rerum", "facilis", "est", "et", "expedita", "distinctio", "nam", "libero", "tempore", "cum", "soluta", "nobis", "est", "eligendi", "optio", "cumque", "nihil", "impedit", "quo", "porro", "quisquam", "est", "qui", "minus", "id", "quod", "maxime", "placeat", "facere", "possimus", "omnis", "voluptas", "assumenda", "est", "omnis", "dolor", "repellendus", "temporibus", "autem", "quibusdam", "et", "aut", "consequatur", "vel", "illum", "qui", "dolorem", "eum", "fugiat", "quo", "voluptas", "nulla", "pariatur", "at", "vero", "eos", "et", "accusamus", "officiis", "debitis", "aut", "rerum", "necessitatibus", "saepe", "eveniet", "ut", "et", "voluptates", "repudiandae", "sint", "et", "molestiae", "non", "recusandae", "itaque", "earum", "rerum", "hic", "tenetur", "a", "sapiente", "delectus", "ut", "aut", "reiciendis", "voluptatibus", "maiores", "doloribus", "asperiores", "repellat" };
    var str: []u8 = try allocator.dupe(u8, if (is_first) "Lorem ipsum" else "");

    var prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const rand = prng.random();

    var it = num;
    if (is_first and it > 2) {
        // remove initial "Lorem ipsum"
        it -= 2;
    }

    while (it > 0) : (it -= 1) {
        const new_str1 = try concat(allocator, str, if (it != num) " " else "");
        allocator.free(str);
        str = try concat(allocator, new_str1, words[rand.int(u32) % words.len]);
        allocator.free(new_str1);
    }
    defer allocator.free(str);

    // uppercase all sentences
    str[0] = std.ascii.toUpper(str[0]);

    return try concat(allocator, str, ".\n");
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    var tokens: usize = 42;
    var paragraphs: usize = 1;
    var is_first = true;

    if (std.os.argv.len > 1) {
        tokens = try std.fmt.parseInt(usize, std.mem.span(std.os.argv[1]), 10);
    }
    if (std.os.argv.len > 2) {
        paragraphs = try std.fmt.parseInt(usize, std.mem.span(std.os.argv[2]), 10);
    }

    while (paragraphs > 0) : (paragraphs -= 1) {
        const li = try generate(allocator, tokens, is_first);
        defer allocator.free(li);

        const stdout = std.io.getStdOut().writer();

        try stdout.print("{s}", .{li});

        if (paragraphs > 1) {
            try stdout.print("\n", .{});
        }
        is_first = false;
    }
}
