const std = @import("std");

pub fn readData(file_name: []u8, val_k: *usize) ![][]f64 {
    const file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();
    var it_1 = std.mem.split(u8, try file.reader().readUntilDelimiterAlloc(std.heap.c_allocator, '\n', 2048), " ");
    var i: usize = 0;
    var n: usize = undefined;
    var m: usize = undefined;
    var k: usize = undefined;
    while (it_1.next()) |part| {
        if (i == 0) n = try std.fmt.parseInt(usize, part, 10);
        if (i == 1) m = try std.fmt.parseInt(usize, part, 10);
        if (i == 2) k = try std.fmt.parseInt(usize, part, 10);
        i += 1;
    }
    val_k.* = k;
    var x: [][]f64 = try std.heap.c_allocator.alloc([]f64, n);
    for (0..n) |j| x[j] = try std.heap.c_allocator.alloc(f64, m);
    i = 0;
    while (i < n) {
        var j: usize = 0;
        var it = std.mem.split(u8, try file.reader().readUntilDelimiterAlloc(std.heap.c_allocator, '\n', 2048), " ");
        while (it.next()) |part| {
            if (j < m) x[i][j] = try std.fmt.parseFloat(f64, part);
            j += 1;
        }
        i += 1;
    }
    return x;
}

pub fn writeData(filename: []const u8, array: []usize) !void {
    var file = try std.fs.cwd().createFile(filename, .{});
    defer file.close();
    var writer = file.writer();
    var i: usize = 1;
    for (array) |element| {
        try writer.print("Object [{}] = {};\n", .{ i, element });
        i += 1;
    }
}

fn numOfLines(filename: []const u8) !usize {
    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();
    var count: usize = 1;
    var flag: bool = true;
    const val: []u8 = try std.heap.c_allocator.alloc(u8, 3);
    defer std.heap.c_allocator.free(val);
    val[0] = 'n';
    val[1] = 'a';
    val[2] = 'n';
    while (flag) {
        const line: []u8 = file.reader().readUntilDelimiterAlloc(std.heap.page_allocator, '\n', 1024) catch val;
        if (std.mem.eql(u8, line, val)) flag = false else if (line.len != 0) count += 1;
    }
    return count;
}

pub fn getSplit(filename: []const u8) ![]usize {
    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();
    const val: []u8 = try std.heap.c_allocator.alloc(u8, 3);
    defer std.heap.c_allocator.free(val);
    val[0] = 'n';
    val[1] = 'a';
    val[2] = 'n';
    const n: usize = try numOfLines(filename);
    const res: []usize = try std.heap.c_allocator.alloc(usize, n);
    var i: usize = 0;
    var flag: bool = true;
    while (flag) {
        const line: []u8 = file.reader().readUntilDelimiterAlloc(std.heap.page_allocator, '\n', 1024) catch val;
        if (std.mem.eql(u8, line, val)) {
            flag = false;
        } else {
            if (line.len != 0) {
                res[i] = try std.fmt.parseInt(usize, line, 10);
                i += 1;
            }
        }
    }
    return res;
}

pub fn writeResult(filename: []const u8, array: []usize, p: f64) !void {
    var file = try std.fs.cwd().createFile(filename, .{});
    defer file.close();
    var writer = file.writer();
    try writer.print("Precision of clustering by k-means = {d:};\n", .{p});
    var i: usize = 1;
    for (array) |element| {
        try writer.print("Object [{}] = {};\n", .{ i, element });
        i += 1;
    }
}

pub fn getPrecision(y: []usize, x: []usize) !f64 {
    if (y.len != x.len) return 0.0;
    const n: usize = y.len;
    var yy: usize = 0;
    var ny: usize = 0;
    for (0..n) |i| {
        for (i + 1..n) |j| {
            if (x[i] == x[j] and y[i] == y[j]) yy += 1;
            if (x[i] != x[j] and y[i] == y[j]) ny += 1;
        }
    }
    return if (ny == 0 and yy == 0) 0.0 else @as(f64, @floatFromInt(yy)) / @as(f64, @floatFromInt(yy + ny));
}
