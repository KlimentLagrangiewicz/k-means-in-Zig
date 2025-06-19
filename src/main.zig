const std = @import("std");
const k_means = @import("k-means");
const help = @import("help");

const c_alloctor = std.heap.c_allocator;

pub fn main() !void {
    const args = try std.process.argsAlloc(c_alloctor);
    defer std.process.argsFree(c_alloctor, args);

    if (args.len < 3) {
        try std.io.getStdOut().writer().print("Not enough parameters\n", .{});
    } else {
        const k: usize = try std.fmt.parseInt(usize, args[2], 10);
        if (k < 1) {
            try std.io.getStdOut().writer().print("Value of input k parameter is incorrect\n", .{});
            std.process.exit(1);
        }

        const x: [][]f64 = try help.readData(args[1], c_alloctor);
        defer {
            for (x) |*xi| c_alloctor.free(xi.*);
            c_alloctor.free(x);
        }

        if (k > x.len) {
            try std.io.getStdOut().writer().print("Value of input k parameter is incorrect\n", .{});
            std.process.exit(1);
        }

        try k_means.scaling(x);

        var kmeans = k_means.kMeans.getKMeans(null);
        defer kmeans.deinit();

        try kmeans.init(k);

        const start = try std.time.Instant.now();
        try kmeans.fit(x);
        const end = try std.time.Instant.now();
        const elapsed_us = end.since(start) / 1000;

        const y: []usize = try kmeans.predict(x);
        defer c_alloctor.free(y);

        try std.io.getStdOut().writer().print("Time for k-means clustering: {} usec\n", .{elapsed_us});
        if (args.len > 4) {
            const perfect: []usize = try help.readArrayFromFile(usize, args[4], c_alloctor);
            defer c_alloctor.free(perfect);

            var p: f64 = undefined;
            var rc: f64 = undefined;
            var cdi: f64 = undefined;
            var fmi: f64 = undefined;
            var hi: f64 = undefined;
            var ji: f64 = undefined;
            var ki: f64 = undefined;
            var mni: f64 = undefined;
            var phi: f64 = undefined;
            var randi: f64 = undefined;
            var rti: f64 = undefined;
            var rri: f64 = undefined;
            var s1i: f64 = undefined;
            var s2i: f64 = undefined;

            try help.getExternalIndices(perfect, y, &p, &rc, &cdi, &fmi, &hi, &ji, &ki, &mni, &phi, &randi, &rti, &rri, &s1i, &s2i);
            try std.io.getStdOut().writer().print("The result of clustering using k-means:\nPrecision coefficient\t= {d:}\nRecall coefficient\t= {d:}\nCzekanowski-Dice index\t= {d:}\nFolkes-Mallows index\t= {d:}\nHubert index\t\t= {d:}\nJaccard index\t\t= {d:}\nKulczynski index\t= {d:}\nMcNemar index\t\t= {d:}\nPhi index\t\t= {d:}\nRand index\t\t= {d:}\nRogers-Tanimoto index\t= {d:}\nRussel-Rao index\t= {d:}\nSokal-Sneath I index\t= {d:}\nSokal-Sneath II index\t= {d:}\n", .{ p, rc, cdi, fmi, hi, ji, ki, mni, phi, randi, rti, rri, s1i, s2i });
            try help.writeFullResult(args[3], y, p, rc, cdi, fmi, hi, ji, ki, mni, phi, randi, rti, rri, s1i, s2i);
        } else try help.writeResult(args[3], y);
    }
}
