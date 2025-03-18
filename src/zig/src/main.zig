const std = @import("std");

const Command = enum {
    incPtr,
    decPtr,
    incVal,
    decVal,
    putChar,
    getChar,
    openBr,
    closeBr,
};

fn parse_code(allocator: std.mem.Allocator, code: []u8) !std.ArrayList(Command) {
    var result = std.ArrayList(Command).init(allocator);
    for (code) |c| {
        switch (c) {
            '>' => try result.append(.incPtr),
            '<' => try result.append(.decPtr),
            '+' => try result.append(.incVal),
            '-' => try result.append(.decVal),
            '.' => try result.append(.putChar),
            ',' => try result.append(.getChar),
            '[' => try result.append(.openBr),
            ']' => try result.append(.closeBr),
            else => {},
        }
    }
    return result;
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    // Process command-line arguments.
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    if (args.len < 2) {
        std.debug.print("Usage: {s} <filename>\n", .{args[0]});
        return;
    }
    const filename = args[1];

    const cwd = std.fs.cwd();
    const file = try cwd.openFile(filename, .{});
    const code = try file.readToEndAlloc(allocator, 65535);
    defer allocator.free(code);

    const program = try parse_code(allocator, code);

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    var prg_head: usize = 0;
    var mem = std.mem.zeroes([65535]u8);
    var mem_ptr: usize = 0;

    while (prg_head < program.items.len) {
        switch (program.items[prg_head]) {
            .incPtr => mem_ptr += 1,
            .decPtr => mem_ptr -= 1,
            .incVal => mem[mem_ptr] +%= 1,
            .decVal => mem[mem_ptr] -%= 1,
            .putChar => {
                try stdout.print("{c}", .{mem[mem_ptr]});
                try bw.flush();
            },
            .getChar => {},
            .openBr => {
                if (mem[mem_ptr] == 0) {
                    var bracketBal: usize = 1;
                    while (bracketBal > 0) {
                        prg_head += 1;
                        if (program.items[prg_head] == .openBr) {
                            bracketBal += 1;
                        } else if (program.items[prg_head] == .closeBr) {
                            bracketBal -= 1;
                        }
                    }
                }
            },
            .closeBr => {
                var bracketBal: usize = 1;
                while (bracketBal > 0) {
                    prg_head -= 1;
                    if (program.items[prg_head] == .openBr) {
                        bracketBal -= 1;
                    } else if (program.items[prg_head] == .closeBr) {
                        bracketBal += 1;
                    }
                }
                prg_head -= 1;
            },
        }
        prg_head += 1;
    }
}
