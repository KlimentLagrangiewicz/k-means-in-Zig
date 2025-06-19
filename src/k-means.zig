const std = @import("std");

pub fn getDistance(y: []const f64, x: []const f64) !f64 {
    if (y.len != x.len) return error.IterableLengthMismatch;

    var sum: f64 = 0.0;
    for (y, x) |yi, xi| {
        const d = yi - xi;
        sum = @mulAdd(f64, d, d, sum);
    }

    return std.math.sqrt(sum);
}

pub fn scaling(X: []const []const f64, allocator: std.mem.Allocator) ![][]f64 {
    const n: usize = X.len;
    const m: usize = X[0].len;
    const x: [][]f64 = try allocator.alloc([]f64, n);
    for (x) |*xi| xi.* = try allocator.alloc(f64, m);
    for (0..m) |j| {
        var ex: f64 = 0;
        var exx: f64 = 0;
        for (X) |xi| {
            const v = xi[j];
            ex += v;
            exx = @mulAdd(f64, v, v, exx);
        }
        ex /= @floatFromInt(n);
        exx = exx / @as(f64, @floatFromInt(n)) - ex * ex;
        exx = if (exx == 0.0) 1.0 else 1.0 / std.math.sqrt(exx);

        for (x, X) |*xi, Xi| {
            xi.*[j] = (Xi[j] - ex) * exx;
        }
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
    for (c) |*ci| @memset(ci.*, 0.0);

    for (y, x) |yi, xi| {
        const c_yi = c[yi];
        for (c_yi, xi) |*c_yi_j, xij| c_yi_j.* += xij;
    }

    for (c, nums) |ci, count| {
        const inv = 1.0 / @as(f64, @floatFromInt(count));
        for (ci) |*cij| {
            cij.* *= inv;
        }
    }

    @memset(nums, 0);
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

fn getUnique(n: usize, k: usize, allocator: std.mem.Allocator) ![]usize {
    if (k > n) return error.ImpossibilityGenUniq;
    var prng = std.Random.DefaultPrng.init(@intCast(std.time.milliTimestamp() - std.time.timestamp() * @as(comptime_int, 1000)));
    const rnd = prng.random();
    const res: []usize = try allocator.alloc(usize, k);
    for (0..k) |i| {
        var val = rnd.intRangeAtMost(usize, 0, n - 1);
        while (try contain(res[0..i], val)) : (val = rnd.intRangeAtMost(usize, 0, n - 1)) {}

        res[i] = val;
    }

    return res;
}

fn detCores(x: []const []const f64, k: usize, allocator: std.mem.Allocator) ![][]f64 {
    const m = x[0].len;
    const nums = try getUnique(x.len, k, allocator);
    defer allocator.free(nums);

    const c: [][]f64 = try allocator.alloc([]f64, k);
    for (c, nums) |*ci, idx| {
        ci.* = try allocator.alloc(f64, m);
        std.mem.copyForwards(f64, ci.*, x[idx]);
    }

    return c;
}

fn detStartPartition(x: []const []const f64, c: []const []const f64, nums: []usize, allocator: std.mem.Allocator) ![]usize {
    const y: []usize = try allocator.alloc(usize, x.len);
    @memset(nums, 0);
    for (x, y) |xi, *yi| {
        yi.* = try getCluster(xi, c);
        nums[yi.*] += 1;
    }
    return y;
}

pub fn kmeans(X: []const []const f64, k: usize, allocator: std.mem.Allocator) ![]usize {
    const x: [][]f64 = try scaling(X, allocator);
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
