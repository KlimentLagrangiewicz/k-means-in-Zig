const std = @import("std");

pub fn readArrayFromFile(comptime T: type, filename: []const u8) ![]T {
    if (@typeInfo(T) != .float and @typeInfo(T) != .int) @compileError("Only ints and floats are accepted");
    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();
    const buffer: []u8 = try file.reader().readAllAlloc(std.heap.c_allocator, try file.getEndPos());
    defer std.heap.c_allocator.free(buffer);
    var list = std.ArrayList(T).init(std.heap.c_allocator);
    defer list.clearAndFree();
    var it = std.mem.tokenizeAny(u8, buffer, "\n ,\r");
    if (@typeInfo(T) == .int) {
        while (it.next()) |num| {
            const n = try std.fmt.parseInt(T, num, 10);
            try list.append(n);
        }
    } else {
        while (it.next()) |num| {
            const n = try std.fmt.parseFloat(T, num);
            try list.append(n);
        }
    }
    return try list.toOwnedSlice();
}

fn arrayToMatr(comptime T: type, a: []const T, n: usize, m: usize) ![][]T {
    if (a.len != n * m) return error.BadSize;
    const x: [][]T = try std.heap.c_allocator.alloc([]T, n);
    for (x) |*xi| xi.* = try std.heap.c_allocator.alloc(T, m);
    for (0..n) |i|
        for (0..m) |j| {
            x[i][j] = a[i * m + j];
        };
    return x;
}

pub fn readData(filename: []const u8, n: usize, m: usize) ![][]f64 {
    const xArr: []f64 = try readArrayFromFile(f64, filename);
    defer std.heap.c_allocator.free(xArr);
    return try arrayToMatr(f64, xArr, n, m);
}

pub fn writeResult(filename: []const u8, array: []usize) !void {
    const file = try std.fs.cwd().createFile(filename, .{});
    defer file.close();
    const writer = file.writer();
    for (array, 0..) |element, i| try writer.print("Object [{}] = {};\n", .{ i, element });
}

pub fn writeShortFullResult(filename: []const u8, array: []const usize, p: f64) !void {
    const file = try std.fs.cwd().createFile(filename, .{});
    defer file.close();
    const writer = file.writer();
    try writer.print("Precision of clustering using k-means: {d:};\n", .{p});
    for (array, 0..) |element, i| try writer.print("Object [{}] = {};\n", .{ i, element });
}

pub fn getPrecisionCoeff(x: []const usize, y: []const usize) !f64 {
    if (y.len != x.len) return error.IncomparableSize;
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
    if (x.len != y.len) return error.IncomparableSize;
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
    if (x.len != y.len) return error.IncomparableSize;
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
    if (x.len != y.len) return error.IncomparableSize;
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
    if (x.len != y.len) return error.IncomparableSize;
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
    if (x.len != y.len) return error.IncomparableSize;
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

pub fn getKulczynskiIndex(x: []const usize, y: []const usize) !f64 {
    if (x.len != y.len) return error.IncomparableSize;
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
    return if (yy == 0 and (ny == 0 or yn == 0)) 0.0 else 0.5 * ((@as(f64, @floatFromInt(yy)) / @as(f64, @floatFromInt(yy + ny)) + @as(f64, @floatFromInt(yy)) / @as(f64, @floatFromInt(yy + yn))));
}

pub fn getMcNemarIndex(x: []const usize, y: []const usize) !f64 {
    if (x.len != y.len) return error.IncomparableSize;
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
    if (x.len != y.len) return error.IncomparableSize;
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
    if (x.len != y.len or x.len < 2) return error.IncomparableSize;
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
    if (x.len != y.len) return error.IncomparableSize;
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
    if (x.len != y.len or x.len < 2) return error.IncomparableSize;
    const n: i128 = x.len;
    var yy: i128 = 0;
    for (0..@intCast(n)) |i| {
        for (i + 1..@intCast(n)) |j| yy += @intFromBool(x[i] == x[j] and y[i] == y[j]);
    }
    return @as(f64, @floatFromInt(2 * yy)) / @as(f64, @floatFromInt(n * (n - 1)));
}

pub fn getSokalSneathFirstIndex(x: []const usize, y: []const usize) !f64 {
    if (x.len != y.len) return error.IncomparableSize;
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
    if (x.len != y.len) return error.IncomparableSize;
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

pub fn getExternalIndices(x: []const usize, y: []const usize, _p: *f64, _rc: *f64, _cdi: *f64, _fmi: *f64, _hi: *f64, _ji: *f64, _ki: *f64, _mni: *f64, _phi: *f64, _rand: *f64, _rti: *f64, _rri: *f64, _s1i: *f64, _s2i: *f64) !void {
    if (x.len != y.len) {
        _p.* = 0.0;
        _rc.* = 0.0;
        _cdi.* = 0.0;
        _fmi.* = 0.0;
        _hi.* = 0.0;
        _ji.* = 0.0;
        _ki.* = 0.0;
        _mni.* = 0.0;
        _phi.* = 0.0;
        _rand.* = 0.0;
        _rti.* = 0.0;
        _rri.* = 0.0;
        _s1i.* = 0.0;
        _s2i.* = 0.0;
        return error.IncomparableSize;
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
    _ki.* = if (yy == 0 and (ny == 0 or yn == 0)) 0.0 else 0.5 * ((@as(f64, @floatFromInt(yy)) / @as(f64, @floatFromInt(yy + ny)) + @as(f64, @floatFromInt(yy)) / @as(f64, @floatFromInt(yy + yn))));
    _mni.* = if (nn == 0 and ny == 0) 0.0 else @as(f64, @floatFromInt(nn - ny)) / std.math.sqrt(@as(f64, @floatFromInt(nn + ny)));
    _phi.* = if (m == 0 or k == 0) 0.0 else @as(f64, @floatFromInt(yy * nn - yn * ny)) / std.math.sqrt(@as(f64, @floatFromInt(m * k)));
    _rand.* = if (n < 2) 0.0 else @as(f64, @floatFromInt(2 * (yy + nn))) / @as(f64, @floatFromInt(n * (n - 1)));
    _rti.* = if (yynn == 0 and yn == 0 and ny == 0) 0.0 else @as(f64, @floatFromInt(yynn)) / @as(f64, @floatFromInt(yynn + 2 * yn + 2 * ny));
    _rri.* = if (n < 2) 0.0 else @as(f64, @floatFromInt(2 * yy)) / @as(f64, @floatFromInt(n * (n - 1)));
    _s1i.* = if (yy == 0 and yn == 0 and ny == 0) 0.0 else @as(f64, @floatFromInt(yy)) / @as(f64, @floatFromInt(yy + 2 * yn + 2 * ny));
    _s2i.* = if (yynn == 0 and yn == 0 and ny == 0) 0.0 else @as(f64, @floatFromInt(yynn)) / (@as(f64, @floatFromInt(yynn)) + 0.5 * (@as(f64, @floatFromInt(yn + ny))));
}

pub fn writeFullResult(filename: []const u8, array: []const usize, p: f64, rc: f64, cdi: f64, fmi: f64, hi: f64, ji: f64, ki: f64, mni: f64, phi: f64, randi: f64, rti: f64, rri: f64, s1i: f64, s2i: f64) !void {
    const file = try std.fs.cwd().createFile(filename, .{});
    defer file.close();
    const writer = file.writer();
    try writer.print("The result of clustering using k-means:\nPrecision coefficient\t= {d:}\nRecall coefficient\t= {d:}\nCzekanowski-Dice index\t= {d:}\nFolkes-Mallows index\t= {d:}\nHubert index\t\t= {d:}\nJaccard index\t\t= {d:}\nKulczynski index\t= {d:}\nMcNemar index\t\t= {d:}\nPhi index\t\t= {d:}\nRand index\t\t= {d:}\nRogers-Tanimoto index\t= {d:}\nRussel-Rao index\t= {d:}\nSokal-Sneath I index\t= {d:}\nSokal-Sneath II index\t= {d:}\n\n", .{ p, rc, cdi, fmi, hi, ji, ki, mni, phi, randi, rti, rri, s1i, s2i });
    for (array, 0..) |element, i| try writer.print("Object [{}] = {};\n", .{ i, element });
}
