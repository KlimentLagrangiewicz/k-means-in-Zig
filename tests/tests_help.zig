const std = @import("std");
const help = @import("help");


test "test 1 calculation precision coeff. fun" {
    const x = [_]usize{ 0, 0 };
    const y = [_]usize{ 1, 1 };

    try std.testing.expectEqual(1.0, try help.getPrecisionCoeff(&x, &y));
}

test "test 2 calculation precision coeff. fun" {
    const x = [_]usize{ 1, 0 };
    const y = [_]usize{ 0, 0 };

    try std.testing.expectEqual(0.0, try help.getPrecisionCoeff(&x, &y));
}

test "test 3 calculation precision coeff. fun" {
    const x = [_]usize{ };
    const y = [_]usize{ };

    try std.testing.expectEqual(0.0, try help.getPrecisionCoeff(&x, &y));
}

test "test 4 calculation precision coeff. fun" {
    const x = [_]usize{ 1, 0 };
    const y = [_]usize{ 0, 0, 1 };

    try std.testing.expectError(error.IncomparableSize, help.getPrecisionCoeff(&x, &y));
}