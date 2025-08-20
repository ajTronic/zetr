const std = @import("std");
const Tetronimo = @import("tetronimo.zig");
const main = @import("main.zig");

pub const NUM_ROWS = 20;
pub const NUM_COLS = 10;

pub const CellVal = enum {
    // placed,
    // tetronimo,
    tetronimo_l,
    tetronimo_j,
    tetronimo_i,
    tetronimo_t,
    tetronimo_o,
    tetronimo_s,
    tetronimo_z,
    placed_l,
    placed_j,
    placed_i,
    placed_t,
    placed_o,
    placed_s,
    placed_z,
    empty,

    pub fn isTetronimo(self: CellVal) bool {
        return self == .tetronimo_l or
            self == .tetronimo_j or
            self == .tetronimo_i or
            self == .tetronimo_t or
            self == .tetronimo_o or
            self == .tetronimo_s or
            self == .tetronimo_z;
    }

    pub fn isPlaced(self: CellVal) bool {
        return self == .placed_l or
            self == .placed_j or
            self == .placed_i or
            self == .placed_t or
            self == .placed_o or
            self == .placed_s or
            self == .placed_z;
    }
};

cells: [NUM_ROWS][NUM_COLS]CellVal,
tetronimo: Tetronimo,
nextTetronimo: Tetronimo,
rand: std.Random,

term: main.Terminal,
renderer: main.Renderer,

pub var lineCount: u8 = 0;

const Self = @This();

pub fn reset(self: *Self) void {
    const rand = std.crypto.random; // yes: we be using cryptographically secure random numbers for tetris bois!
    self.cells = .{.{CellVal.empty} ** NUM_COLS} ** NUM_ROWS;
    self.nextTetronimo = Tetronimo.init(
        rand.intRangeAtMost(usize, 0, 6),
        .{ .r = 0, .c = NUM_COLS / 2 },
    );
    self.tetronimo = Tetronimo.init(
        rand.intRangeAtMost(usize, 0, 6),
        .{ .r = 0, .c = NUM_COLS / 2 },
    );
    self.rand = rand;
    lineCount = 0;
}

pub fn init(term: main.Terminal, renderer: main.Renderer) Self {
    // random initialisation
    // var prng = std.Random.DefaultPrng.init(blk: {
    //     var seed: u64 = undefined;
    //     try std.posix.getrandom(std.mem.asBytes(&seed));
    //     break :blk seed;
    // });
    // const rand = prng.random();
    // var prng = std.Random.DefaultPrng.init(blk: {
    //     var seed: u64 = undefined;
    //     try std.posix.getrandom(std.mem.asBytes(&seed));
    //     break :blk seed;
    // });

    var s: Self = undefined;
    s.term = term;
    s.renderer = renderer;
    s.reset();
    return s;

    // return Self{
    //     .cells = .{.{CellVal.empty} ** NUM_COLS} ** NUM_ROWS,
    //     .tetronimo = Tetronimo.init(
    //         rand.intRangeAtMost(usize, 0, 6),
    //         .{ .r = 0, .c = NUM_COLS / 2 },
    //     ),
    //     .rand = rand,
    // };
}

pub fn updateGrid(self: *Self) !void {
    if (self.canMoveTetronimoDown()) {
        self.refreshTetronimos();
        self.blitTetronimo();
        self.moveTetronimoDown();
    } else {
        self.solidifyTetronimo();
        try self.clearClearableRows();
        self.resetTetronimoPosition();
        self.newTetronimoShape();

        if (self.checkForGameOver()) {
            // std.debug.print("gameover", .{});
            self.reset();
        }
    }
}

pub fn getLineCount() u8 {
    return lineCount;
}

pub fn hardDrop(self: *Self) !void {
    while (self.canMoveTetronimoDown()) {
        self.refreshTetronimos();
        self.blitTetronimo();
        self.moveTetronimoDown();
    }
    self.solidifyTetronimo();
    try self.clearClearableRows();
    self.resetTetronimoPosition();
    self.newTetronimoShape();
    if (self.checkForGameOver()) {
        std.debug.print("gameover", .{});
        self.reset();
    }
}

pub fn checkForGameOver(self: *Self) bool {
    for (0..NUM_COLS) |c| {
        if (self.cells[1][c].isPlaced()) {
            return true;
        }
    }
    return false;
}

pub fn newTetronimoShape(self: *Self) void {
    self.tetronimo = self.nextTetronimo;
    self.nextTetronimo = Tetronimo.init(
        self.rand.intRangeAtMost(usize, 0, 6),
        .{ .r = 0, .c = NUM_COLS / 2 },
    );
}

pub fn moveTetronimoDown(self: *Self) void {
    self.tetronimo.pos.r += 1;
}

pub fn tryMoveTetronimoDown(self: *Self) void {
    if (self.canMoveTetronimoDown()) self.moveTetronimoDown();
}

pub fn solidifyTetronimo(self: *Self) void {
    var r: u8 = NUM_ROWS - 1;
    while (r >= 1) : (r -= 1) {
        for (0..NUM_COLS) |c| {
            if (self.cells[r][c].isTetronimo())
                self.cells[r][c] = self.getPlacedType();
        }
    }
}

fn getPlacedType(self: *Self) CellVal {
    return switch (self.tetronimo.shapeIndex) {
        0 => .placed_l,
        1 => .placed_j,
        2 => .placed_i,
        3 => .placed_t,
        4 => .placed_o,
        5 => .placed_s,
        6 => .placed_z,
        else => @panic("unknown tetronimo shape index"),
    };
}

pub fn blitTetronimo(self: *Self) void {
    // var r: u8 = self.tetronimo.pos.r;
    // while (r < self.tetronimo.pos.r + 4 and r < NUM_ROWS) {
    //     var c: u8 = self.tetronimo.pos.c;
    //     while (c < self.tetronimo.pos.c + 4 and c < NUM_COLS) {
    //         if (self.tetronimo.shape[r - self.tetronimo.pos.r][c - self.tetronimo.pos.c]) {
    //             self.cells[r][c] = CellVal.tetronimo;
    //             // std.debug.print(" r:{} c:{} ", .{ r, c });
    //         }
    //         c += 1;
    //     }
    //     r += 1;
    // }

    // for (0..4) |r| {
    //     for (0..4) |c| {
    //         std.debug.print("{any}\n", .{self.tetronimo.shape[r][c]});
    //         if (self.tetronimo.pos.r < r or self.tetronimo.pos.c < c) break;
    //         const targetRow: usize = r + @as(usize, @intCast(self.tetronimo.pos.r));
    //         const targetCol: usize = c + @as(usize, @intCast(self.tetronimo.pos.c));
    //         if (self.tetronimo.shape[r][c] and targetRow < NUM_ROWS and targetCol < NUM_COLS) {
    //             self.cells[targetRow][targetCol] = CellVal.tetronimo;
    //         }
    //     }
    // }
    for (0..4) |r| {
        for (0..4) |c| {
            // std.debug.print("{any}\n", .{self.tetronimo.shape[r][c]});
            if (-self.tetronimo.pos.c > c) continue;
            if (!self.tetronimo.shape[r][c]) continue;
            // const targetRow: usize = @intCast(@as(isize, r) + @as(isize, @intCast(self.tetronimo.pos.r)));
            // const targetCol: usize = @intCast(@as(isize, c) + @as(isize, @intCast(self.tetronimo.pos.c)));

            // std.debug.print("{} {} \n", .{ self.tetronimo.pos.c, c });
            const targetRow: usize = @intCast(@as(i8, @intCast(r)) + self.tetronimo.pos.r);
            const targetCol: usize = @intCast(@as(i8, @intCast(c)) + self.tetronimo.pos.c);
            if (targetRow < NUM_ROWS and targetCol < NUM_COLS) {
                self.cells[targetRow][targetCol] = self.getTetronimoType();
            }
        }
    }
    // _ = self;
}

fn getTetronimoType(self: *Self) CellVal {
    return switch (self.tetronimo.shapeIndex) {
        0 => .tetronimo_l,
        1 => .tetronimo_j,
        2 => .tetronimo_i,
        3 => .tetronimo_t,
        4 => .tetronimo_o,
        5 => .tetronimo_s,
        6 => .tetronimo_z,
        else => @panic("unknown tetronimo shape index"),
    };
}

pub fn canMoveTetronimoDown(self: *Self) bool {
    var c: u8 = 0;
    while (c < NUM_COLS) : (c += 1) {
        if (self.cells[NUM_ROWS - 1][c].isTetronimo()) {
            return false;
        }
    }
    var r: u8 = 0;
    while (r < NUM_ROWS - 1) : (r += 1) {
        c = 0;
        while (c < NUM_COLS) : (c += 1) {
            if (self.cells[r][c].isTetronimo() and self.cells[r + 1][c].isPlaced()) {
                return false;
            }
        }
    }
    return true;
}

pub fn resetTetronimoPosition(self: *Self) void {
    self.tetronimo.pos.r = 0;
    self.tetronimo.pos.c = NUM_COLS / 2;
}

pub fn clearClearableRows(self: *Self) !void {
    // try self.renderer.blitCells(self.cells);
    // try self.term.resetCursorPosition();
    var r: u8 = 0;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator: std.mem.Allocator = gpa.allocator();
    var rowsToShift = std.ArrayList(u8).init(allocator);
    defer rowsToShift.deinit();
    while (r < NUM_ROWS) : (r += 1) {
        if (self.isRowFilled(r)) {
            try self.renderer.blitCells(self.cells);
            try self.term.resetCursorPosition();
            std.time.sleep(std.time.ns_per_s * 0.1);
            self.clearRow(r);
            std.time.sleep(std.time.ns_per_s * 0.1);
            // self.shiftGridDown(r);
            // std.debug.print("should shift {}\n", .{r});
            try rowsToShift.append(r);
        }
    }
    if (rowsToShift.items.len > 0) {
        try self.renderer.blitCells(self.cells);
        try self.term.resetCursorPosition();
        std.time.sleep(std.time.ns_per_s * 0.1);
        // self.updateGrid();

        for (rowsToShift.items) |rowToShift| {
            // std.debug.print("shifting {}\n", .{rowToShift});
            self.shiftGridDown(rowToShift);
            lineCount += 1;
        }
        // std.debug.print("line!{}", .{self.lineCount});
    }
}

pub fn isRowFilled(self: *Self, r: u8) bool {
    var c: u8 = 0;
    while (c < NUM_COLS) : (c += 1) {
        // std.debug.print("{}\n", .{self.cells[r][c]});
        if (self.cells[r][c] == CellVal.empty) return false;
    }
    // std.debug.print("\n", .{});
    return true;
}

pub fn clearRow(self: *Self, r: u8) void {
    var c: u8 = 0;
    while (c < NUM_COLS) : (c += 1) {
        self.cells[r][c] = CellVal.empty;
    }
}

pub fn refreshTetronimos(self: *Self) void {
    var r: u8 = 0;
    while (r < NUM_ROWS) : (r += 1) {
        var c: u8 = 0;
        // if (r == 0) std.debug.print("yes", .{});
        while (c < NUM_COLS) : (c += 1) {
            if (self.cells[r][c].isTetronimo())
                self.cells[r][c] = CellVal.empty;
        }
    }
}

pub fn shiftGridDown(self: *Self, stopRow: u8) void {
    var r: u8 = stopRow - 1;
    while (r > 0) : (r -= 1) {
        var c: u8 = 0;
        while (c < NUM_COLS) : (c += 1) {
            self.cells[r + 1][c] = self.cells[r][c];
        }
    }
}

pub fn canMoveTetronimoLeft(self: *Self) bool {
    for (0..NUM_ROWS) |r| {
        if (self.cells[r][0].isTetronimo()) {
            return false;
        }
        for (1..NUM_COLS) |c| {
            if (self.cells[r][c].isTetronimo() and self.cells[r][c - 1].isPlaced()) {
                return false;
            }
        }
    }
    return true;
}

pub fn canMoveTetronimoRight(self: *Self) bool {
    for (0..NUM_ROWS) |r| {
        if (self.cells[r][NUM_COLS - 1].isTetronimo()) {
            return false;
        }
        for (0..NUM_COLS - 1) |c| {
            if (self.cells[r][c].isTetronimo() and self.cells[r][c + 1].isPlaced()) {
                return false;
            }
        }
    }
    return true;
}

pub fn tryMoveTetronimoLeft(self: *Self) void {
    if (!self.canMoveTetronimoLeft()) {
        return;
    }
    self.tetronimo.pos.c -= 1;
}

pub fn tryMoveTetronimoRight(self: *Self) void {
    if (!self.canMoveTetronimoRight()) {
        return;
    }
    self.tetronimo.pos.c += 1;
}

pub fn rotateTetronimoClockwise(self: *Self) void {
    self.tetronimo.rotateShapeClockwise();
    if (!self.wallKick()) {
        self.tetronimo.rotateShapeAntiClockwise(); // fail
    }
}

pub fn rotateTetronimoAntiClockwise(self: *Self) void {
    self.tetronimo.rotateShapeAntiClockwise();
    if (!self.wallKick()) {
        self.tetronimo.rotateShapeClockwise(); // fail
    }
}

pub fn wallKick(self: *Self) bool {
    // while (self.wallKickOffset() != 0) {
    //     self.tetronimo.pos.c += self.wallKickOffset();
    // }
    while (true) {
        var clean = true;
        for (0..4) |r| {
            for (0..4) |c| {
                // std.debug.print("{any}\n", .{self.tetronimo.shape[r][c]});
                // if (-self.tetronimo.pos.c > c) continue;
                if (!self.tetronimo.shape[r][c]) continue;
                // const targetRow: usize = @intCast(@as(isize, r) + @as(isize, @intCast(self.tetronimo.pos.r)));
                // const targetCol: usize = @intCast(@as(isize, c) + @as(isize, @intCast(self.tetronimo.pos.c)));

                // std.debug.print("{} {} \n", .{ self.tetronimo.pos.c, c });
                const targetRow: isize = @intCast(@as(i8, @intCast(r)) + self.tetronimo.pos.r);
                const targetCol: isize = @intCast(@as(i8, @intCast(c)) + self.tetronimo.pos.c);
                if (targetCol >= NUM_COLS) {
                    self.tetronimo.pos.c -= 1;
                    clean = false;
                } else if (targetCol < 0) {
                    self.tetronimo.pos.c += 1;
                    clean = false;
                } else if (targetRow >= NUM_ROWS) {
                    self.tetronimo.pos.r -= 1;
                    clean = false;
                } else if (self.cells[@as(usize, @intCast(targetRow))][@as(usize, @intCast(targetCol))].isPlaced()) {
                    // std.log.debug("false!", .{});
                    return false;
                }
            }
        }
        if (clean) return true;
    }
    std.debug.panic("this shouldn't happen. if it did, the wall kick failed.", .{});
    // for (0..4) |r| {
    //     for (0..4) |c| {
    //         // std.debug.print("{any}\n", .{self.tetronimo.shape[r][c]});
    //         // if (-self.tetronimo.pos.c > c) continue;
    //         if (!self.tetronimo.shape[r][c]) continue;
    //         // const targetRow: usize = @intCast(@as(isize, r) + @as(isize, @intCast(self.tetronimo.pos.r)));
    //         // const targetCol: usize = @intCast(@as(isize, c) + @as(isize, @intCast(self.tetronimo.pos.c)));

    //         // std.debug.print("{} {} \n", .{ self.tetronimo.pos.c, c });
    //         const targetCol: isize = @intCast(@as(i8, @intCast(c)) + self.tetronimo.pos.c);
    //         if (targetCol >= NUM_COLS) {
    //             std.debug.print("wall kik", .{});
    //             self.tetronimo.pos.c -= 1;
    //         }
    //         if (targetCol < 0) {
    //             std.debug.print("wall kik", .{});
    //             self.tetronimo.pos.c += 1;
    //         }
    //         const targetRow: usize = @intCast(@as(i8, @intCast(r)) + self.tetronimo.pos.r);
    //         if (targetRow >= NUM_ROWS) {

    //         }
    //     }
    // }
}

pub fn wallKickOffset(self: *Self) i2 {
    for (0..4) |r| {
        for (0..4) |c| {
            // std.debug.print("{any}\n", .{self.tetronimo.shape[r][c]});
            // if (-self.tetronimo.pos.c > c) continue;
            if (!self.tetronimo.shape[r][c]) continue;
            // const targetRow: usize = @intCast(@as(isize, r) + @as(isize, @intCast(self.tetronimo.pos.r)));
            // const targetCol: usize = @intCast(@as(isize, c) + @as(isize, @intCast(self.tetronimo.pos.c)));

            // std.debug.print("{} {} \n", .{ self.tetronimo.pos.c, c });
            // const targetRow: usize = @intCast(@as(i8, @intCast(r)) + self.tetronimo.pos.r);
            const targetCol: isize = @intCast(@as(i8, @intCast(c)) + self.tetronimo.pos.c);
            if (targetCol >= NUM_COLS) {
                return -1;
            }
            if (targetCol < 0) {
                return 1;
            }
        }
    }
    return 0;
}
