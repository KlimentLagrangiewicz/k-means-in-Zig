const std = @import("std");
const k_means = @import("k-means");
const help = @import("help");

const c_allocator = std.heap.c_allocator;

const used_float = f64;

pub fn main() !void {
    const args = try std.process.argsAlloc(c_allocator);
    defer std.process.argsFree(c_allocator, args);

    if (args.len < 3) {
        try std.io.getStdOut().writer().print("Not enough parameters\n", .{});
    } else {
        const k: usize = try std.fmt.parseInt(usize, args[2], 10);
        if (k < 1) {
            try std.io.getStdOut().writer().print("Value of input k parameter is incorrect\n", .{});
            std.process.exit(1);
        }

        const x: [][]used_float = try help.readData(used_float, args[1], c_allocator);
        defer {
            for (x) |*xi| c_allocator.free(xi.*);
            c_allocator.free(x);
        }

        if (k > x.len) {
            try std.io.getStdOut().writer().print("Value of input k parameter is incorrect\n", .{});
            std.process.exit(1);
        }

        try k_means.scaling(used_float, x);

        var kmeans = k_means.KMeans(used_float, null, null, null, null){};

        defer kmeans.deinit();

        try kmeans.init(k, null, null);

        const start = try std.time.Instant.now();
        try kmeans.fit(x);
        const end = try std.time.Instant.now();
        const elapsed_us = end.since(start) / 1000;

        const y: []usize = try kmeans.predict(x);
        defer c_allocator.free(y);

        try std.io.getStdOut().writer().print("Time for k-means clustering: {} usec\n", .{elapsed_us});
        if (args.len > 4) {
            const perfect: []usize = try help.readArrayFromFile(usize, args[4], c_allocator);
            defer c_allocator.free(perfect);
            var p: used_float = undefined;
            var rc: used_float = undefined;
            var cdi: used_float = undefined;
            var fmi: used_float = undefined;
            var hi: used_float = undefined;
            var ji: used_float = undefined;
            var ki: used_float = undefined;
            var mni: used_float = undefined;
            var phi: used_float = undefined;
            var randi: used_float = undefined;
            var rti: used_float = undefined;
            var rri: used_float = undefined;
            var s1i: used_float = undefined;
            var s2i: used_float = undefined;

            try help.getExternalIndices(used_float, perfect, y, &p, &rc, &cdi, &fmi, &hi, &ji, &ki, &mni, &phi, &randi, &rti, &rri, &s1i, &s2i);
            try std.io.getStdOut().writer().print("The result of clustering using k-means:\nPrecision coefficient\t= {d:}\nRecall coefficient\t= {d:}\nCzekanowski-Dice index\t= {d:}\nFolkes-Mallows index\t= {d:}\nHubert index\t\t= {d:}\nJaccard index\t\t= {d:}\nKulczynski index\t= {d:}\nMcNemar index\t\t= {d:}\nPhi index\t\t= {d:}\nRand index\t\t= {d:}\nRogers-Tanimoto index\t= {d:}\nRussel-Rao index\t= {d:}\nSokal-Sneath I index\t= {d:}\nSokal-Sneath II index\t= {d:}\n", .{ p, rc, cdi, fmi, hi, ji, ki, mni, phi, randi, rti, rri, s1i, s2i });
            try help.writeFullResult(used_float, args[3], y, p, rc, cdi, fmi, hi, ji, ki, mni, phi, randi, rti, rri, s1i, s2i);
        } else try help.writeResult(args[3], y);
    }
}
