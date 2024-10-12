const std = @import("std");

fn numOfNonEmptyLines(filename: []const u8) !usize {
    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();
    const buffer: []u8 = try file.reader().readAllAlloc(std.heap.c_allocator, try file.getEndPos());
    defer std.heap.c_allocator.free(buffer);
    var lines = std.mem.splitAny(u8, buffer, "\r\n");
    var res: usize = 0;
    while (lines.next()) |line|
        res += @intFromBool(!std.mem.eql(u8, line, ""));
    return res;
}

fn getMaxWidthOfFileLines(filename: []u8) !u64 {
    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();
    const buffer: []u8 = try file.reader().readAllAlloc(std.heap.c_allocator, try file.getEndPos());
    defer std.heap.c_allocator.free(buffer);
    var max: u64 = 0;
    var cur: u64 = 0;
    for (buffer) |char| {
        if (char == '\n' or char == '\r') {
            if (cur > max) max = cur;
            cur = 0;
        } else cur += 1;
    }
    return if (cur > max) cur else max;
}

pub fn readData(filename: []u8, val_k: *usize) ![][]f64 {
    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();
    const maxSize: u64 = try getMaxWidthOfFileLines(filename) + 1;
    var it_1 = std.mem.split(u8, try file.reader().readUntilDelimiterAlloc(std.heap.c_allocator, '\n', maxSize), " ");
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
    const n_buf: usize = try numOfNonEmptyLines(filename) - 1;
    n = if (n < n_buf) n else n_buf;
    var x: [][]f64 = try std.heap.c_allocator.alloc([]f64, n);
    for (x) |*j| j.* = try std.heap.c_allocator.alloc(f64, m);
    i = 0;
    while (i < n) {
        const buf: []u8 = (try file.reader().readUntilDelimiterOrEofAlloc(std.heap.c_allocator, '\n', maxSize)).?;
        defer std.heap.c_allocator.free(buf);
        if (!std.mem.eql(u8, buf, "")) {
            var j: usize = 0;
            var it = std.mem.split(u8, buf, " ");
            while (it.next()) |part|
                if (!std.mem.eql(u8, part, "")) {
                    x[i][j] = try std.fmt.parseFloat(f64, part);
                    j += 1;
                };
            i += 1;
        }
    }
    return x;
}

pub fn writeData(filename: []const u8, array: []usize) !void {
    const file = try std.fs.cwd().createFile(filename, .{});
    defer file.close();
    const writer = file.writer();
    for (array, 0..) |element, i| try writer.print("Object [{}] = {};\n", .{ i, element });
}

pub fn getSplit(filename: []const u8) ![]usize {
    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();
    const n: usize = try numOfNonEmptyLines(filename);
    const res: []usize = try std.heap.c_allocator.alloc(usize, n);
    const buffer = try file.reader().readAllAlloc(std.heap.c_allocator, try file.getEndPos());
    defer std.heap.c_allocator.free(buffer);
    var numbers = std.mem.splitAny(u8, buffer, "\r\n");
    var i: usize = 0;
    while (numbers.next()) |number|
        if (!std.mem.eql(u8, number, "")) {
            res[i] = try std.fmt.parseInt(usize, number, 10);
            i += 1;
        };
    return res;
}

pub fn writeResult(filename: []const u8, array: []usize, p: f64) !void {
    const file = try std.fs.cwd().createFile(filename, .{});
    defer file.close();
    const writer = file.writer();
    try writer.print("Precision of clustering by k-means = {d:};\n", .{p});
    for (array, 0..) |element, i| try writer.print("Object [{}] = {};\n", .{ i, element });
}

pub fn getPrecision(y: []usize, x: []usize) !f64 {
    if (y.len != x.len) return 0.0;
    const n: usize = y.len;
    var yy: usize = 0;
    var ny: usize = 0;
    for (0..n) |i|
        for (i + 1..n) |j| {
            if (x[i] == x[j] and y[i] == y[j]) yy += 1;
            if (x[i] != x[j] and y[i] == y[j]) ny += 1;
        };
    return if (ny == 0 and yy == 0) 0.0 else @as(f64, @floatFromInt(yy)) / @as(f64, @floatFromInt(yy + ny));
}
