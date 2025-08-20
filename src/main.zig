// Disclaimer:
// This this project was rushed, and I did not do any refactoring at all.
// I know it's bad. Yes, I could fix it. No, I won't. It works!

// ⚠ Warnings:
// Procede with caution.
// Some code may cause experienced developers to cry.

// Still want to read it? Go ahead. I believe in you! (No, not really)

const std = @import("std");
const io = std.io;
const posix = std.posix;

const Grid = @import("grid.zig");

pub const Terminal = struct {
    stdout: std.fs.File,
    stdin: std.fs.File,
    writer: std.fs.File.Writer,

    original_termios: ?posix.termios = null,

    fn enableRawMode(self: *Terminal) !void {
        const handle = self.stdin.handle;

        self.original_termios = try posix.tcgetattr(handle);
        var termios = self.original_termios orelse @panic("original_termios unexpectedly null");

        // https://viewsourcecode.org/snaptoken/kilo/02.enteringRawMode.html
        // TCSETATTR(3)
        // reference: void cfmakeraw(struct termios *t)

        termios.iflag.BRKINT = false;
        termios.iflag.ICRNL = false;
        termios.iflag.INPCK = false;
        termios.iflag.ISTRIP = false;
        termios.iflag.IXON = false;

        // important: this means \n doesn't result in \r\n so \r\n must be written manually
        termios.oflag.OPOST = false;

        termios.lflag.ECHO = false;
        termios.lflag.ICANON = false;
        termios.lflag.IEXTEN = false;
        termios.lflag.ISIG = false;

        termios.cflag.CSIZE = .CS8;

        termios.cc[@intFromEnum(posix.V.MIN)] = 0; // non blocking read
        termios.cc[@intFromEnum(posix.V.TIME)] = 0;

        // apply changes
        try posix.tcsetattr(handle, .FLUSH, termios);
    }

    fn resetTerminal(self: *Terminal) !void {
        const termios = self.original_termios orelse @panic("Called reset terminal before entering raw mode.");
        try posix.tcsetattr(self.stdin.handle, .FLUSH, termios);
    }

    fn readByte(self: *Terminal) !u8 {
        var buf: [1]u8 = undefined;
        _ = try self.stdin.read(&buf);
        return buf[0];
    }

    pub fn resetCursorPosition(self: *Terminal) !void {
        try self.print("\x1b[{d}A", .{Grid.NUM_ROWS + 2});
    }

    fn hideCursor(self: *Terminal) !void {
        try self.print("\x1b[?25l", .{});
    }

    fn showCursor(self: *Terminal) !void {
        try self.print("\x1b[?25h", .{});
    }

    fn print(self: *Terminal, comptime format: []const u8, args: anytype) !void {
        try self.writer.print(format, args);
    }

    fn setColor(self: *Terminal, color: u8) !void {
        try self.print("\x1b[1;{}m", .{color});
    }

    fn setColorToDimColor(self: *Terminal, color: u8) !void {
        try self.print("\x1b[2;{}m", .{color});
    }
};

pub const Renderer = struct {
    term: *Terminal,

    pub fn blitCells(self: *Renderer, cells: [Grid.NUM_ROWS][Grid.NUM_COLS]Grid.CellVal) !void {
        try self.term.setColor(89);
        try self.term.print("\r", .{});
        for (0..Grid.NUM_ROWS + 2) |r| {
            for (0..Grid.NUM_COLS + 2) |c| {
                // if ((c + r + 0) % 2 == 0) {
                //     try self.term.print("██", .{});
                // } else {
                //     try self.term.print("  ", .{});
                // }
                if (r == 0) {
                    if (c == 0) {
                        try self.term.print(" ╭", .{});
                    } else if (c == Grid.NUM_COLS + 1) {
                        try self.term.print("╮ ", .{});
                    } else {
                        try self.term.print("──", .{});
                    }
                } else if (r == Grid.NUM_ROWS + 1) {
                    // if (c == 0) {
                    //     try self.term.print(" ╰", .{});
                    // } else if (c == Grid.NUM_COLS + 1) {
                    //     try self.term.print("╯", .{});
                    // } else {
                    //     try self.term.print("──", .{});
                    // }
                } else if (c == 0) {
                    try self.term.print(" │", .{});
                } else if (c == Grid.NUM_COLS + 1) {
                    try self.term.print("│ ", .{});
                } else {
                    const cellR = r - 1;
                    const cellC = c - 1;
                    if (cells[cellR][cellC].isTetronimo() or cells[cellR][cellC].isPlaced()) {
                        switch (cells[cellR][cellC]) {
                            .tetronimo_l, .placed_l => try self.term.setColor(97),
                            .tetronimo_j, .placed_j => try self.term.setColor(92),
                            .tetronimo_i, .placed_i => try self.term.setColor(91),
                            .tetronimo_t, .placed_t => try self.term.setColor(93),
                            .tetronimo_o, .placed_o => try self.term.setColor(94),
                            .tetronimo_s, .placed_s => try self.term.setColor(95),
                            .tetronimo_z, .placed_z => try self.term.setColor(96),
                            else => @panic("unknown tetronimo type"),
                        }
                        // try self.term.setColor(33);
                        if (cells[cellR][cellC].isTetronimo()) {
                            try self.term.print("░░", .{});
                        } else if (cells[cellR][cellC].isPlaced()) {
                            // try self.term.print("██", .{});
                            // try self.term.print("🟥🟥", .{});
                            try self.term.print("▒▒", .{});
                        }
                        try self.term.setColor(37);
                        try self.term.print("\x1b[1;37m", .{});
                    } else {
                        try self.term.print("  ", .{});
                    }
                }
            }
            try self.term.print("\r\n", .{});
        }
        // try self.term.print("\r\n", .{});
    }
};

var rate: u8 = 5;

pub fn main() !void {
    var term = Terminal{
        .stdout = io.getStdOut(),
        .stdin = io.getStdIn(),
        .writer = io.getStdOut().writer(),
    };
    var renderer = Renderer{ .term = &term };
    try term.enableRawMode();
    try term.hideCursor();
    var grid = Grid.init(term, renderer);
    try term.print("\n", .{});
    // try term.print("\n", .{});

    // for (0..255) |n| {
    //     try term.setColor(@as(u8, @intCast(n)));
    //     try term.print("██ is {}", .{n});
    // }
    // std.time.sleep(std.time.ns_per_s); // 1 sec
    // try term.resetCursor();
    // try renderer.blitCells(grid.cells);

    var running = true;
    var count: usize = 0;
    while (running) {
        const input = try term.readByte();

        var validInput = true;
        switch (input) {
            'h' => grid.tryMoveTetronimoLeft(),
            'l' => grid.tryMoveTetronimoRight(),
            'j' => grid.tryMoveTetronimoDown(),
            ' ' => try grid.hardDrop(),
            ';' => grid.rotateTetronimoAntiClockwise(),
            'k' => grid.rotateTetronimoClockwise(),
            'q' => running = false,
            else => validInput = false, // S
            // 2768 => grid.canMoveTetronimoLeft(),
            // else => try term.print("\n\n{}", .{input}),
        }

        // std.debug.print("{c}", .{input});

        // try term.print("{}", .{input});

        // your eyes will BURN
        if (validInput) {
            grid.refreshTetronimos();
            grid.blitTetronimo();
            std.debug.print("{}", .{10});
            try renderer.blitCells(grid.cells);
            try term.resetCursorPosition();
            try term.print("\x1b[{d}C", .{10}); // Move right
            // try term.print("\x1b[{d}A", .{1}); // Move up
            // try term.setColor(96);
            try term.print("zetr", .{});
            try term.setColor(39);
            // try term.print("\x1b[{d}B", .{1}); // Move down
            try term.print("\x1b[{d}D", .{10}); // Move left
        } else if (count % rate == 0) {
            try grid.updateGrid();
            // // Move cursor up
            // try term.stdout.print("\x1b[{d}A", .{move_up}); // Move up
            // Move cursor right
            try renderer.blitCells(grid.cells);
            try term.resetCursorPosition();

            try term.print("\x1b[{d}C", .{10}); // Move right
            // try term.print("\x1b[{d}A", .{1}); // Move up
            // try term.setColor(96);
            try term.print("zetr", .{});
            try term.setColor(39);
            // try term.print("\x1b[{d}B", .{1}); // Move down
            try term.print("\x1b[{d}D", .{10}); // Move left

            try term.print("\x1b[{d}C", .{21}); // Move right
            try term.print("\x1b[{d}B", .{0}); // Move down
            try term.print("\x1b[{d}A", .{1}); // Move up
            try term.setColor(39);
            try term.print("lines:", .{});
            try term.print("\x1b[{d}B", .{0}); // Move down
            try term.print("\x1b[{d}D", .{6}); // Move left
            // try io.getStdOut().writer().print("{d}", .{grid.getLineCount()});
            // const lineCount: u8 = 10;
            try term.print("{d}", .{Grid.lineCount});
            try term.setColor(39);
            try term.print("\x1b[{d}B", .{1}); // Move down
            try term.print("\x1b[{d}A", .{0}); // Move up
            try term.print("\x1b[{d}A", .{0}); // Move up
            try term.print("\x1b[{d}D", .{21}); // Move left

            try term.print("\x1b[{d}C", .{10}); // Move right
            // try term.print("\x1b[{d}A", .{1}); // Move up
            // try term.setColor(96);
            // try term.print("zetr", .{});
            try term.setColor(39);
            // try term.print("\x1b[{d}B", .{1}); // Move down
            try term.print("\x1b[{d}D", .{15}); // Move left

            try term.print("\x1b[{d}C", .{21}); // Move right
            try term.print("\x1b[{d}B", .{16}); // Move down
            try term.setColor(39);
            try term.print("\x1b[{d}C", .{4}); // Move right
            try term.print("next:", .{});
            try term.print("\x1b[{d}B", .{1}); // Move down
            try term.print("\x1b[{d}D", .{5}); // Move left
            // try io.getStdOut().writer().print("{d}", .{grid.getLineCount()});
            // const lineCount: u8 = 10;
            // try term.print("{d}", .{Grid.lineCount});

            const tetronimoColor: u8 = switch (grid.nextTetronimo.shapeIndex) {
                0 => 97,
                1 => 92,
                2 => 91,
                3 => 93,
                4 => 94,
                5 => 95,
                6 => 96,
                else => @panic("unknown tetronimo type"),
            };
            for (0..4) |r| {
                for (0..4) |c| {
                    if (grid.nextTetronimo.shape[r][c]) {
                        try term.setColor(tetronimoColor);
                        try term.print("▒▒", .{});
                    } else {
                        try term.setColor(39);
                        try term.print("・", .{});
                    }
                }
                try term.print("\x1b[{d}D", .{8}); // Move left
                try term.print("\n", .{});
            }
            try term.print("\x1b[{d}A", .{4}); // Move up

            try term.setColor(39);
            try term.print("\x1b[{d}A", .{16}); // Move up
            try term.print("\x1b[{d}A", .{1}); // Move up
            try term.print("\x1b[{d}D", .{20}); // Move left
        }

        std.time.sleep(std.time.ns_per_s * 0.05); // .1 sec

        count += 1;
    }
    running = false;
    // _ = try term.readByte();

    // // _ = try stdin.readByte();
    // const bytesRead = try stdin.read(buf[0..1]);
    // _ = bytesRead;
    try term.resetTerminal();
    try term.showCursor();
}
