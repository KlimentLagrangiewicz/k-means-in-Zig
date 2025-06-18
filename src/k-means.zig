const std = @import("std");
const setZero = std.crypto.utils.secureZero;

pub fn getDistance(y: []const f64, x: []const f64) !f64 {
    if (y.len != x.len) return error.IterableLengthMismatch;

    var sum: f64 = 0.0;
    for (y, x) |i, j| sum += (i - j) * (i - j);

    return std.math.sqrt(sum);
}

pub fn autoscaling(X: []const []const f64, allocator: std.mem.Allocator) ![][]f64 {
    const n: usize = X.len;
    const m: usize = X[0].len;
    const ex: []f64 = try allocator.alloc(f64, m);
    defer allocator.free(ex);
    const exx: []f64 = try allocator.alloc(f64, m);
    defer allocator.free(exx);
    setZero(f64, ex);
    setZero(f64, exx);

    for (X) |xi|
        for (xi, ex, exx) |xij, *exj, *exxj| {
            exj.* += xij;
            exxj.* += xij * xij;
        };

    for (ex, exx) |*exi, *exxi| {
        exi.* /= @floatFromInt(n);
        exxi.* = @abs(exxi.* / @as(f64, @floatFromInt(n)) - exi.* * exi.*);
        exxi.* = if (exxi.* == 0.0) 1.0 else 1.0 / std.math.sqrt(exxi.*);
    }

    const x: [][]f64 = try allocator.alloc([]f64, n);
    for (x, X) |*xi, Xi| {
        xi.* = try allocator.alloc(f64, m);
        for (xi.*, Xi, ex, exx) |*xij, Xij, exj, exxj| xij.* = (Xij - exj) * exxj;
    }

    return x;
}

fn getCluster(x: []const f64, c: []const []const f64) !usize {
    var res: usize = 0;
    var min_d: f64 = try getDistance(x, c[0]);

    for (c[1..], 1..) |ci, i| {
        const cur_d: f64 = try getDistance(x, ci);
        if (cur_d < min_d) {
            min_d = cur_d;
            res = i;
        }
    }

    return res;
}

fn checkPartition(x: []const []const f64, c: [][]f64, y: []usize, nums: []usize) !bool {
    for (c) |*ci| setZero(f64, ci.*);
    for (y, x) |yi, xi| {
        for (c[yi], xi) |*c_yi, xij| c_yi.* += xij;
    }
    for (c, nums) |ci, count| {
        for (ci) |*cij| cij.* /= @floatFromInt(count);
    }

    setZero(usize, nums);
    var flag: bool = false;
    for (x, y) |xi, *yi| {
        const f: usize = try getCluster(xi, c);
        if (f != yi.*) flag = true;
        yi.* = f;
        nums[f] += 1;
    }

    return flag;
}

fn contain(y: []const usize, val: usize) !bool {
    for (y) |yi| if (yi == val) return true;
    return false;
}

test "test 1 contain fun" {
    const x = [_]usize{ 0, 1 };

    try std.testing.expectEqual(true, try contain(&x, 1));
}

test "test 2 contain fun" {
    const x = [_]usize{ 0, 1 };

    try std.testing.expectEqual(false, try contain(&x, 3));
}

test "test 3 contain fun" {
    const x = [_]usize{};

    try std.testing.expectEqual(false, try contain(&x, 1));
}

fn getNums(n: usize, k: usize, allocator: std.mem.Allocator) ![]usize {
    var random = std.Random.DefaultPrng.init(@intCast(std.time.milliTimestamp() - std.time.timestamp() * @as(comptime_int, 1000)));
    const res: []usize = try allocator.alloc(usize, k);
    for (0..k) |i| {
        var val = random.random().intRangeAtMost(usize, 0, n - 1);
        while (try contain(res[0..i], val)) : (val = random.random().intRangeAtMost(usize, 0, n - 1)) {}

        res[i] = val;
    }

    return res;
}

fn detCores(x: []const []const f64, k: usize, allocator: std.mem.Allocator) ![][]f64 {
    const m = x[0].len;
    const nums = try getNums(x.len, k, allocator);
    defer allocator.free(nums);

    const c: [][]f64 = try allocator.alloc([]f64, k);
    for (c, nums) |*ci, count| {
        ci.* = try allocator.alloc(f64, m);
        for (ci.*, x[count]) |*cij, xij| cij.* = xij;
    }

    return c;
}

fn detStartPartition(x: []const []const f64, c: []const []const f64, nums: []usize, allocator: std.mem.Allocator) ![]usize {
    const y: []usize = try allocator.alloc(usize, x.len);
    setZero(usize, nums);
    for (x, y) |xi, *yi| {
        yi.* = try getCluster(xi, c);
        nums[yi.*] += 1;
    }
    return y;
}

pub fn kmeans(X: []const []const f64, k: usize, allocator: std.mem.Allocator) ![]usize {
    const x: [][]f64 = try autoscaling(X, allocator);
    defer {
        for (x) |*xi| allocator.free(xi.*);
        allocator.free(x);
    }

    const c: [][]f64 = try detCores(x, k, allocator);
    defer {
        for (c) |*ci| allocator.free(ci.*);
        allocator.free(c);
    }

    const nums = try allocator.alloc(usize, k);
    defer allocator.free(nums);

    const y: []usize = try detStartPartition(x, c, nums, allocator);
    while (try checkPartition(x, c, y, nums)) {}

    return y;
}

// k-means without scaling data at the beginning
pub fn kmeans_ws(x: []const []const f64, k: usize, allocator: std.mem.Allocator) ![]usize {
    const c: [][]f64 = try detCores(x, k, allocator);
    defer {
        for (c) |*ci| allocator.free(ci.*);
        allocator.free(c);
    }

    const nums = try allocator.alloc(usize, k);
    defer allocator.free(nums);

    const y: []usize = try detStartPartition(x, c, nums, allocator);
    while (try checkPartition(x, c, y, nums)) {}

    return y;
}
