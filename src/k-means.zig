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
    var x: [][]f64 = try std.heap.c_allocator.alloc([]f64, n);
    for (0..n) |i| x[i] = try std.heap.c_allocator.alloc(f64, m);
    for (0..m) |j| {
        var ex: f64 = 0.0;
        var exx: f64 = 0.0;
        for (0..n) |i| {
            const d: f64 = X[i][j];
            ex += d;
            exx += d * d;
        }
        ex /= @floatFromInt(n);
        exx /= @floatFromInt(n);
        const sd: f64 = std.math.sqrt(exx - ex * ex);
        for (0..n) |i| x[i][j] = (X[i][j] - ex) / sd;
    }
    return x;
}

fn getCluster(x: []f64, c: [][]f64) !usize {
    var res: usize = 0;
    var min_d: f64 = try getDistance(x, c[0]);
    for (1..c.len) |i| {
        const cur_d: f64 = try getDistance(x, c[i]);
        if (cur_d < min_d) {
            min_d = cur_d;
            res = i;
        }
    }
    return res;
}

fn checkSplitting(x: [][]f64, c: [][]f64, y: []usize, nums: []usize) !bool {
    const n: usize = x.len;
    const m: usize = x[0].len;
    const k: usize = c.len;
    for (c) |*i| std.crypto.utils.secureZero(f64, i.*);
    for (0..n) |i| {
        const id: usize = y[i];
        for (0..m) |j| c[id][j] += x[i][j];
    }
    for (0..k) |i| {
        const count: usize = nums[i];
        for (0..m) |j| c[i][j] /= @floatFromInt(count);
    }
    std.crypto.utils.secureZero(usize, nums);
    var flag: bool = false;
    for (0..n) |i| {
        const f: usize = try getCluster(x[i], c);
        if (f != y[i]) flag = true;
        y[i] = f;
        nums[f] += 1;
    }
    return flag;
}

fn contain(y: []usize, k: usize, val: usize) !bool {
    for (0..k) |i| if (y[i] == val) return true;
    return false;
}

fn getNums(n: usize, k: usize) ![]usize {
    var random = std.rand.DefaultPrng.init(@intCast(std.time.milliTimestamp()));
    var res: []usize = try std.heap.c_allocator.alloc(usize, k);
    for (0..k) |i| {
        var val = random.random().intRangeAtMost(usize, 0, n - 1);
        while (try contain(res, i, val)) : (val = random.random().intRangeAtMost(usize, 0, n - 1)) {}
        res[i] = val;
    }
    return res;
}

fn detCores(x: [][]f64, k: usize) ![][]f64 {
    const n = x.len;
    const m = x[0].len;
    const nums = try getNums(n, k);
    defer std.heap.c_allocator.free(nums);
    var res: [][]f64 = try std.heap.c_allocator.alloc([]f64, k);
    for (0..k) |i| {
        res[i] = try std.heap.c_allocator.alloc(f64, m);
        const val: usize = nums[i];
        for (0..m) |j| res[i][j] = x[val][j];
    }
    return res;
}

fn detStartSplitting(x: [][]f64, c: [][]f64, nums: []usize) ![]usize {
    const n: usize = x.len;
    var y: []usize = try std.heap.c_allocator.alloc(usize, n);
    std.crypto.utils.secureZero(usize, nums);
    for (0..n) |i| {
        const f = try getCluster(x[i], c);
        y[i] = f;
        nums[f] += 1;
    }
    return y;
}

pub fn kmeans(X: [][]f64, k: usize) ![]usize {
    const x: [][]f64 = try autoscaling(X);
    defer {
        for (0..x.len) |i| std.heap.c_allocator.free(x[i]);
        std.heap.c_allocator.free(x);
    }
    const c: [][]f64 = try detCores(x, k);
    defer {
        for (0..c.len) |i| std.heap.c_allocator.free(c[i]);
        std.heap.c_allocator.free(c);
    }
    const nums = try std.heap.c_allocator.alloc(usize, k);
    defer std.heap.c_allocator.free(nums);
    const y: []usize = try detStartSplitting(x, c, nums);
    while (try checkSplitting(x, c, y, nums)) {}
    return y;
}
