//بسم الله الرحمن الرحيم
//la ilaha illa Allah Mohammed Rassoul Allah
const std = @import("std");
const tt = @import("libtask-tree");
const rl = @import("raylib");

pub fn main() !void {
    rl.initWindow(800, 500, "بسم الله الرحمن الرحيم");

    defer rl.closeWindow();
    rl.setTargetFPS(60);

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.gray);
    }
}
