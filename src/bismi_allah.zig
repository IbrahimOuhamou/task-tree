//بسم الله الرحمن الرحيم
//la ilaha illa Allah Mohammed Rassoul Allah
const std = @import("std");
const tt = @import("libtask-tree");
const rl = @import("raylib");
const rgui = @import("raylib-gui");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const tlist = try tt.Tlist.new(allocator);

    rl.initWindow(800, 500, "بسم الله الرحمن الرحيم");

    defer rl.closeWindow();
    rl.setTargetFPS(60);

    const ControlPanel = struct {
        buffer: [34:0]u8 = [34:0]u8{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        rec: rl.Rectangle,
    };

    var control_panel = ControlPanel{
        .rec = rl.Rectangle{ .x = 20, .y = 20, .width = 100, .height = 150 },
    };
    control_panel.buffer[0] = 0;
    control_panel.buffer[control_panel.buffer.len - 1] = 0;
    var selected_task: u32 = 0;

    std.debug.print("la ilaha illa Allah {d}", .{rl.getFontDefault().recs.*.y});
    while (!rl.windowShouldClose()) {
        input: {
            if (rl.isMouseButtonDown(.mouse_button_left)) {
                if (rl.checkCollisionPointRec(rl.getMousePosition(), control_panel.rec)) {
                    const delta = rl.getMouseDelta();
                    control_panel.rec.x += delta.x;
                    control_panel.rec.y += delta.y;
                } else if (null != tlist.data) {
                    const delta = rl.getMouseDelta();
                    {
                        const task = try tlist.getTask(selected_task);
                        if (rl.checkCollisionPointRec(rl.getMousePosition(), .{ .x = task.x, .y = task.y, .width = 100, .height = 120 })) {
                            task.x += delta.x;
                            task.y += delta.y;
                            selected_task = task.id;
                            break :input;
                        }
                    }
                    for (tlist.data.?) |task| {
                        if (null == task) continue;
                        if (rl.checkCollisionPointRec(rl.getMousePosition(), .{ .x = task.?.x, .y = task.?.y, .width = 100, .height = 120 })) {
                            task.?.x += delta.x;
                            task.?.y += delta.y;
                            selected_task = task.?.id;
                            break :input;
                        }
                    }
                }
            }
        }

        rl.beginDrawing();
        defer rl.endDrawing();

        // draw control panel
        rl.drawRectangleRec(control_panel.rec, rl.Color.brown);
        _ = rgui.GuiTextBox(.{ .x = control_panel.rec.x + 1, .y = control_panel.rec.y + 5, .width = control_panel.rec.width - 2, .height = 15 }, &control_panel.buffer, 34, true);
        if (0 != rgui.GuiButton(.{ .x = control_panel.rec.x + 1, .y = control_panel.rec.y + 20, .width = control_panel.rec.width - 2, .height = 15 }, "new task")) {
            std.debug.print("alhamdo li Allah gonna add a new task with name '{s}'\n", .{control_panel.buffer});
            const task = try tt.Task.new(allocator);
            task.setName(&control_panel.buffer);
            try tlist.addTask(task);
        }

        // draw tasks
        if (null != tlist.data) {
            for (tlist.data.?) |task| {
                if (null == task) continue;
                rl.drawRectangleRec(.{ .x = task.?.x, .y = task.?.y, .width = 100, .height = 120 }, rl.Color.lime);
                rgui.GuiDrawText(&task.?.name, .{ .x = task.?.x, .y = task.?.y + 2, .width = 100, .height = 20 }, 0, .{ .r = 0, .g = 0, .b = 0, .a = 255 });
            }
        }

        rl.clearBackground(rl.Color.gray);
    }
    try tlist.free();
    allocator.destroy(tlist);
}
