const std = @import("std");

fn checkSlicesLen(comptime T: type, x: []const []const T) !bool {
    const lenFirst = x.ptr[0].len;

    for (x[1..]) |xi| if (xi.len != lenFirst) return false;
    return true;
}

fn free(comptime T: type, x: *[][]T, allocator: std.mem.Allocator) !void {
    if (x.*.len != 0) {
        for (x.*) |*xi| allocator.free(xi.*);
        allocator.free(x.*);
    }
}

fn copyMatr(comptime T: type, x: []const []const T, allocator: std.mem.Allocator) ![][]T {
    const res: [][]T = try allocator.alloc([]T, x.len);
    for (x, res) |xi, *resi| {
        resi.* = try allocator.alloc(T, xi.len);
        @memcpy(resi.*, xi);
    }
    return res;
}

pub const kMeans = struct {
    data: [][]f64 = undefined, // data
    centers: [][]f64 = undefined, // cluster centers
    n_clusters: usize = 0, // number of clusters
    allocator: std.mem.Allocator = std.heap.c_allocator, // memory allocator

    //de-facto constructor
    pub fn getKMeans(allocator: ?std.mem.Allocator, k: ?usize) kMeans {
        const _k = if (k) |v| v else 0;
        const _allocator = if (allocator) |alloc| alloc else std.heap.c_allocator;
        return .{ .n_clusters = _k, .centers = undefined, .data = undefined, .allocator = _allocator };
    }

    //initializator
    pub fn init(self: *kMeans, k: usize) !void {
        self.n_clusters = k;
    }

    // returns cluster centers
    pub fn get_centers(self: kMeans) ![][]f64 {
        if (self.centers.len == 0 and (self.data.len == 0 or self.n_clusters == 0)) return error.EmptyCenters;
        if (self.centers.len == 0 and self.data.len != 0 and self.n_clusters != 0) {
            return try kmeans_cores(self.data, self.n_clusters, self.allocator);
        }
        return self.centers;
    }

    //fit model
    pub fn fit(self: *kMeans, x: [][]f64) !void {
        if (x.len == 0 or self.n_clusters == 0) return error.ErrorFit;

        self.data = try copyMatr(f64, x, self.allocator);

        self.centers = try kmeans_cores(self.data, self.n_clusters, self.allocator);
    }

    // get predictions
    pub fn predict(self: kMeans, x: []const []const f64) ![]usize {
        if (x.len == 0) return error.EmptyInput;
        if (!try checkSlicesLen(f64, x)) return error.UnequalLenOfInput;

        if (self.centers.len == 0) {
            if (self.n_clusters == 0) return error.ErrorPredict;
            return try kmeans_y(x, self.n_clusters, self.allocator);
        } else {
            if (self.centers[0].len != x[0].len) {
                if (self.n_clusters == 0) return error.UnifiedNumberOfClusters;
                return try kmeans_y(x, self.n_clusters, self.allocator);
            }
            return try getPartition(x, self.centers, self.allocator);
        }
    }

    //de-facto destructor
    pub fn deinit(self: *kMeans) void {
        try free(f64, &self.centers, self.allocator);
        try free(f64, &self.data, self.allocator);
        self.n_clusters = 0;
    }
};

pub fn getDistance(y: []const f64, x: []const f64) !f64 {
    if (y.len != x.len) return error.IterableLengthMismatch;

    var sum: f64 = 0.0;
    for (y, x) |yi, xi| {
        const d = yi - xi;
        sum = @mulAdd(f64, d, d, sum);
    }

    return std.math.sqrt(sum);
}

pub fn scaling(x: [][]f64) !void {
    const n: usize = x.len;
    const m: usize = x[0].len;
    for (0..m) |j| {
        var ex: f64 = 0;
        var exx: f64 = 0;
        for (x) |xi| {
            const v = xi[j];
            ex += v;
            exx = @mulAdd(f64, v, v, exx);
        }
        ex /= @floatFromInt(n);
        exx = exx / @as(f64, @floatFromInt(n)) - ex * ex;
        exx = if (exx == 0.0) 1.0 else 1.0 / std.math.sqrt(exx);

        for (x) |*xi| {
            xi.*[j] = (xi.*[j] - ex) * exx;
        }
    }
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

fn contain(comptime T: type, y: []const T, val: T) !bool {
    for (y) |yi| if (yi == val) return true;
    return false;
}

test "test 1 contain fun" {
    const x = [_]usize{ 0, 1 };

    try std.testing.expectEqual(true, try contain(usize, &x, 1));
}

test "test 2 contain fun" {
    const x = [_]usize{ 0, 1 };

    try std.testing.expectEqual(false, try contain(usize, &x, 3));
}

test "test 3 contain fun" {
    const x = [_]usize{};

    try std.testing.expectEqual(false, try contain(usize, &x, 1));
}

fn getUnique(n: usize, k: usize, allocator: std.mem.Allocator) ![]usize {
    if (k > n) return error.ImpossibilityGenUniq;
    var prng = std.Random.DefaultPrng.init(@intCast(std.time.milliTimestamp() - std.time.timestamp() * @as(comptime_int, 1000)));
    const rnd = prng.random();
    const res: []usize = try allocator.alloc(usize, k);
    for (0..k) |i| {
        var val = rnd.intRangeAtMost(usize, 0, n - 1);
        while (try contain(usize, res[0..i], val)) : (val = rnd.intRangeAtMost(usize, 0, n - 1)) {}

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

fn getPartition(x: []const []const f64, c: []const []const f64, allocator: std.mem.Allocator) ![]usize {
    const y: []usize = try allocator.alloc(usize, x.len);

    for (x, y) |xi, *yi| yi.* = try getCluster(xi, c);

    return y;
}

fn kmeans_y(x: []const []const f64, k: usize, allocator: std.mem.Allocator) ![]usize {
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

fn calcCores(x: []const []const f64, y: []const usize, k: usize, allocator: std.mem.Allocator) ![][]f64 {
    if (k == 0) return error.IncorrectLen;
    const c: [][]f64 = try allocator.alloc([]f64, k);
    for (c) |*ci| {
        ci.* = try allocator.alloc(f64, x[0].len);
    }
    for (c) |*ci| @memset(ci.*, 0.0);

    const nums: []usize = try allocator.alloc(usize, k);
    defer allocator.free(nums);
    @memset(nums, 0);

    for (y, x) |yi, xi| {
        const c_yi = c[yi];
        nums[yi] += 1;
        for (c_yi, xi) |*c_yi_j, xij| c_yi_j.* += xij;
    }

    for (c, nums) |ci, count| {
        const inv = 1.0 / @as(f64, @floatFromInt(count));
        for (ci) |*cij| {
            cij.* *= inv;
        }
    }
    return c;
}

fn kmeans_cores(x: []const []const f64, k: usize, allocator: std.mem.Allocator) ![][]f64 {
    const c: [][]f64 = try detCores(x, k, allocator);

    const nums = try allocator.alloc(usize, k);
    defer allocator.free(nums);

    const y: []usize = try detStartPartition(x, c, nums, allocator);
    defer allocator.free(y);
    while (try checkPartition(x, c, y, nums)) {}

    return c;
}
