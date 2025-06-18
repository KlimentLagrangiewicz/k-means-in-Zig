const std = @import("std");
const kmeans = @import("k-means");
const help = @import("help");

pub fn main() !void {
    const used_alloctor = std.heap.c_allocator;
    // or:
    //var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    //defer _ = gpa.deinit();
    //const used_alloctor = gpa.allocator();

    const args = try std.process.argsAlloc(used_alloctor);
    defer std.process.argsFree(used_alloctor, args);
    if (args.len < 3) {
        try std.io.getStdOut().writer().print("Not enough parameters\n", .{});
    } else {
        const k: usize = try std.fmt.parseInt(usize, args[2], 10);
        if (k < 1) {
            try std.io.getStdOut().writer().print("Value of input k parameter is incorrect\n", .{});
            std.process.exit(1);
        }

        const x: [][]f64 = try help.readData(args[1], used_alloctor);
        defer {
            for (x) |*xi| used_alloctor.free(xi.*);
            used_alloctor.free(x);
        }

        if (k > x.len) {
            try std.io.getStdOut().writer().print("Value of input k parameter is incorrect\n", .{});
            std.process.exit(1);
        }

        const start = try std.time.Instant.now();
        const y: []usize = try kmeans.kmeans(x, k, used_alloctor);
        defer used_alloctor.free(y);
        const end = try std.time.Instant.now();
        const elapsed_us = end.since(start) / 1000;

        try std.io.getStdOut().writer().print("Time for k-means clustering: {} usec\n", .{elapsed_us});
        if (args.len > 4) {
            const perfect: []usize = try help.readArrayFromFile(usize, args[4], used_alloctor);
            defer used_alloctor.free(perfect);
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
