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

const OptCommand = union(enum) {
    addPtr: usize,
    subPtr: usize,
    addVal: u8,
    subVal: u8,
    zero,
    putChar,
    getChar,
    openBr: usize,
    closeBr: usize,
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

fn array_contains(comptime T: type, haystack: []const T, needle: T) bool {
    for (haystack) |element|
        if (element == needle)
            return true;
    return false;
}

fn cmd_to_optcmd(cmd: Command, count: usize) OptCommand {
    switch (cmd) {
        .incPtr => return .{ .addPtr = count},
        .decPtr => return .{ .subPtr = count},
        .incVal => return .{ .addVal = @intCast(count)},
        .decVal => return .{ .subVal = @intCast(count)},
        .putChar => return .putChar,
        .getChar => return .getChar,
        .openBr => return .{ .openBr = 0 },
        .closeBr => return .{ .closeBr = 0 },
    }
}

fn optimize_code(allocator: std.mem.Allocator, code: std.ArrayList(Command)) !std.ArrayList(OptCommand) {
    var result = std.ArrayList(OptCommand).init(allocator);
    var last_cmd: ?Command = null;
    var count: usize = 1;
    const opt_cmds: []const Command = &.{Command.incPtr, Command.decPtr, Command.incVal, Command.decVal};
    for (code.items) |cmd| {
        if (cmd == last_cmd and array_contains(Command, opt_cmds, cmd)) {
            count += 1;
        } else if (last_cmd != null) {
            try result.append(cmd_to_optcmd(last_cmd.?, count));
            count = 1;
        }
        last_cmd = cmd;
    }
    if (last_cmd != null) {
        try result.append(cmd_to_optcmd(last_cmd.?, count));
    }

    // Add jumps to enums
    var unsolved = std.ArrayList(usize).init(allocator);
    for (result.items, 0..) |cmd, i| {
        if (cmd == .openBr) {
            try unsolved.append(i);
        } else if (cmd == .closeBr) {
            const connection = unsolved.pop().?;
            result.items[connection] = .{.openBr = i};
            result.items[i] = .{.closeBr = connection};
        }
    }

    return result;
}

fn execute(prg: std.ArrayList(OptCommand)) !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    var prg_head: usize = 0;
    var mem = std.mem.zeroes([65535]u8);
    var mem_ptr: usize = 0;

    while (prg_head < prg.items.len) {
        switch (prg.items[prg_head]) {
            .addPtr => |count| mem_ptr += count,
            .subPtr => |count| mem_ptr -= count,
            .addVal => |count| mem[mem_ptr] +%= count,
            .subVal => |count| mem[mem_ptr] -%= count,
            .zero => mem[mem_ptr] = 0,
            .putChar => {
                try stdout.print("{c}", .{mem[mem_ptr]});
                if (mem[mem_ptr] == '\n') {
                    try bw.flush();
                }
            },
            .getChar => {},
            .openBr => |connection| {
                if (mem[mem_ptr] == 0) {
                    prg_head = connection;
                }
            },
            .closeBr => |connection| {
                if (mem[mem_ptr] != 0) {
                    prg_head = connection;
                }
            },
        }
        prg_head += 1;
    }
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
    const opt_program = try optimize_code(allocator, program);

    try execute(opt_program);
}

