const std = @import("std");
const kmeans = @import("k-means.zig");
const help = @import("help.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    if (args.len < 3) {
        try std.io.getStdOut().writer().print("Not enough parameters\n", .{});
    } else {
        var k: usize = 1;
        const x: [][]f64 = try help.readData(args[1], &k);
        defer {
            for (x) |*xi| std.heap.c_allocator.free(xi.*);
            std.heap.c_allocator.free(x);
        }
        const y: []usize = try kmeans.kmeans(x, k);
        defer std.heap.c_allocator.free(y);
        if (args.len > 3) {
            const perfect: []usize = try help.getSplit(args[3]);
            defer std.heap.c_allocator.free(perfect);
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
            try std.io.getStdOut().writer().print("The result of clustering using k-means:\nPrecision coefficient\t= {d:8.5}\nRecall coefficient\t= {d:17}\nCzekanowski-Dice index\t= {d:17}\nFolkes-Mallows index\t= {d:17}\nHubert index\t\t= {d:17}\nJaccard index\t\t= {d:17}\nKulczynski index\t= {d:17}\nMcNemar index\t\t= {d:17}\nPhi index\t\t= {d:17}\nRand index\t\t= {d:17}\nRogers-Tanimoto index\t= {d:17}\nRussel-Rao index\t= {d:17}\nSokal-Sneath I index\t= {d:17}\nSokal-Sneath II index\t= {d:17}\n", .{ p, rc, cdi, fmi, hi, ji, ki, mni, phi, randi, rti, rri, s1i, s2i });
            try help.writeFullResult(args[2], y, p, rc, cdi, fmi, hi, ji, ki, mni, phi, randi, rti, rri, s1i, s2i);
        } else try help.writeResult(args[2], y);
    }
}