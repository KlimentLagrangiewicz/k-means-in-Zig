const std = @import("std");

pub fn readArrayFromFile(comptime T: type, file_name: []const u8, allocator: std.mem.Allocator) ![]T {
    if (@typeInfo(T) != .float and @typeInfo(T) != .int) @compileError("Only ints and floats are accepted");
    const file = std.fs.cwd().openFile(file_name, .{}) catch |err| {
        try std.io.getStdOut().writer().print("Error during opening `{s}` file: {s}\n", .{ file_name, @errorName(err) });
        return err;
    };
    defer file.close();

    var buffered_reader = std.io.bufferedReader(file.reader());
    const reader = buffered_reader.reader();
    var line_buffer = std.ArrayList(u8).init(allocator);
    defer line_buffer.deinit();

    var res = std.ArrayList(T).init(allocator);
    defer res.deinit();
    if (@typeInfo(T) == .int) {
        while (reader.streamUntilDelimiter(line_buffer.writer(), '\n', null)) {
            const line = line_buffer.items;
            if (line.len != 0) {
                var line_iterator = std.mem.tokenizeAny(u8, line, ", \n\r\t\u{feff}");
                while (line_iterator.next()) |token| {
                    if (token.len != 0) {
                        const n = try std.fmt.parseInt(T, token, 10);
                        try res.append(n);
                    }
                }
            }
            line_buffer.clearRetainingCapacity();
        } else |err| switch (err) {
            error.EndOfStream => {
                if (line_buffer.items.len > 0) {
                    const line = line_buffer.items;
                    if (line.len != 0) {
                        var line_iterator = std.mem.tokenizeAny(u8, line, ", \n\r\t\u{feff}");
                        while (line_iterator.next()) |token| {
                            if (token.len != 0) {
                                const n = try std.fmt.parseInt(T, token, 10);
                                try res.append(n);
                            }
                        }
                    }
                    line_buffer.clearRetainingCapacity();
                }
            },
            else => return err,
        }
    } else {
        while (reader.streamUntilDelimiter(line_buffer.writer(), '\n', null)) {
            const line = line_buffer.items;
            if (line.len != 0) {
                var line_iterator = std.mem.tokenizeAny(u8, line, ", \n\r\t\u{feff}");
                while (line_iterator.next()) |token| {
                    if (token.len != 0) {
                        const n = try std.fmt.parseFloat(T, token);
                        try res.append(n);
                    }
                }
            }
            line_buffer.clearRetainingCapacity();
        } else |err| switch (err) {
            error.EndOfStream => {
                if (line_buffer.items.len > 0) {
                    const line = line_buffer.items;
                    if (line.len != 0) {
                        var line_iterator = std.mem.tokenizeAny(u8, line, ", \n\r\t\u{feff}");
                        while (line_iterator.next()) |token| {
                            if (token.len != 0) {
                                const n = try std.fmt.parseFloat(T, token);
                                try res.append(n);
                            }
                        }
                    }
                    line_buffer.clearRetainingCapacity();
                }
            },
            else => return err,
        }
    }
    return try res.toOwnedSlice();
}

pub fn readMatrFromCSV(file_name: []const u8, allocator: std.mem.Allocator) !std.ArrayList(std.ArrayList(std.ArrayList(u8))) {
    const file = std.fs.cwd().openFile(file_name, .{}) catch |err| {
        try std.io.getStdOut().writer().print("Error during opening `{s}` file: {s}\n", .{ file_name, @errorName(err) });
        return err;
    };
    defer file.close();

    var buffered_reader = std.io.bufferedReader(file.reader());
    const reader = buffered_reader.reader();
    var line_buffer = std.ArrayList(u8).init(allocator);
    defer line_buffer.deinit();

    var matr = std.ArrayList(std.ArrayList(std.ArrayList(u8))).init(allocator);

    while (reader.streamUntilDelimiter(line_buffer.writer(), '\n', null)) {
        var row = std.ArrayList(std.ArrayList(u8)).init(allocator);
        defer row.deinit();

        const line = line_buffer.items;
        if (line.len != 0) {
            var line_iterator = std.mem.tokenizeAny(u8, line, ", \n\r\t\u{feff}");

            while (line_iterator.next()) |token| {
                if (token.len != 0) {
                    var elem = try std.ArrayList(u8).initCapacity(allocator, token.len);
                    defer elem.deinit();
                    try elem.appendSlice(token);
                    try row.append(try elem.clone());
                }
            }
            try matr.append(try row.clone());
        }

        line_buffer.clearRetainingCapacity();
    } else |err| switch (err) {
        error.EndOfStream => {
            if (line_buffer.items.len > 0) {
                var row = std.ArrayList(std.ArrayList(u8)).init(allocator);
                defer row.deinit();

                const line = line_buffer.items;
                if (line.len != 0) {
                    var line_iterator = std.mem.tokenizeAny(u8, line, ", \n\r\t\u{feff}");

                    while (line_iterator.next()) |token| {
                        if (token.len != 0) {
                            var elem = try std.ArrayList(u8).initCapacity(allocator, token.len);
                            defer elem.deinit();
                            try elem.appendSlice(token);
                            try row.append(try elem.clone());
                        }
                    }
                    try matr.append(try row.clone());
                }
                line_buffer.clearRetainingCapacity();
            }
        },
        else => return err,
    }
    return matr;
}

pub fn allRowsHaveEqualLength(comptime T: type, list: std.ArrayList(std.ArrayList(T))) bool {
    if (list.items.len < 2) return true;

    const items = list.items;
    const first_len = items[0].items.len;
    for (items[1..]) |item| {
        if (item.items.len != first_len) return false;
    }
    return true;
}

fn getMatrFromStrMatr(comptime T: type, str_matr: std.ArrayList(std.ArrayList(std.ArrayList(u8))), allocator: std.mem.Allocator) ![][]T {
    if (@typeInfo(T) != .float and @typeInfo(T) != .int) @compileError("Only ints and floats are accepted as elements of matrix");
    if (!allRowsHaveEqualLength(std.ArrayList(u8), str_matr)) return error.notRectMatr;
    const n = str_matr.items.len;
    const m = str_matr.items[0].items.len;
    const x: [][]T = try allocator.alloc([]T, n);
    for (x) |*xi| xi.* = try allocator.alloc(T, m);
    if (@typeInfo(T) == .int) {
        for (0..n) |i|
            for (0..m) |j| {
                const el = str_matr.items[i].items[j].items;
                x[i][j] = try std.fmt.parseInt(T, el, 10);
            };
    } else {
        for (0..n) |i|
            for (0..m) |j| {
                const el = str_matr.items[i].items[j].items;
                x[i][j] = try std.fmt.parseFloat(T, el);
            };
    }

    return x;
}

pub fn readData(file_name: []const u8, allocator: std.mem.Allocator) ![][]f64 {
    const x_str = try readMatrFromCSV(file_name, allocator);
    defer {
        for (x_str.items) |*xi| {
            for ((xi.*).items) |*xij| {
                xij.deinit();
            }
            xi.deinit();
        }
        x_str.deinit();
    }
    return try getMatrFromStrMatr(f64, x_str, allocator);
}

pub fn writeResult(file_name: []const u8, array: []usize) !void {
    const file = try std.fs.cwd().createFile(file_name, .{});
    defer file.close();
    const writer = file.writer();
    try writer.print("i, y_i\n", .{});
    for (array, 1..) |element, i| try writer.print("{}, {}\n", .{ i, element });
}

pub fn writeShortFullResult(file_name: []const u8, array: []const usize, p: f64) !void {
    const file = try std.fs.cwd().createFile(file_name, .{});
    defer file.close();
    const writer = file.writer();
    try writer.print("Precision of clustering using k-means, {d:}\ni, y_i\n", .{p});
    for (array, 1..) |element, i| try writer.print("{}, {}\n", .{ i, element });
}

// x is reference partition, y is obtained partition
pub fn getPrecisionCoeff(x: []const usize, y: []const usize) !f64 {
    if (y.len != x.len) return error.IncomparableSize;
    const n: usize = x.len;
    var yy: usize = 0;
    var ny: usize = 0;
    for (0..n) |i| {
        const xi = x[i];
        const yi = y[i];
        for (i + 1..n) |j| {
            if (xi == x[j] and yi == y[j]) yy += 1;
            if (xi != x[j] and yi == y[j]) ny += 1;
        }
    }
    // c = yy / (yy + ny)
    return if (ny == 0 and yy == 0) 0.0 else @as(f64, @floatFromInt(yy)) / (@as(f64, @floatFromInt(yy)) + @as(f64, @floatFromInt(ny)));
}

// x is reference partition, y is obtained partition
pub fn getRecallCoeff(x: []const usize, y: []const usize) !f64 {
    if (x.len != y.len) return error.IncomparableSize;
    const n: usize = x.len;
    var yy: usize = 0;
    var yn: usize = 0;
    for (0..n) |i| {
        const xi = x[i];
        const yi = y[i];
        for (i + 1..n) |j| {
            if (xi == x[j] and yi == y[j]) yy += 1;
            if (xi == x[j] and yi != y[j]) yn += 1;
        }
    }
    // c = yy / (yy + yn)
    return if (yy == 0 and yn == 0) 0.0 else @as(f64, @floatFromInt(yy)) / (@as(f64, @floatFromInt(yy)) + @as(f64, @floatFromInt(yn)));
}

// x is reference partition, y is obtained partition
pub fn getCzekanowskiDiceIndex(x: []const usize, y: []const usize) !f64 {
    if (x.len != y.len) return error.IncomparableSize;
    const n: usize = x.len;
    var yy: usize = 0;
    var yn: usize = 0;
    var ny: usize = 0;
    for (0..n) |i| {
        const xi = x[i];
        const yi = y[i];
        for (i + 1..n) |j| {
            if (xi == x[j] and yi == y[j]) yy += 1;
            if (xi != x[j] and yi == y[j]) ny += 1;
            if (xi == x[j] and yi != y[j]) yn += 1;
        }
    }
    // c = 2yy / (2yy + yn + ny)
    return if (yy == 0 and yn == 0 and ny == 0) 0.0 else 2.0 * @as(f64, @floatFromInt(yy)) / (2.0 * @as(f64, @floatFromInt(yy)) + @as(f64, @floatFromInt(yn)) + @as(f64, @floatFromInt(ny)));
}

// x is reference partition, y is obtained partition
pub fn getFolkesMallowsIndex(x: []const usize, y: []const usize) !f64 {
    if (x.len != y.len) return error.IncomparableSize;
    const n: usize = x.len;
    var yy: usize = 0;
    var yn: usize = 0;
    var ny: usize = 0;
    for (0..n) |i| {
        const xi = x[i];
        const yi = y[i];
        for (i + 1..n) |j| {
            if (xi == x[j] and yi == y[j]) yy += 1;
            if (xi != x[j] and yi == y[j]) ny += 1;
            if (xi == x[j] and yi != y[j]) yn += 1;
        }
    }
    // c = yy / sqrt( (yy + yn)(yy + ny) )
    return if (yy == 0 and (yn == 0 or ny == 0)) 0.0 else @as(f64, @floatFromInt(yy)) / std.math.sqrt((@as(f64, @floatFromInt(yy)) + @as(f64, @floatFromInt(yn))) * (@as(f64, @floatFromInt(yy)) + @as(f64, @floatFromInt(ny))));
}

// x is reference partition, y is obtained partition
pub fn getHubertIndex(x: []const usize, y: []const usize) !f64 {
    if (x.len != y.len) return error.IncomparableSize;
    const n: usize = x.len;
    var yy: usize = 0;
    var yn: usize = 0;
    var ny: usize = 0;
    var nn: usize = 0;
    for (0..@intCast(n)) |i| {
        const xi = x[i];
        const yi = y[i];
        for (i + 1..@intCast(n)) |j| {
            const x_eq = xi == x[j];
            const y_eq = yi == y[j];
            if (x_eq and y_eq) yy += 1;
            if (!x_eq and y_eq) ny += 1;
            if (x_eq and !y_eq) yn += 1;
            if (!x_eq and !y_eq) nn += 1;
        }
    }
    // c = ( N_t * yy - (yy + yn)(yy + ny)) / sqrt( (yy + yn)(yy + ny)(nn + yn)(nn + ny) ), where Nt = n(n - 1) / 2
    const n_t: f64 = 0.5 * @as(f64, @floatFromInt(n)) * @as(f64, @floatFromInt(n - 1));
    const m: f64 = (@as(f64, @floatFromInt(yy)) + @as(f64, @floatFromInt(yn))) * (@as(f64, @floatFromInt(yy)) + @as(f64, @floatFromInt(ny)));
    const k: f64 = (@as(f64, @floatFromInt(nn)) + @as(f64, @floatFromInt(yn))) * (@as(f64, @floatFromInt(nn)) + @as(f64, @floatFromInt(ny)));
    return if (m == 0.0 or k == 0.0) 0.0 else (n_t * @as(f64, @floatFromInt(yy)) - m) / std.math.sqrt(k * m);
}

// x is reference partition, y is obtained partition
pub fn getJaccardIndex(x: []const usize, y: []const usize) !f64 {
    if (x.len != y.len) return error.IncomparableSize;
    const n: usize = x.len;
    var yy: usize = 0;
    var yn: usize = 0;
    var ny: usize = 0;
    for (0..n) |i| {
        const xi = x[i];
        const yi = y[i];
        for (i + 1..n) |j| {
            const x_eq = xi == x[j];
            const y_eq = yi == y[j];
            if (x_eq and y_eq) yy += 1;
            if (!x_eq and y_eq) ny += 1;
            if (x_eq and !y_eq) yn += 1;
        }
    }
    // c = yy / ( yy + yn + ny )
    return if (yy == 0 and yn == 0 and ny == 0) 0.0 else @as(f64, @floatFromInt(yy)) / (@as(f64, @floatFromInt(yy)) + @as(f64, @floatFromInt(yn)) + @as(f64, @floatFromInt(ny)));
}

// x is reference partition, y is obtained partition
pub fn getKulczynskiIndex(x: []const usize, y: []const usize) !f64 {
    if (x.len != y.len) return error.IncomparableSize;
    const n: usize = x.len;
    var yy: usize = 0;
    var yn: usize = 0;
    var ny: usize = 0;
    for (0..n) |i| {
        const xi = x[i];
        const yi = y[i];
        for (i + 1..n) |j| {
            const x_eq = xi == x[j];
            const y_eq = yi == y[j];
            if (x_eq and y_eq) yy += 1;
            if (!x_eq and y_eq) ny += 1;
            if (x_eq and !y_eq) yn += 1;
        }
    }
    // c = 0.5 ( (yy / (yy + ny)) + (yy / (yy + yn)) )
    return if (yy == 0 and (ny == 0 or yn == 0)) 0.0 else 0.5 * ((@as(f64, @floatFromInt(yy)) / (@as(f64, @floatFromInt(yy)) + @as(f64, @floatFromInt(ny)))) + (@as(f64, @floatFromInt(yy)) / (@as(f64, @floatFromInt(yy)) + @as(f64, @floatFromInt(yn)))));
}

// x is reference partition, y is obtained partition
pub fn getMcNemarIndex(x: []const usize, y: []const usize) !f64 {
    if (x.len != y.len) return error.IncomparableSize;
    const n: usize = x.len;
    var yn: usize = 0;
    var ny: usize = 0;
    for (0..n) |i| {
        const xi = x[i];
        const yi = y[i];
        for (i + 1..n) |j| {
            const x_eq = xi == x[j];
            const y_eq = yi == y[j];
            if (!x_eq and y_eq) ny += 1;
            if (x_eq and !y_eq) yn += 1;
        }
    }
    // c = ((yn - ny) / sqrt(yn + ny))
    return if (yn == 0 and ny == 0) 0.0 else (@as(f64, @floatFromInt(yn)) - @as(f64, @floatFromInt(ny))) / std.math.sqrt(@as(f64, @floatFromInt(yn)) + @as(f64, @floatFromInt(ny)));
}

// x is reference partition, y is obtained partition
pub fn getPhiIndex(x: []const usize, y: []const usize) !f64 {
    if (x.len != y.len) return error.IncomparableSize;
    const n: usize = x.len;
    var yy: usize = 0;
    var yn: usize = 0;
    var ny: usize = 0;
    var nn: usize = 0;
    for (0..n) |i| {
        const xi = x[i];
        const yi = y[i];
        for (i + 1..n) |j| {
            const x_eq = xi == x[j];
            const y_eq = yi == y[j];
            if (x_eq and y_eq) yy += 1;
            if (!x_eq and y_eq) ny += 1;
            if (x_eq and !y_eq) yn += 1;
            if (!x_eq and !y_eq) nn += 1;
        }
    }
    // c = ( yy * nn − yn * ny ) / ( (yy + yn)(yy + ny)(yn + nn)(ny + nn) )
    const m: f64 = (@as(f64, @floatFromInt(yy)) + @as(f64, @floatFromInt(yn))) * (@as(f64, @floatFromInt(yy)) + @as(f64, @floatFromInt(ny)));
    const k: f64 = (@as(f64, @floatFromInt(nn)) + @as(f64, @floatFromInt(yn))) * (@as(f64, @floatFromInt(nn)) + @as(f64, @floatFromInt(ny)));
    return if (m == 0.0 or k == 0.0) 0.0 else (@as(f64, @floatFromInt(yy)) * @as(f64, @floatFromInt(nn)) - @as(f64, @floatFromInt(yn)) * @as(f64, @floatFromInt(ny))) / (m * k);
}

// x is reference partition, y is obtained partition
pub fn getRandIndex(x: []const usize, y: []const usize) !f64 {
    if (x.len != y.len or x.len < 2) return error.IncomparableSize;
    const n: usize = x.len;
    var yy: usize = 0;
    var nn: usize = 0;
    for (0..@intCast(n)) |i| {
        const xi = x[i];
        const yi = y[i];
        for (i + 1..n) |j| {
            const x_eq = xi == x[j];
            const y_eq = yi == y[j];
            if (x_eq and y_eq) yy += 1;
            if (!x_eq and !y_eq) nn += 1;
        }
    }
    // c = ( yy + nn ) / N_t, where Nt = n(n - 1) / 2
    const n_t: f64 = 0.5 * @as(f64, @floatFromInt(n)) * @as(f64, @floatFromInt(n - 1));
    return (@as(f64, @floatFromInt(yy)) + @as(f64, @floatFromInt(nn))) / n_t;
}

// x is reference partition, y is obtained partition
pub fn getRogersTanimotoIndex(x: []const usize, y: []const usize) !f64 {
    if (x.len != y.len) return error.IncomparableSize;
    const n: usize = x.len;
    var yy: usize = 0;
    var yn: usize = 0;
    var ny: usize = 0;
    var nn: usize = 0;
    for (0..n) |i| {
        const xi = x[i];
        const yi = y[i];
        for (i + 1..n) |j| {
            const x_eq = xi == x[j];
            const y_eq = yi == y[j];
            if (x_eq and y_eq) yy += 1;
            if (!x_eq and y_eq) ny += 1;
            if (x_eq and !y_eq) yn += 1;
            if (!x_eq and !y_eq) nn += 1;
        }
    }
    // c = ( yy + nn ) / ( yy + nn + 2(yn + ny) )
    const yynn: f64 = @as(f64, @floatFromInt(yy)) + @as(f64, @floatFromInt(nn));
    return if (yy == 0 and nn == 0 and yn == 0 and ny == 0) 0.0 else yynn / (yynn + 2.0 * @as(f64, @floatFromInt(yn)) + 2.0 * @as(f64, @floatFromInt(ny)));
}

// x is reference partition, y is obtained partition
pub fn getRusselRaoIndex(x: []const usize, y: []const usize) !f64 {
    if (x.len != y.len or x.len < 2) return error.IncomparableSize;
    const n: usize = x.len;
    var yy: usize = 0;
    for (0..n) |i| {
        const xi = x[i];
        const yi = y[i];
        for (i + 1..n) |j| yy += @intFromBool(xi == x[j] and yi == y[j]);
    }
    const n_t: f64 = 0.5 * @as(f64, @floatFromInt(n)) * @as(f64, @floatFromInt(n - 1));
    // c = yy / N_t, where Nt = n(n - 1) / 2
    return @as(f64, @floatFromInt(yy)) / n_t;
}

// x is reference partition, y is obtained partition
pub fn getSokalSneathFirstIndex(x: []const usize, y: []const usize) !f64 {
    if (x.len != y.len) return error.IncomparableSize;
    const n: usize = x.len;
    var yy: usize = 0;
    var yn: usize = 0;
    var ny: usize = 0;
    for (0..n) |i| {
        const xi = x[i];
        const yi = y[i];
        for (i + 1..n) |j| {
            const x_eq = xi == x[j];
            const y_eq = yi == y[j];
            if (x_eq and y_eq) yy += 1;
            if (!x_eq and y_eq) ny += 1;
            if (x_eq and !y_eq) yn += 1;
        }
    }
    // c = yy / ( yy + 2(yn + ny) )
    return if (yy == 0 and yn == 0 and ny == 0) 0.0 else @as(f64, @floatFromInt(yy)) / (@as(f64, @floatFromInt(yy)) + 2.0 * @as(f64, @floatFromInt(yn)) + 2.0 * @as(f64, @floatFromInt(ny)));
}

// x is reference partition, y is obtained partition
pub fn getSokalSneathSecondIndex(x: []const usize, y: []const usize) !f64 {
    if (x.len != y.len) return error.IncomparableSize;
    const n: usize = x.len;
    var yy: usize = 0;
    var yn: usize = 0;
    var ny: usize = 0;
    var nn: usize = 0;
    for (0..n) |i| {
        for (i + 1..n) |j| {
            if (x[i] == x[j] and y[i] == y[j]) yy += 1;
            if (x[i] != x[j] and y[i] == y[j]) ny += 1;
            if (x[i] == x[j] and y[i] != y[j]) yn += 1;
            if (x[i] != x[j] and y[i] != y[j]) nn += 1;
        }
    }
    // c = ( yy + nn ) / ( yy + nn + 0.5 * (yn + ny) )
    const yynn: f64 = @as(f64, @floatFromInt(yy)) + @as(f64, @floatFromInt(nn));
    return if (yynn == 0.0 and yn == 0 and ny == 0) 0.0 else yynn / (yynn + 0.5 * (@as(f64, @floatFromInt(yn)) + (@as(f64, @floatFromInt(ny)))));
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
    const n: usize = x.len;
    var yy: usize = 0;
    var yn: usize = 0;
    var ny: usize = 0;
    var nn: usize = 0;
    for (0..n) |i| {
        const xi = x[i];
        const yi = y[i];
        for (i + 1..n) |j| {
            const x_eq = xi == x[j];
            const y_eq = yi == y[j];
            if (x_eq and y_eq) yy += 1;
            if (!x_eq and y_eq) ny += 1;
            if (x_eq and !y_eq) yn += 1;
            if (!x_eq and !y_eq) nn += 1;
        }
    }
    const n_t: f64 = 0.5 * @as(f64, @floatFromInt(n)) * @as(f64, @floatFromInt(n - 1));
    const yynn: f64 = @as(f64, @floatFromInt(yy)) + @as(f64, @floatFromInt(nn));
    const m: f64 = (@as(f64, @floatFromInt(yy)) + @as(f64, @floatFromInt(yn))) * (@as(f64, @floatFromInt(yy)) + @as(f64, @floatFromInt(ny)));
    const k: f64 = (@as(f64, @floatFromInt(nn)) + @as(f64, @floatFromInt(yn))) * (@as(f64, @floatFromInt(nn)) + @as(f64, @floatFromInt(ny)));
    _p.* = if (ny == 0 and yy == 0) 0.0 else @as(f64, @floatFromInt(yy)) / (@as(f64, @floatFromInt(yy)) + @as(f64, @floatFromInt(ny)));
    _rc.* = if (yy == 0 and yn == 0) 0.0 else @as(f64, @floatFromInt(yy)) / (@as(f64, @floatFromInt(yy)) + @as(f64, @floatFromInt(yn)));
    _cdi.* = if (yy == 0 and yn == 0 and ny == 0) 0.0 else 2.0 * @as(f64, @floatFromInt(yy)) / (2.0 * @as(f64, @floatFromInt(yy)) + @as(f64, @floatFromInt(yn)) + @as(f64, @floatFromInt(ny)));
    _fmi.* = if (yy == 0 and (yn == 0 or ny == 0)) 0.0 else @as(f64, @floatFromInt(yy)) / std.math.sqrt((@as(f64, @floatFromInt(yy)) + @as(f64, @floatFromInt(yn))) * (@as(f64, @floatFromInt(yy)) + @as(f64, @floatFromInt(ny))));
    _hi.* = if (m == 0.0 or k == 0.0) 0.0 else (n_t * @as(f64, @floatFromInt(yy)) - m) / std.math.sqrt(k * m);
    _ji.* = if (yy == 0 and yn == 0 and ny == 0) 0.0 else @as(f64, @floatFromInt(yy)) / (@as(f64, @floatFromInt(yy)) + @as(f64, @floatFromInt(yn)) + @as(f64, @floatFromInt(ny)));
    _ki.* = if (yy == 0 and (ny == 0 or yn == 0)) 0.0 else 0.5 * ((@as(f64, @floatFromInt(yy)) / (@as(f64, @floatFromInt(yy)) + @as(f64, @floatFromInt(ny)))) + (@as(f64, @floatFromInt(yy)) / (@as(f64, @floatFromInt(yy)) + @as(f64, @floatFromInt(yn)))));
    _mni.* = if (yn == 0 and ny == 0) 0.0 else (@as(f64, @floatFromInt(yn)) - @as(f64, @floatFromInt(ny))) / std.math.sqrt(@as(f64, @floatFromInt(yn)) + @as(f64, @floatFromInt(ny)));
    _phi.* = if (m == 0.0 or k == 0.0) 0.0 else (@as(f64, @floatFromInt(yy)) * @as(f64, @floatFromInt(nn)) - @as(f64, @floatFromInt(yn)) * @as(f64, @floatFromInt(ny))) / (m * k);
    _rand.* = if (n < 2) 0.0 else (@as(f64, @floatFromInt(yy)) + @as(f64, @floatFromInt(nn))) / n_t;
    _rti.* = if (yy == 0 and nn == 0 and yn == 0 and ny == 0) 0.0 else yynn / (yynn + 2.0 * @as(f64, @floatFromInt(yn)) + 2.0 * @as(f64, @floatFromInt(ny)));
    _rri.* = if (n < 2) 0.0 else @as(f64, @floatFromInt(yy)) / n_t;
    _s1i.* = if (yy == 0 and yn == 0 and ny == 0) 0.0 else @as(f64, @floatFromInt(yy)) / (@as(f64, @floatFromInt(yy)) + 2.0 * @as(f64, @floatFromInt(yn)) + 2.0 * @as(f64, @floatFromInt(ny)));
    _s2i.* = if (yynn == 0.0 and yn == 0 and ny == 0) 0.0 else yynn / (yynn + 0.5 * (@as(f64, @floatFromInt(yn)) + (@as(f64, @floatFromInt(ny)))));
}

pub fn writeFullResult(file_name: []const u8, array: []const usize, p: f64, rc: f64, cdi: f64, fmi: f64, hi: f64, ji: f64, ki: f64, mni: f64, phi: f64, randi: f64, rti: f64, rri: f64, s1i: f64, s2i: f64) !void {
    const file = try std.fs.cwd().createFile(file_name, .{});
    defer file.close();
    const writer = file.writer();
    try writer.print("The result of clustering using k-means, _\nPrecision coefficient, {d:}\nRecall coefficient, {d:}\nCzekanowski-Dice index, {d:}\nFolkes-Mallows index, {d:}\nHubert index, {d:}\nJaccard index, {d:}\nKulczynski index, {d:}\nMcNemar index, {d:}\nPhi index, {d:}\nRand index, {d:}\nRogers-Tanimoto index, {d:}\nRussel-Rao index, {d:}\nSokal-Sneath I index, {d:}\nSokal-Sneath II index, {d:}\n\n", .{ p, rc, cdi, fmi, hi, ji, ki, mni, phi, randi, rti, rri, s1i, s2i });
    for (array, 1..) |element, i| try writer.print("{}, {}\n", .{ i, element });
}
