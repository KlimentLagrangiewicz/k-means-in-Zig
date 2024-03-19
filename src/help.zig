const std = @import("std");

pub fn read_data(val_k: *usize, file_name: []u8) ![][]f64 {
    const file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();
    var it_1 = std.mem.split(u8, try file.reader().readUntilDelimiterAlloc(std.heap.c_allocator, '\n', 2048), " ");
    var i: usize = 0;
    var n: usize = undefined;
    var m: usize = undefined;
    var k: usize = undefined;
    while (it_1.next()) |part| {
        if (i == 0) {
            n = try std.fmt.parseInt(usize, part, 10);
        }
        if (i == 1) {
            m = try std.fmt.parseInt(usize, part, 10);
        }
        if (i == 2) {
            k = try std.fmt.parseInt(usize, part, 10);
        }
        i += 1;
    }
    val_k.* = k;
    var x: [][]f64 = try std.heap.c_allocator.alloc([]f64, n);
    for (0..n) |j| {
        x[j] = try std.heap.c_allocator.alloc(f64, m);
    }
    i = 0;
    while (i < n) {
        var j: usize = 0;
        var it = std.mem.split(u8, try file.reader().readUntilDelimiterAlloc(std.heap.c_allocator, '\n', 2048), " ");
        while (it.next()) |part| {
            if (j < m) {
                x[i][j] = try std.fmt.parseFloat(f64, part);
            }
            j += 1;
        }
        i += 1;
    }
    return x;
}

pub fn write_data(array: []usize, path: []const u8) !void {
    var file = try std.fs.cwd().createFile(path, .{});
    defer file.close();
    var writer = file.writer();
    var i: usize = 1;
    for (array) |element| {
        try writer.print("Object [{}] = {} cluster;\n", .{ i, element });
        i += 1;
    }
}
