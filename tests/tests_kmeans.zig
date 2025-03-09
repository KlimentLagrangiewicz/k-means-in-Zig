const std = @import("std");
const kmeans = @import("k-means");

test "test 1 distance fun" {
    const x = [_]f64{ 0.0, 0.0 };
    const y = [_]f64{ 1.0, 1.0 };
    try std.testing.expectEqual(std.math.sqrt(2.0), try kmeans.getDistance(&x, &y));
}

test "test 2 distance fun" {
    const x = [_]f64{ 1.0, 1.0 };
    try std.testing.expectEqual(std.math.sqrt(0.0), try kmeans.getDistance(&x, &x));
}

test "test 3 distance fun" {
    const x = [_]f64{};
    const y = [_]f64{};
    try std.testing.expectEqual(std.math.sqrt(0.0), try kmeans.getDistance(&x, &y));
}

test "test 4 distance fun" {
    const x = [_]f64{ 0.0, 0.0 };
    const y = [_]f64{ 1.0, 1.0, 5.0 };
    try std.testing.expectError(error.IterableLengthMismatch, kmeans.getDistance(&x, &y));
}
