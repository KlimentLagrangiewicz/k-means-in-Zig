const std = @import("std");
const kmeans = @import("k-means");
const help = @import("help");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    if (args.len < 6) {
        try std.io.getStdOut().writer().print("Not enough parameters\n", .{});
    } else {
        const n: usize = try std.fmt.parseInt(usize, args[2], 10);
        const m: usize = try std.fmt.parseInt(usize, args[3], 10);
        const k: usize = try std.fmt.parseInt(usize, args[4], 10);
        if (n < 1 or m < 1 or k < 1 or k > n) {
            try std.io.getStdOut().writer().print("Values of input parameters are incorrect\n", .{});
            std.process.exit(1);
        }
        const x: [][]f64 = try help.readData(args[1], n, m);
        defer {
            for (x) |*xi| std.heap.c_allocator.free(xi.*);
            std.heap.c_allocator.free(x);
        }
        const y: []usize = try kmeans.kmeans(x, k);
        defer std.heap.c_allocator.free(y);
        if (args.len > 6) {
            const perfect: []usize = try help.readArrayFromFile(usize, args[6]);
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
            try std.io.getStdOut().writer().print("The result of clustering using k-means:\nPrecision coefficient\t= {d:}\nRecall coefficient\t= {d:}\nCzekanowski-Dice index\t= {d:}\nFolkes-Mallows index\t= {d:}\nHubert index\t\t= {d:}\nJaccard index\t\t= {d:}\nKulczynski index\t= {d:}\nMcNemar index\t\t= {d:}\nPhi index\t\t= {d:}\nRand index\t\t= {d:}\nRogers-Tanimoto index\t= {d:}\nRussel-Rao index\t= {d:}\nSokal-Sneath I index\t= {d:}\nSokal-Sneath II index\t= {d:}\n", .{ p, rc, cdi, fmi, hi, ji, ki, mni, phi, randi, rti, rri, s1i, s2i });
            try help.writeFullResult(args[5], y, p, rc, cdi, fmi, hi, ji, ki, mni, phi, randi, rti, rri, s1i, s2i);
        } else try help.writeResult(args[5], y);
    }
}
