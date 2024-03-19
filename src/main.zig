const std = @import("std");
const kmeans = @import("k-means.zig");
const help = @import("help.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    if (args.len < 3) {
        std.debug.print("Not enough parameters...", .{});
    } else {
        var k: usize = 1;
        var x: [][]f64 = try help.read_data(&k, args[1]);
        defer {
            const n: usize = x.len;
            for (0..n) |i| {
                std.heap.c_allocator.free(x[i]);
            }
            std.heap.c_allocator.free(x);
        }
        const y: []usize = try kmeans.kmeans(x, k);
        defer std.heap.c_allocator.free(y);
        try help.write_data(y, args[2]);
    }
}
