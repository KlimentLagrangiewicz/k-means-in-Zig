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
        std.debug.print("Not enough parameters\n", .{});
    } else {
        var k: usize = 1;
        const x: [][]f64 = try help.readData(args[1], &k);
        defer {
            const n: usize = x.len;
            for (0..n) |i| std.heap.c_allocator.free(x[i]);
            std.heap.c_allocator.free(x);
        }
        const y: []usize = try kmeans.kmeans(x, k);
        defer std.heap.c_allocator.free(y);
        if (args.len > 3) {
            const perfect: []usize = try help.getSplit(args[3]);
            defer std.heap.c_allocator.free(perfect);
            const p: f64 = try help.getPrecision(perfect, y);
            std.debug.print("Precision of clustering by k-means = {d:}\n", .{p});
            try help.writeResult(args[2], y, p);
        } else try help.writeData(args[2], y);
    }
}
