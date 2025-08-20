const std = @import("std");

const shapes = [_][4][4]bool{
    // L
    .{
        .{ false, false, false, false },
        .{ false, true, true, false },
        .{ false, true, false, false },
        .{ false, true, false, false },
    },
    // J
    .{
        .{ false, false, false, false },
        .{ false, false, true, false },
        .{ false, false, true, false },
        .{ false, true, true, false },
    },
    // I
    .{
        .{ false, true, false, false },
        .{ false, true, false, false },
        .{ false, true, false, false },
        .{ false, true, false, false },
    },
    // T
    .{
        .{ false, false, false, false },
        .{ true, true, true, false },
        .{ false, true, false, false },
        .{ false, false, false, false },
    },
    // O
    .{
        .{ false, false, false, false },
        .{ false, true, true, false },
        .{ false, true, true, false },
        .{ false, false, false, false },
    },
    // S
    .{
        .{ false, false, false, false },
        .{ false, true, true, false },
        .{ true, true, false, false },
        .{ false, false, false, false },
    },
    // Z
    .{
        .{ false, false, false, false },
        .{ true, true, false, false },
        .{ false, true, true, false },
        .{ false, false, false, false },
    },
    // .{
    //     .{ false, false, false, false },
    //     .{ true, true, true, false },
    //     .{ false, true, false, false },
    //     .{ false, false, false, false },
    // },
};

const Pos = struct { r: i8, c: i8 };

shapeIndex: usize,
shape: [4][4]bool,
pos: Pos,

const Self = @This();

pub fn init(shapeIndex: usize, pos: Pos) Self {
    return Self{
        .shapeIndex = shapeIndex,
        .shape = shapes[shapeIndex],
        .pos = pos,
    };
}

pub fn rotateShapeClockwise(self: *Self) void {
    var result: [4][4]bool = .{.{false} ** 4} ** 4;
    for (0..4) |r| {
        for (0..4) |c| {
            result[r][3 - c] = self.shape[c][r];
            //        ^reverse           ^transpose
        }
    }
    self.shape = result;
    // std.debug.print("{any}", .{self.shape});
}

pub fn rotateShapeAntiClockwise(self: *Self) void {
    var result: [4][4]bool = .{.{false} ** 4} ** 4;
    for (0..4) |r| {
        for (0..4) |c| {
            result[3 - r][c] = self.shape[c][r];
            //        ^reverse           ^transpose
        }
    }
    self.shape = result;
    // std.debug.print("{any}", .{self.shape});
}

pub fn getShape(index: u8) [4][4]bool {
    return shapes[index];
}
