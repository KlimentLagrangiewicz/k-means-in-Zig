const std = @import("std");

pub fn getDistance(y: []f64, x: []f64) !f64 {
    var sum: f64 = 0.0;
    for (y, x) |i, j| {
        const cur: f64 = i - j;
        sum += cur * cur;
    }
    return sum;
}

fn autoscaling(X: [][]f64) ![][]f64 {
    const n: usize = X.len;
    const m: usize = X[0].len;
    const x: [][]f64 = try std.heap.c_allocator.alloc([]f64, n);
    for (x) |*xi| xi.* = try std.heap.c_allocator.alloc(f64, m);
    for (0..m) |j| {
        var ex: f64 = 0.0;
        var exx: f64 = 0.0;
        for (X) |xi| {
            const d: f64 = xi[j];
            ex += d;
            exx += d * d;
        }
        ex /= @floatFromInt(n);
        exx /= @floatFromInt(n);
        const sd: f64 = std.math.sqrt(exx - ex * ex);
        for (x, X) |*xi, Xi| (xi.*)[j] = (Xi[j] - ex) / sd;
    }
    return x;
}

fn getCluster(x: []f64, c: [][]f64) !usize {
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

fn checkSplitting(x: [][]f64, c: [][]f64, y: []usize, nums: []usize) !bool {
    for (c) |*ci| std.crypto.utils.secureZero(f64, ci.*);
    for (y, x) |yi, xi| {
        for (c[yi], xi) |*c_yi, xij| c_yi.* += xij;
    }
    for (c, nums) |ci, count| {
        for (ci) |*cij| cij.* /= @floatFromInt(count);
    }
    std.crypto.utils.secureZero(usize, nums);
    var flag: bool = false;
    for (x, y) |xi, *yi| {
        const f: usize = try getCluster(xi, c);
        if (f != yi.*) flag = true;
        yi.* = f;
        nums[f] += 1;
    }
    return flag;
}

fn contain(y: []usize, val: usize) !bool {
    for (y) |yi| if (yi == val) return true;
    return false;
}

fn getNums(n: usize, k: usize) ![]usize {
    var random = std.rand.DefaultPrng.init(@intCast(std.time.milliTimestamp()));
    var res: []usize = try std.heap.c_allocator.alloc(usize, k);
    for (0..k) |i| {
        var val = random.random().intRangeAtMost(usize, 0, n - 1);
        while (try contain(res[0..i], val)) : (val = random.random().intRangeAtMost(usize, 0, n - 1)) {}
        res[i] = val;
    }
    return res;
}

fn detCores(x: [][]f64, k: usize) ![][]f64 {
    const m = x[0].len;
    const nums = try getNums(x.len, k);
    defer std.heap.c_allocator.free(nums);
    const c: [][]f64 = try std.heap.c_allocator.alloc([]f64, k);
    for (c, nums) |*ci, count| {
        ci.* = try std.heap.c_allocator.alloc(f64, m);
        for (ci.*, x[count]) |*cij, xij| cij.* = xij;
    }
    return c;
}

fn detStartSplitting(x: [][]f64, c: [][]f64, nums: []usize) ![]usize {
    const y: []usize = try std.heap.c_allocator.alloc(usize, x.len);
    std.crypto.utils.secureZero(usize, nums);
    for (x, y) |xi, *yi| {
        yi.* = try getCluster(xi, c);
        nums[yi.*] += 1;
    }
    return y;
}

pub fn kmeans(X: [][]f64, k: usize) ![]usize {
    const x: [][]f64 = try autoscaling(X);
    defer {
        for (x) |*xi| std.heap.c_allocator.free(xi.*);
        std.heap.c_allocator.free(x);
    }
    const c: [][]f64 = try detCores(x, k);
    defer {
        for (c) |*ci| std.heap.c_allocator.free(ci.*);
        std.heap.c_allocator.free(c);
    }
    const nums = try std.heap.c_allocator.alloc(usize, k);
    defer std.heap.c_allocator.free(nums);
    const y: []usize = try detStartSplitting(x, c, nums);
    while (try checkSplitting(x, c, y, nums)) {}
    return y;
}
