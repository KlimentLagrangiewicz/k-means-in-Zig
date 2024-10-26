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

pub fn writeResult(filename: []const u8, array: []usize) !void {
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

pub fn writeShortFullResult(filename: []const u8, array: []const usize, p: f64) !void {
    const file = try std.fs.cwd().createFile(filename, .{});
    defer file.close();
    const writer = file.writer();
    try writer.print("Precision of clustering using k-means: {d:};\n", .{p});
    for (array, 0..) |element, i| try writer.print("Object [{}] = {};\n", .{ i, element });
}

pub fn getPrecisionCoeff(x: []const usize, y: []const usize) !f64 {
    if (y.len != x.len) return 0.0;
    const n: usize = x.len;
    var yy: i128 = 0;
    var ny: i128 = 0;
    for (0..n) |i|
        for (i + 1..n) |j| {
            if (x[i] == x[j] and y[i] == y[j]) yy += 1;
            if (x[i] != x[j] and y[i] == y[j]) ny += 1;
        };
    return if (ny == 0 and yy == 0) 0.0 else @as(f64, @floatFromInt(yy)) / @as(f64, @floatFromInt(yy + ny));
}

pub fn getRecallCoeff(x: []const usize, y: []const usize) !f64 {
    if (x.len != y.len) return 0.0;
    const n: usize = x.len;
    var yy: i128 = 0;
    var yn: i128 = 0;
    for (0..n) |i|
        for (i + 1..n) |j| {
            if (x[i] == x[j] and y[i] == y[j]) yy += 1;
            if (x[i] == x[j] and y[i] != y[j]) yn += 1;
        };
    return if (yy == 0 and yn == 0) 0.0 else @as(f64, @floatFromInt(yy)) / @as(f64, @floatFromInt(yy + yn));
}

pub fn getCzekanowskiDiceIndex(x: []const usize, y: []const usize) !f64 {
    if (x.len != y.len) return 0.0;
    const n: usize = x.len;
    var yy: i128 = 0;
    var yn: i128 = 0;
    var ny: i128 = 0;
    for (0..n) |i|
        for (i + 1..n) |j| {
            if (x[i] == x[j] and y[i] == y[j]) yy += 1;
            if (x[i] != x[j] and y[i] == y[j]) ny += 1;
            if (x[i] == x[j] and y[i] != y[j]) yn += 1;
        };
    return if (yy == 0 and yn == 0 and ny == 0) 0.0 else @as(f64, @floatFromInt(2 * yy)) / @as(f64, @floatFromInt(2 * yy + yn + ny));
}

pub fn getFolkesMallowsIndex(x: []const usize, y: []const usize) !f64 {
    if (x.len != y.len) return 0.0;
    const n: usize = x.len;
    var yy: i128 = 0;
    var yn: i128 = 0;
    var ny: i128 = 0;
    for (0..n) |i|
        for (i + 1..n) |j| {
            if (x[i] == x[j] and y[i] == y[j]) yy += 1;
            if (x[i] != x[j] and y[i] == y[j]) ny += 1;
            if (x[i] == x[j] and y[i] != y[j]) yn += 1;
        };
    return if (yy == 0 and (yn == 0 or ny == 0)) 0.0 else @as(f64, @floatFromInt(yy)) / std.math.sqrt(@as(f64, @floatFromInt((yy + yn) * (yy + ny))));
}

pub fn getHubertIndex(x: []const usize, y: []const usize) !f64 {
    if (x.len != y.len) return 0.0;
    const n: i128 = x.len;
    var yy: i128 = 0;
    var yn: i128 = 0;
    var ny: i128 = 0;
    var nn: i128 = 0;
    for (0..@intCast(n)) |i|
        for (i + 1..@intCast(n)) |j| {
            if (x[i] == x[j] and y[i] == y[j]) yy += 1;
            if (x[i] != x[j] and y[i] == y[j]) ny += 1;
            if (x[i] == x[j] and y[i] != y[j]) yn += 1;
            if (x[i] != x[j] and y[i] != y[j]) nn += 1;
        };
    const m: i128 = (yy + yn) * (yy + ny);
    return if (m == 0 or nn == 0 and (yn == 0 or ny == 0)) 0.0 else 0.5 * @as(f64, @floatFromInt(n * (n - 1) * yy - m)) / std.math.sqrt(@as(f64, @floatFromInt(m * (nn + yn) * (nn + ny))));
}

pub fn getJaccardIndex(x: []const usize, y: []const usize) !f64 {
    if (x.len != y.len) return 0.0;
    const n: usize = x.len;
    var yy: i128 = 0;
    var yn: i128 = 0;
    var ny: i128 = 0;
    for (0..n) |i|
        for (i + 1..n) |j| {
            if (x[i] == x[j] and y[i] == y[j]) yy += 1;
            if (x[i] != x[j] and y[i] == y[j]) ny += 1;
            if (x[i] == x[j] and y[i] != y[j]) yn += 1;
        };
    return if (yy == 0 and yn == 0 and ny == 0) 0.0 else @as(f64, @floatFromInt(yy)) / @as(f64, @floatFromInt(yy + yn + ny));
}

pub fn getMcNemarIndex(x: []const usize, y: []const usize) !f64 {
    if (x.len != y.len) return 0.0;
    const n: usize = x.len;
    var nn: i128 = 0;
    var ny: i128 = 0;
    for (0..n) |i|
        for (i + 1..n) |j| {
            if (x[i] != x[j] and y[i] == y[j]) ny += 1;
            if (x[i] != x[j] and y[i] != y[j]) nn += 1;
        };
    return if (nn == 0 and ny == 0) 0.0 else @as(f64, @floatFromInt(nn - ny)) / std.math.sqrt(@as(f64, @floatFromInt(nn + ny)));
}

pub fn getPhiIndex(x: []const usize, y: []const usize) !f64 {
    if (x.len != y.len) return 0.0;
    const n: usize = x.len;
    var yy: i128 = 0;
    var yn: i128 = 0;
    var ny: i128 = 0;
    var nn: i128 = 0;
    for (0..n) |i|
        for (i + 1..n) |j| {
            if (x[i] == x[j] and y[i] == y[j]) yy += 1;
            if (x[i] != x[j] and y[i] == y[j]) ny += 1;
            if (x[i] == x[j] and y[i] != y[j]) yn += 1;
            if (x[i] != x[j] and y[i] != y[j]) nn += 1;
        };
    const m: i128 = (yy + yn) * (yy + ny);
    const k: i128 = (nn + yn) * (nn + ny);
    return if (m == 0 or k == 0) 0.0 else @as(f64, @floatFromInt(yy * nn - yn * ny)) / std.math.sqrt(@as(f64, @floatFromInt(m * k)));
}

pub fn getRandIndex(x: []const usize, y: []const usize) !f64 {
    if (x.len != y.len or x.len < 2) return 0.0;
    const n: i128 = x.len;
    var yy: i128 = 0;
    var nn: i128 = 0;
    for (0..@intCast(n)) |i|
        for (i + 1..@intCast(n)) |j| {
            if (x[i] == x[j] and y[i] == y[j]) yy += 1;
            if (x[i] != x[j] and y[i] != y[j]) nn += 1;
        };
    return @as(f64, @floatFromInt(2 * (yy + nn))) / @as(f64, @floatFromInt(n * (n - 1)));
}

pub fn getRogersTanimotoIndex(x: []const usize, y: []const usize) !f64 {
    if (x.len != y.len) return 0.0;
    const n: i128 = x.len;
    var yy: i128 = 0;
    var yn: i128 = 0;
    var ny: i128 = 0;
    var nn: i128 = 0;
    for (0..@intCast(n)) |i|
        for (i + 1..@intCast(n)) |j| {
            if (x[i] == x[j] and y[i] == y[j]) yy += 1;
            if (x[i] != x[j] and y[i] == y[j]) ny += 1;
            if (x[i] == x[j] and y[i] != y[j]) yn += 1;
            if (x[i] != x[j] and y[i] != y[j]) nn += 1;
        };
    const yynn: i128 = yy + nn;
    return if (yynn == 0 and yn == 0 and ny == 0) 0.0 else @as(f64, @floatFromInt(yynn)) / @as(f64, @floatFromInt(yynn + 2 * yn + 2 * ny));
}

pub fn getRusselRaoIndex(x: []const usize, y: []const usize) !f64 {
    if (x.len != y.len or x.len < 2) return 0.0;
    const n: i128 = x.len;
    var yy: i128 = 0;
    for (0..@intCast(n)) |i| {
        for (i + 1..@intCast(n)) |j| yy += @intFromBool(x[i] == x[j] and y[i] == y[j]);
    }
    return @as(f64, @floatFromInt(2 * yy)) / @as(f64, @floatFromInt(n * (n - 1)));
}

pub fn getSokalSneathFirstIndex(x: []const usize, y: []const usize) !f64 {
    if (x.len != y.len) return 0.0;
    const n: usize = x.len;
    var yy: i128 = 0;
    var yn: i128 = 0;
    var ny: i128 = 0;
    for (0..n) |i|
        for (i + 1..n) |j| {
            if (x[i] == x[j] and y[i] == y[j]) yy += 1;
            if (x[i] != x[j] and y[i] == y[j]) ny += 1;
            if (x[i] == x[j] and y[i] != y[j]) yn += 1;
        };
    return if (yy == 0 and yn == 0 and ny == 0) 0.0 else @as(f64, @floatFromInt(yy)) / @as(f64, @floatFromInt(yy + 2 * yn + 2 * ny));
}

pub fn getSokalSneathSecondIndex(x: []const usize, y: []const usize) !f64 {
    if (x.len != y.len) return 0.0;
    const n: usize = x.len;
    var yy: i128 = 0;
    var yn: i128 = 0;
    var ny: i128 = 0;
    var nn: i128 = 0;
    for (0..n) |i|
        for (i + 1..n) |j| {
            if (x[i] == x[j] and y[i] == y[j]) yy += 1;
            if (x[i] != x[j] and y[i] == y[j]) ny += 1;
            if (x[i] == x[j] and y[i] != y[j]) yn += 1;
            if (x[i] != x[j] and y[i] != y[j]) nn += 1;
        };
    const yynn: i128 = yy + nn;
    return if (yynn == 0 and yn == 0 and ny == 0) 0.0 else @as(f64, @floatFromInt(yynn)) / (@as(f64, @floatFromInt(yynn)) + 0.5 * (@as(f64, @floatFromInt(yn + ny))));
}

pub fn getExternalIndices(x: []const usize, y: []const usize, _p: *f64, _rc: *f64, _cdi: *f64, _fmi: *f64, _hi: *f64, _ji: *f64, _mni: *f64, _phi: *f64, _rand: *f64, _rti: *f64, _rri: *f64, _s1i: *f64, _s2i: *f64) !void {
    if (x.len != y.len) {
        _p.* = 0.0;
        _rc.* = 0.0;
        _cdi.* = 0.0;
        _fmi.* = 0.0;
        _hi.* = 0.0;
        _ji.* = 0.0;
        _mni.* = 0.0;
        _phi.* = 0.0;
        _rand.* = 0.0;
        _rti.* = 0.0;
        _rri.* = 0.0;
        _s1i.* = 0.0;
        _s2i.* = 0.0;
        return;
    }
    const n: i128 = x.len;
    var yy: i128 = 0;
    var yn: i128 = 0;
    var ny: i128 = 0;
    var nn: i128 = 0;
    for (0..@intCast(n)) |i|
        for (i + 1..@intCast(n)) |j| {
            if (x[i] == x[j] and y[i] == y[j]) yy += 1;
            if (x[i] != x[j] and y[i] == y[j]) ny += 1;
            if (x[i] == x[j] and y[i] != y[j]) yn += 1;
            if (x[i] != x[j] and y[i] != y[j]) nn += 1;
        };
    const yynn: i128 = yy + nn;
    const m: i128 = (yy + yn) * (yy + ny);
    const k: i128 = (nn + yn) * (nn + ny);
    _p.* = if (ny == 0 and yy == 0) 0.0 else @as(f64, @floatFromInt(yy)) / @as(f64, @floatFromInt(yy + ny));
    _rc.* = if (yy == 0 and yn == 0) 0.0 else @as(f64, @floatFromInt(yy)) / @as(f64, @floatFromInt(yy + yn));
    _cdi.* = if (yy == 0 and yn == 0 and ny == 0) 0.0 else @as(f64, @floatFromInt(2 * yy)) / @as(f64, @floatFromInt(2 * yy + yn + ny));
    _fmi.* = if (yy == 0 and (yn == 0 or ny == 0)) 0.0 else @as(f64, @floatFromInt(yy)) / std.math.sqrt(@as(f64, @floatFromInt(m)));
    _hi.* = if (m == 0 or nn == 0 and (yn == 0 or ny == 0)) 0.0 else 0.5 * @as(f64, @floatFromInt(n * (n - 1) * yy - m)) / std.math.sqrt(@as(f64, @floatFromInt(m * k)));
    _ji.* = if (yy == 0 and yn == 0 and ny == 0) 0.0 else @as(f64, @floatFromInt(yy)) / @as(f64, @floatFromInt(yy + yn + ny));
    _mni.* = if (nn == 0 and ny == 0) 0.0 else @as(f64, @floatFromInt(nn - ny)) / std.math.sqrt(@as(f64, @floatFromInt(nn + ny)));
    _phi.* = if (m == 0 or k == 0) 0.0 else @as(f64, @floatFromInt(yy * nn - yn * ny)) / std.math.sqrt(@as(f64, @floatFromInt(m * k)));
    _rand.* = if (n < 2) 0.0 else @as(f64, @floatFromInt(2 * (yy + nn))) / @as(f64, @floatFromInt(n * (n - 1)));
    _rti.* = if (yynn == 0 and yn == 0 and ny == 0) 0.0 else @as(f64, @floatFromInt(yynn)) / @as(f64, @floatFromInt(yynn + 2 * yn + 2 * ny));
    _rri.* = if (n < 2) 0.0 else @as(f64, @floatFromInt(2 * yy)) / @as(f64, @floatFromInt(n * (n - 1)));
    _s1i.* = if (yy == 0 and yn == 0 and ny == 0) 0.0 else @as(f64, @floatFromInt(yy)) / @as(f64, @floatFromInt(yy + 2 * yn + 2 * ny));
    _s2i.* = if (yynn == 0 and yn == 0 and ny == 0) 0.0 else @as(f64, @floatFromInt(yynn)) / (@as(f64, @floatFromInt(yynn)) + 0.5 * (@as(f64, @floatFromInt(yn + ny))));
}

pub fn writeFullResult(filename: []const u8, array: []const usize, p: f64, rc: f64, cdi: f64, fmi: f64, hi: f64, ji: f64, mni: f64, phi: f64, randi: f64, rti: f64, rri: f64, s1i: f64, s2i: f64) !void {
    const file = try std.fs.cwd().createFile(filename, .{});
    defer file.close();
    const writer = file.writer();
    try writer.print("The result of clustering using k-means:\nPrecision coefficient\t= {d:}\nRecall coefficient\t\t= {d:}\nCzekanowski-Dice index\t= {d:}\nFolkes-Mallows index\t= {d:}\nHubert index\t\t\t= {d:}\nJaccard index\t\t\t= {d:}\nMcNemar index\t\t\t= {d:}\nPhi index\t\t\t\t= {d:}\nRand index\t\t\t\t= {d:}\nRogers-Tanimoto indext\t= {d:}\nRussel-Rao index\t\t= {d:}\nSokal-Sneath I index\t= {d:}\nSokal-Sneath II index\t= {d:}\n\n", .{ p, rc, cdi, fmi, hi, ji, mni, phi, randi, rti, rri, s1i, s2i });
    for (array, 0..) |element, i| try writer.print("Object [{}] = {};\n", .{ i, element });
}
