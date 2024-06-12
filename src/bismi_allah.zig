//بسم الله الرحمن الرحيم
//la ilaha illa Allah Mohammed Rassoul Allah
const std = @import("std");
const tt = @import("libtask-tree");
const rl = @import("raylib");
const rgui = @import("raylib-gui");

const TASK_WIDTH = 100;
const TASK_HEIGHT = 120;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const tlist = try tt.Tlist.new(allocator);

    read_from_save_file: {
        const file = std.fs.cwd().openFile("bismi_allah.ltt", .{}) catch |e| switch (e) {
            std.fs.Dir.OpenError.FileNotFound => break :read_from_save_file,
            else => return e,
        };
        tlist.readFromStream(file, true) catch |e| switch (e) {
            tt.Tlist.Error.DataIsNull => {},
            else => return e,
        };
        file.close();
    }

    rl.initWindow(1200, 600, "بسم الله الرحمن الرحيم");
    defer rl.closeWindow();

    var camera = rl.Camera2D{ .offset = rl.Vector2.init(0, 0), .target = rl.Vector2.init(0, 0), .rotation = 0, .zoom = 1 };

    rl.setTargetFPS(60);
    rl.setWindowState(rl.ConfigFlags.flag_window_resizable);

    const ControlPanel = struct {
        buffer: [34:0]u8 = [34:0]u8{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        rec: rl.Rectangle,
    };

    var control_panel = ControlPanel{
        .rec = rl.Rectangle{ .x = 20, .y = 20, .width = 100, .height = 40 },
    };
    control_panel.buffer[0] = 0;
    control_panel.buffer[control_panel.buffer.len - 1] = 0;
    var selected_task: u32 = 0;

    const StateMachine = enum {
        Idle,

        TlistMenu,

        TaskSelect,
        TaskMove,

        TaskConnectParent,
        TaskConnectChild,
        TaskConnectNext,
        TaskConnectPrev,
    };
    var state_machine: StateMachine = StateMachine.Idle;

    while (!rl.windowShouldClose()) {
        // TODO: by the will of Allah make it keyboard-only (kinda of)
        const mouse_pos = rl.getScreenToWorld2D(rl.getMousePosition(), camera);
        const delta = rl.getMouseDelta();

        if (rl.isKeyDown(.key_left_control) and rl.isKeyDown(.key_up)) {
            camera.zoom += 0.01;
        } else if (rl.isKeyDown(.key_left_control) and rl.isKeyDown(.key_down)) {
            camera.zoom -= 0.01;
        } else if (rl.isKeyDown(.key_up)) {
            camera.target.y -= 4;
        } else if (rl.isKeyDown(.key_down)) {
            camera.target.y += 4;
        } else if (rl.isKeyDown(.key_left)) {
            camera.target.x -= 4;
        } else if (rl.isKeyDown(.key_right)) {
            camera.target.x += 4;
        }

        // -------------------------------------------------------------------------------------------------------------------------------------
        //                                                      handle state
        // -------------------------------------------------------------------------------------------------------------------------------------
        // state with the help of Allah
        // if a task is clicked it becomes TaskKSelect|TaskMove
        state_machine = handle_state: {
            // if there was no mouse no state was changed or stopped moving a task
            if (!(rl.isMouseButtonDown(.mouse_button_left) or rl.isMouseButtonDown(.mouse_button_right))) {
                if (.TaskMove == state_machine) break :handle_state .TaskSelect;
                break :handle_state state_machine;
            }

            // stopped moving a task
            if (.TaskMove == state_machine and !rl.isMouseButtonDown(.mouse_button_left)) break :handle_state .TaskSelect;

            if (null != tlist.data) {
                // incha'Allah will test the selected task first
                {
                    const task = try tlist.getTask(selected_task);
                    if (StateMachine.TaskSelect == state_machine) {
                        var vec = rl.Vector2{ .x = task.x, .y = task.y + (TASK_HEIGHT / 3) };
                        if (rl.checkCollisionPointCircle(rl.getMousePosition(), vec, 15)) {
                            break :handle_state .TaskConnectPrev;
                        }
                        vec.x += TASK_WIDTH;
                        if (rl.checkCollisionPointCircle(rl.getMousePosition(), vec, 15)) {
                            break :handle_state .TaskConnectNext;
                        }
                        vec.x -= TASK_WIDTH / 2;
                        vec.y = task.y;
                        if (rl.checkCollisionPointCircle(rl.getMousePosition(), vec, 15)) {
                            break :handle_state .TaskConnectParent;
                        }
                        vec.y += TASK_HEIGHT;
                        if (rl.checkCollisionPointCircle(rl.getMousePosition(), vec, 15)) {
                            break :handle_state .TaskConnectChild;
                        }
                    } else if (rl.checkCollisionPointRec(rl.getMousePosition(), .{ .x = task.x, .y = task.y, .width = TASK_WIDTH, .height = TASK_HEIGHT })) {
                        if (rl.isMouseButtonDown(.mouse_button_left)) {
                            selected_task = task.id;
                            if (0 != delta.x or 0 != delta.y) break :handle_state .TaskMove;
                            break :handle_state .TaskSelect;
                        }
                    }
                }

                for (tlist.data.?) |task| {
                    if (null == task) continue;
                    if (rl.isMouseButtonDown(.mouse_button_left) and rl.checkCollisionPointRec(rl.getMousePosition(), .{ .x = task.?.x, .y = task.?.y, .width = TASK_WIDTH, .height = TASK_HEIGHT })) {
                        switch (state_machine) {
                            .TaskConnectChild => {
                                if (tlist.data.?[selected_task].?.hasChildId(task.?.id)) {
                                    try tlist.taskRemoveChildId(tlist.data.?[selected_task].?.id, task.?.id, true);
                                } else {
                                    tlist.taskAddChildId(tlist.data.?[selected_task].?.id, task.?.id, true) catch |e| if (tt.Tlist.Error.TaskCanNotBeGrandChildOfItSelf != e) return e;
                                }
                                break :handle_state .TaskSelect;
                            },
                            .TaskConnectParent => {
                                if (tlist.data.?[selected_task].?.hasParentId(task.?.id)) {
                                    try tlist.taskRemoveParentId(tlist.data.?[selected_task].?.id, task.?.id, true);
                                } else {
                                    tlist.taskAddParentId(tlist.data.?[selected_task].?.id, task.?.id, true) catch |e| if (tt.Tlist.Error.TaskCanNotBeGrandChildOfItSelf != e) return e;
                                }
                                break :handle_state .TaskSelect;
                            },
                            .TaskConnectNext => {
                                if (tlist.data.?[selected_task].?.hasNextId(task.?.id)) {
                                    try tlist.taskRemoveNextId(tlist.data.?[selected_task].?.id, task.?.id);
                                } else {
                                    tlist.taskAddNextId(tlist.data.?[selected_task].?.id, task.?.id) catch |e| if (tt.Tlist.Error.TaskCanNotBeNextOfItSelf != e) return e;
                                }
                                break :handle_state .TaskSelect;
                            },
                            .TaskConnectPrev => {
                                if (tlist.data.?[selected_task].?.hasPreviousId(task.?.id)) {
                                    try tlist.taskRemovePreviousId(tlist.data.?[selected_task].?.id, task.?.id);
                                } else {
                                    tlist.taskAddPreviousId(tlist.data.?[selected_task].?.id, task.?.id) catch |e| if (tt.Tlist.Error.TaskCanNotBeNextOfItSelf != e) return e;
                                }
                                break :handle_state .TaskSelect;
                            },
                            else => {
                                selected_task = task.?.id;
                                if (0 != delta.x or 0 != delta.y) break :handle_state .TaskMove;
                                break :handle_state .TaskSelect;
                            },
                        }
                    }
                }
            }

            // we ask the help of Allah

            if (.TlistMenu == state_machine and rl.isMouseButtonDown(.mouse_button_left) and rl.checkCollisionPointRec(rl.getMousePosition(), control_panel.rec)) break :handle_state .TlistMenu;

            if (rl.isMouseButtonDown(.mouse_button_right)) {
                control_panel.rec.x = mouse_pos.x;
                control_panel.rec.y = mouse_pos.y;
                break :handle_state .TlistMenu;
            }

            // if no task was clicked
            break :handle_state .Idle;
        };

        // react to state machine by the will of Allah
        react_to_state: {
            switch (state_machine) {
                .TaskMove => {
                    if (null != tlist.data) {
                        const task = try tlist.getTask(selected_task);
                        task.x += delta.x;
                        task.y += delta.y;
                    }
                },
                .TaskSelect => {
                    if (rl.isKeyPressed(.key_delete)) {
                        try tlist.removeTaskById(selected_task, true);
                    }
                    break :react_to_state;
                },
                else => {},
            }
        }

        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(rl.Color.gray);

        camera.begin();
        defer camera.end();
        // -------------------------------------------------------------------------------------------------------------------------------------
        //                                                      draw tasks
        // -------------------------------------------------------------------------------------------------------------------------------------

        // rgui.SetMousePosition(@intFromFloat(mouse_pos.x), @intFromFloat(mouse_pos.y));
        if (null != tlist.data) {
            for (tlist.data.?) |task| {
                if (null == task) continue;
                rl.drawRectangleRec(.{ .x = task.?.x, .y = task.?.y, .width = TASK_WIDTH, .height = TASK_HEIGHT }, rl.Color.lime);
                rgui.GuiDrawText(&task.?.name, .{ .x = task.?.x, .y = task.?.y + 2, .width = 100, .height = 20 }, 0, .{ .r = 0, .g = 0, .b = 0, .a = 255 });

                if (null != task.?.children_ids) {
                    for (task.?.children_ids.?) |child_id| {
                        rl.drawLineBezier(rl.Vector2{ .x = task.?.x + (TASK_WIDTH / 2), .y = task.?.y + TASK_HEIGHT }, rl.Vector2{ .x = tlist.data.?[child_id].?.x + (TASK_WIDTH / 2), .y = tlist.data.?[child_id].?.y }, 7, rl.Color.orange);
                    }
                }

                if (null != task.?.previous_tasks_ids) {
                    for (task.?.previous_tasks_ids.?) |previous_id| {
                        rl.drawLineBezier(rl.Vector2{ .x = task.?.x, .y = task.?.y + (TASK_HEIGHT / 2) }, rl.Vector2{ .x = tlist.data.?[previous_id].?.x + TASK_WIDTH, .y = tlist.data.?[previous_id].?.y + (TASK_HEIGHT / 3) }, 7, rl.Color.beige);
                    }
                }
            }
        }

        switch (state_machine) {
            .TlistMenu => {
                rl.drawRectangleRec(control_panel.rec, rl.Color.brown);
                _ = rgui.GuiTextBox(.{ .x = control_panel.rec.x + 1, .y = control_panel.rec.y + 5, .width = control_panel.rec.width - 2, .height = 15 }, &control_panel.buffer, 34, true);
                if (0 != control_panel.buffer[0] and 0 != rgui.GuiButton(.{ .x = control_panel.rec.x + 1, .y = control_panel.rec.y + 20, .width = control_panel.rec.width - 2, .height = 15 }, "new task")) {
                    const task = try tt.Task.new(allocator);
                    task.setName(&control_panel.buffer);
                    task.x = control_panel.rec.x;
                    task.y = control_panel.rec.y;
                    try tlist.addTask(task);
                    control_panel.buffer[0] = 0;
                }
            },
            .TaskSelect, .TaskMove => {
                var vec = rl.Vector2{ .x = tlist.data.?[selected_task].?.x, .y = tlist.data.?[selected_task].?.y + (TASK_HEIGHT / 3) };
                rl.drawCircleV(vec, 15, rl.Color.blue);
                vec.x += TASK_WIDTH;
                rl.drawCircleV(vec, 15, rl.Color.blue);
                vec.x -= TASK_WIDTH / 2;
                vec.y = tlist.data.?[selected_task].?.y;
                rl.drawCircleV(vec, 15, rl.Color.blue);
                vec.y += TASK_HEIGHT;
                rl.drawCircleV(vec, 15, rl.Color.blue);
            },
            .TaskConnectChild => {
                rl.drawLineBezier(rl.Vector2{ .x = tlist.data.?[selected_task].?.x + (TASK_WIDTH / 2), .y = tlist.data.?[selected_task].?.y + TASK_HEIGHT }, rl.getMousePosition(), 7, rl.Color.orange);
            },
            .TaskConnectParent => {
                rl.drawLineBezier(rl.Vector2{ .x = tlist.data.?[selected_task].?.x + (TASK_WIDTH / 2), .y = tlist.data.?[selected_task].?.y }, rl.getMousePosition(), 7, rl.Color.orange);
            },
            .TaskConnectNext => {
                rl.drawLineBezier(rl.Vector2{ .x = tlist.data.?[selected_task].?.x + TASK_WIDTH, .y = tlist.data.?[selected_task].?.y + (TASK_HEIGHT / 3) }, rl.getMousePosition(), 7, rl.Color.beige);
            },
            .TaskConnectPrev => {
                rl.drawLineBezier(rl.Vector2{ .x = tlist.data.?[selected_task].?.x, .y = tlist.data.?[selected_task].?.y + (TASK_HEIGHT / 3) }, rl.getMousePosition(), 7, rl.Color.beige);
            },
            else => {},
        }
    }

    const file = std.fs.cwd().createFile("bismi_allah.ltt", std.fs.File.CreateFlags{ .read = true }) catch |e| {
        try tlist.clear();
        allocator.destroy(tlist);
        return e;
    };
    tlist.saveToStream(file) catch |e| if (tt.Tlist.Error.DataIsNull != e) return e;
    file.close();

    try tlist.clear();
    allocator.destroy(tlist);
}
