const std = @import("std");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;

// Typical BF code has 30,000 cells. This interpreter uses 2^16 cells instead.
// This is still valid according to all sources I read, and allows us to write
// more performant interpreter code.

const Command = enum {
    inc_cell,
    dec_cell,
    inc_ptr,
    dec_ptr,
    get_char,
    put_char,
    loop_start,
    loop_end,
};

const OptCommand = union(enum) {
    add_cell: u8, // wrapping value that is added to a cell
    add_ptr: u16, // wrapping value that is added to the pc
    clear, // Happy path for [-]
    get_char,
    put_char,
    loop_start: usize, // value points to the end of the loop
    loop_end: usize, // value points to the start of the loop
};

// Note that we use []const u8 instead of []u8, because we do not wish to
// modify the code bytes. Also note that we avoid passing std.ArrayList around,
// as we don't need to later mutate the tokens.
fn tokenize(gpa: Allocator, code: []const u8) ![]Command {
    // ArrayListUnmanaged is generally preferred over ArrayList, as we know
    // which methods do and do not allocate memory. It also saves space, as
    // it does not store the Allocator structure. In the future, the other
    // varient will be removed, replaced with ArrayListUnmanaged. Also note
    // the decl-literal syntax `.empty`, which is preferred to the alternative.
    var tokens: std.ArrayListUnmanaged(Command) = .empty;
    defer tokens.deinit(gpa);
    // ^ In all cases (error or otherwise) we want to deinitialize the list. In
    // the case that we would be returning an ArrayList directly, we would want
    // to use errdefer to help prevent memory leaks in our program.

    for (code) |c| {
        const command: Command = switch (c) {
            '>' => .inc_ptr,
            '<' => .dec_ptr,
            '+' => .inc_cell,
            '-' => .dec_cell,
            '.' => .put_char,
            ',' => .get_char,
            '[' => .loop_start,
            ']' => .loop_end,
            else => continue,
        };

        try tokens.append(gpa, command);
    }

    // You can choose to omit the `try` in a `return try`, it's currently
    // an opinion but may be hard required or not in the future.
    return try tokens.toOwnedSlice(gpa);
}

// In this function we will not actually link up the loop starts & ends,
// as further will manipulate and distort the IR
fn mapCommands(gpa: Allocator, tokens: []const Command) ![]OptCommand {
    var opt_commands: std.ArrayListUnmanaged(OptCommand) = .empty;
    defer opt_commands.deinit(gpa);

    // By allocating all of the space up-front, we don't need to call the
    // allocator constantly, and avoid the checks for inserting items.
    try opt_commands.ensureTotalCapacity(gpa, tokens.len);

    for (tokens) |cmd| {
        const opt_cmd: OptCommand = switch (cmd) {
            .inc_cell => .{ .add_cell = 1 },
            .dec_cell => .{ .add_cell = 255 },
            .inc_ptr => .{ .add_ptr = 1 },
            .dec_ptr => .{ .add_ptr = 65535 },
            .get_char => .get_char,
            .put_char => .put_char,
            .loop_start => .{ .loop_start = undefined },
            .loop_end => .{ .loop_end = undefined },
        };

        opt_commands.appendAssumeCapacity(opt_cmd);
    }

    return try opt_commands.toOwnedSlice(gpa);
}

// This function replaces all `[-]` with `clear`. Make sure that the same
// allocator used for `commands` is passed as gpa here. This function is more
// effective if we first fold multiple `add_cell`s into one `add_cell`.
fn optimizeClear(gpa: Allocator, commands_ptr: *[]OptCommand) !void {
    // Because we are going to be looking at several tokens in advance to check
    // if we can replace certain segments, I am going to write a simple little
    // finite state automata to handle this process efficiently. Zig's "labeled
    // switch statement" is perfect for this usecase.

    const commands = commands_ptr.*;
    var read_idx: usize = 0;
    var write_idx: usize = 0;

    scan: while (read_idx < commands.len) {
        // A `[-]` can only occur if there are at least 3 more commands
        // remaining in the list. This check ensures safe memory access.
        if (read_idx + 2 < commands.len) {
            const a = commands[read_idx];
            const b = commands[read_idx + 1];
            const c = commands[read_idx + 2];

            if (a == .loop_start and b == .add_cell and c == .loop_end) {
                // [-], [+], [---], [+++], etc. all work, yet [--] doesn't:
                if (b.add_cell % 2 == 1) {
                    commands[write_idx] = .clear;
                    write_idx += 1;
                    read_idx += 3;
                    continue :scan;
                }
            }
        }

        // The code reaches this point if we did not find the needle
        commands[write_idx] = commands[read_idx];
        write_idx += 1;
        read_idx += 1;
    }

    // Shrink the allocation to match our use
    commands_ptr.* = try gpa.realloc(commands, write_idx);
}

// This function replaces repetitions of commands with singular commands.
fn optimizeRepeats(gpa: Allocator, commands_ptr: *[]OptCommand) !void {
    const commands = commands_ptr.*;
    var read_idx: usize = 0;
    var write_idx: usize = 0;

    while (read_idx < commands.len) {
        switch (commands[read_idx]) {
            .add_cell => {
                // Consume all repeating + and - until you hit something else
                var increment: u8 = 0;
                eat: while (read_idx < commands.len) {
                    if (commands[read_idx] == .add_cell) {
                        increment +%= commands[read_idx].add_cell;
                        read_idx += 1;
                    } else {
                        break :eat;
                    }
                }
                // Insert the sum of the increments at the current writing ptr
                commands[write_idx] = .{ .add_cell = increment };
                write_idx += 1;
            },
            .add_ptr => {
                // Consume all repeating > and < until you hit something else
                var shift: u16 = 0;
                eat: while (read_idx < commands.len) {
                    if (commands[read_idx] == .add_ptr) {
                        shift +%= commands[read_idx].add_ptr;
                        read_idx += 1;
                    } else {
                        break :eat;
                    }
                }
                // Insert the sum of the shifts at the current writing ptr
                commands[write_idx] = .{ .add_ptr = shift };
                write_idx += 1;
            },
            else => {
                // If it is not something that can be repeated, place it at the
                // write position and advance to the next position.
                commands[write_idx] = commands[read_idx];
                read_idx += 1;
                write_idx += 1;
            },
        }
    }

    // Shrink the allocation to match our use
    commands_ptr.* = try gpa.realloc(commands, write_idx);
}

// Links the `loop_start` and `loop_end` states of OptCommand. This function
// should be called after all other command morphing functions are complete.
fn linkLoops(commands: []OptCommand) !void {
    loop_find: for (commands, 0..) |cmd, pc_idx| {
        switch (cmd) {
            .loop_end => {
                // Search backwards until we find the open to this loop
                var search: usize = pc_idx;

                // Keep track of the number of nested loops we are in
                var nest_count: usize = 0;
                while (search > 0) {
                    search -= 1;

                    // For each command we search through, we adjust the number
                    // of nested loops correctly, stopping when we encounter a
                    // `loop_start` outside of nested loops.
                    switch (commands[search]) {
                        .loop_end => nest_count += 1,
                        .loop_start => {
                            if (nest_count == 0) {

                                // We have found our goal, update both pointers
                                commands[pc_idx].loop_end = search;
                                commands[search].loop_start = pc_idx;

                                // Continue to link the remainder of the loops
                                continue :loop_find;
                            } else {
                                nest_count -= 1;
                            }
                        },
                        else => {},
                    }
                }

                // If we have reached this part of the program, then we failed
                // to find the start of a loop. There are more "]" than "[".
                return error.UnmatchedLoopClose;
            },
            .loop_start => {
                // Mark all of the `loop_start` commands as pointing to the max
                // value that a usize could represent. We do this so we can
                // later check if there is an unmatched loop start that was
                // never paired with a loop close. We are safe to do this as we
                // know that we will always reach `loop_start`s here before the
                // code that searches backwards for the match to a `loop_end`.
                commands[pc_idx].loop_start = std.math.maxInt(usize);
            },
            else => {},
        }
    }

    for (commands) |cmd| {
        // These two if statements can be combined with `and`, due to short-
        // circuiting operators, it would be the same. They are kept separate
        // here for readability.
        if (cmd == .loop_start) {
            if (cmd.loop_start == std.math.maxInt(usize)) {
                return error.UnmatchedLoopStart;
            }
        }
    }
}

fn execute(commands: []const OptCommand) !void {
    const unbuffered_stdout = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(unbuffered_stdout);
    const stdout = bw.writer();

    var pc: usize = 0;
    var ptr: u16 = 0;

    var mem: [65536]u8 = @splat(0);

    while (pc < commands.len) : (pc += 1) {
        switch (commands[pc]) {
            .add_ptr => |amt| ptr +%= amt,
            .add_cell => |amt| mem[ptr] +%= amt,
            .clear => mem[ptr] = 0,
            .loop_start => |end_idx| {
                if (mem[ptr] == 0) pc = end_idx;
            },
            .loop_end => |start_idx| {
                if (mem[ptr] != 0) pc = start_idx;
            },
            .get_char => {
                // BF may rely on the user knowing what has been printed for
                // certain same-line inputs. Thus, we flush the output here.
                try bw.flush();
                // TODO: read a byte from unbuffered stdin
            },
            .put_char => {
                try stdout.writeByte(mem[ptr]);
                if (mem[ptr] == '\n') try bw.flush();
            },
        }
    }
}

pub fn main() !void {
    const gpa = std.heap.smp_allocator;

    // Process command-line arguments
    const args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);
    if (args.len < 2) {
        std.debug.print("Usage: {s} <filename>\n", .{args[0]});
        std.process.exit(1);
    }

    // Open file
    const source_file = try std.fs.cwd().openFile(args[1], .{});
    defer source_file.close();

    // Personally I don't mind it if we support large programs
    const limit = std.math.maxInt(usize);
    const code = try source_file.readToEndAlloc(gpa, limit);
    defer gpa.free(code);

    // Notice how all the memory is clearly annotated with defer to free it at
    // the end of the program. We can tell the allocator to free memory right
    // after we use it, but the code looks a bit messier so I won't bother.

    const tokens = try tokenize(gpa, code);
    defer gpa.free(tokens);

    var commands = try mapCommands(gpa, tokens);
    defer gpa.free(commands);

    try optimizeRepeats(gpa, &commands);
    try optimizeClear(gpa, &commands);

    // TODO: here would be a good spot to switch on the errors and return
    // some more readable error for invalid BF code (loops not matching).
    try linkLoops(commands);

    // Allocates 64k stack
    try execute(commands);
}
