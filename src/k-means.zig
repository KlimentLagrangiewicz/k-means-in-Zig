const std = @import("std");

pub fn get_distance(y: []f64, x: []f64) !f64 {
    var sum: f64 = 0.0;
    for (y, x) |i, j| {
        const cur: f64 = i - j;
        sum += cur * cur;
    }
    return sum;
}

pub fn autoscaling(X: [][]f64) ![][]f64 {
    const n: usize = X.len;
    const m: usize = X[0].len;
    var x: [][]f64 = try std.heap.c_allocator.alloc([]f64, n);
    for (0..n) |i| {
        x[i] = try std.heap.c_allocator.alloc(f64, m);
    }
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
        for (0..n) |i| {
            x[i][j] = (X[i][j] - ex) / sd;
        }
    }
    return x;
}

pub fn get_cluster(x: []f64, c: [][]f64) !usize {
    var res: usize = 0;
    var min_d: f64 = try get_distance(x, c[0]);
    for (1..c.len) |i| {
        const cur_d: f64 = try get_distance(x, c[i]);
        if (cur_d < min_d) {
            min_d = cur_d;
            res = i;
        }
    }
    return res;
}

pub fn check_splitting(x: [][]f64, c: [][]f64, y: []usize) !bool {
    const n: usize = x.len;
    const m: usize = x[0].len;
    const k: usize = c.len;
    var flag: bool = false;
    var nums = try std.heap.c_allocator.alloc(usize, k);
    var n_c: [][]f64 = try std.heap.c_allocator.alloc([]f64, k);
    defer std.heap.c_allocator.free(nums);
    for (0..k) |i| {
        n_c[i] = try std.heap.c_allocator.alloc(f64, m);
        for (0..m) |j| {
            n_c[i][j] = 0.0;
        }
        nums[i] = 0;
    }
    for (0..n) |i| {
        const f: usize = try get_cluster(x[i], c);
        if (f != y[i]) {
            flag = true;
        }
        y[i] = f;
        nums[f] += 1;
        for (0..m) |j| {
            n_c[f][j] += x[i][j];
        }
    }
    for (0..k) |i| {
        const f: f64 = @as(f64, @floatFromInt(nums[i]));
        for (0..m) |j| {
            c[i][j] = n_c[i][j] / f;
        }
        std.heap.c_allocator.free(n_c[i]);
    }
    std.heap.c_allocator.free(n_c);
    return flag;
}

pub fn contain(y: []usize, k: usize, val: usize) !bool {
    for (0..k) |i| {
        if (y[i] == val) return true;
    }
    return false;
}

pub fn get_nums(n: usize, k: usize) ![]usize {
    var random = std.rand.DefaultPrng.init(@intCast(std.time.milliTimestamp()));
    var res: []usize = try std.heap.c_allocator.alloc(usize, k);
    for (0..k) |i| {
        var val = random.random().intRangeAtMost(usize, 0, n - 1);
        while (try contain(res, i, val)) : (val = random.random().intRangeAtMost(usize, 0, n - 1)) {}
        res[i] = val;
    }
    return res;
}

pub fn det_cores(x: [][]f64, k: usize) ![][]f64 {
    const n = x.len;
    const m = x[0].len;
    const nums = try get_nums(n, k);
    defer std.heap.c_allocator.free(nums);
    var res: [][]f64 = try std.heap.c_allocator.alloc([]f64, k);
    for (0..k) |i| {
        res[i] = try std.heap.c_allocator.alloc(f64, m);
        const val: usize = nums[i];
        for (0..m) |j| {
            res[i][j] = x[val][j];
        }
    }
    return res;
}

pub fn det_start_splitting(x: [][]f64, c: [][]f64) ![]usize {
    const n: usize = x.len;
    var y: []usize = try std.heap.c_allocator.alloc(usize, n);
    for (0..n) |i| {
        y[i] = try get_cluster(x[i], c);
    }
    return y;
}

pub fn kmeans(X: [][]f64, k: usize) ![]usize {
    var x: [][]f64 = try autoscaling(X);
    defer {
        const n: usize = x.len;
        for (0..n) |i| {
            std.heap.c_allocator.free(x[i]);
        }
        std.heap.c_allocator.free(x);
    }
    var c: [][]f64 = try det_cores(x, k);
    defer {
        const n: usize = c.len;
        for (0..n) |i| {
            std.heap.c_allocator.free(c[i]);
        }
        std.heap.c_allocator.free(c);
    }
    var y: []usize = try det_start_splitting(x, c);
    while (try check_splitting(x, c, y)) {}
    return y;
}
