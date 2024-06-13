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
    rl.setExitKey(.key_null);
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
    var selected_task: ?*tt.Task = null;

    const StateMachine = enum {
        Idle,

        ViewMove,

        TlistMenu,

        TaskSelect,
        TaskMove,
        TaskRename,

        TaskConnectParent,
        TaskConnectChild,
        TaskConnectNext,
        TaskConnectPrev,
    };
    var state_machine: StateMachine = StateMachine.Idle;

    while (!rl.windowShouldClose()) {
        // TODO: by the will of Allah make it keyboard-only (kinda of)
        // const mouse_pos = rl.getScreenToWorld2D(rl.getMousePosition(), camera);
        // const delta = rl.getMouseDelta();

        // if (rl.isKeyDown(.key_left_control) and rl.isKeyDown(.key_up)) {
        //     camera.zoom += 0.01;
        // } else if (rl.isKeyDown(.key_left_control) and rl.isKeyDown(.key_down)) {
        //     camera.zoom -= 0.01;
        // } else if (rl.isKeyDown(.key_up)) {
        //     camera.target.y -= 4;
        // } else if (rl.isKeyDown(.key_down)) {
        //     camera.target.y += 4;
        // } else if (rl.isKeyDown(.key_left)) {
        //     camera.target.x -= 4;
        // } else if (rl.isKeyDown(.key_right)) {
        //     camera.target.x += 4;
        // }

        // -------------------------------------------------------------------------------------------------------------------------------------
        //                                                      handle state
        // -------------------------------------------------------------------------------------------------------------------------------------
        // state with the help of Allah
        // if a task is clicked it becomes TaskKSelect|TaskMove
        // state_machine = handle_state: {
        //     // if there was no mouse no state was changed or stopped moving a task
        //     if (!(rl.isMouseButtonDown(.mouse_button_left) or rl.isMouseButtonDown(.mouse_button_right))) {
        //         if (.TaskMove == state_machine) break :handle_state .TaskSelect;
        //         break :handle_state state_machine;
        //     }
        //
        //     // stopped moving a task
        //     if (.TaskMove == state_machine and !rl.isMouseButtonDown(.mouse_button_left)) break :handle_state .TaskSelect;
        //
        //     if (null != tlist.data) {
        //         // incha'Allah will test the selected task first
        //         {
        //             const task = try tlist.getTask(selected_task);
        //             if (StateMachine.TaskSelect == state_machine) {
        //                 var vec = rl.Vector2{ .x = task.x, .y = task.y + (TASK_HEIGHT / 3) };
        //                 if (rl.checkCollisionPointCircle(rl.getMousePosition(), vec, 15)) {
        //                     break :handle_state .TaskConnectPrev;
        //                 }
        //                 vec.x += TASK_WIDTH;
        //                 if (rl.checkCollisionPointCircle(rl.getMousePosition(), vec, 15)) {
        //                     break :handle_state .TaskConnectNext;
        //                 }
        //                 vec.x -= TASK_WIDTH / 2;
        //                 vec.y = task.y;
        //                 if (rl.checkCollisionPointCircle(rl.getMousePosition(), vec, 15)) {
        //                     break :handle_state .TaskConnectParent;
        //                 }
        //                 vec.y += TASK_HEIGHT;
        //                 if (rl.checkCollisionPointCircle(rl.getMousePosition(), vec, 15)) {
        //                     break :handle_state .TaskConnectChild;
        //                 }
        //             } else if (rl.checkCollisionPointRec(rl.getMousePosition(), .{ .x = task.x, .y = task.y, .width = TASK_WIDTH, .height = TASK_HEIGHT })) {
        //                 if (rl.isMouseButtonDown(.mouse_button_left)) {
        //                     selected_task = task.id;
        //                     if (0 != delta.x or 0 != delta.y) break :handle_state .TaskMove;
        //                     break :handle_state .TaskSelect;
        //                 }
        //             }
        //         }
        //
        //         for (tlist.data.?) |task| {
        //             if (null == task) continue;
        //             if (rl.isMouseButtonDown(.mouse_button_left) and rl.checkCollisionPointRec(rl.getMousePosition(), .{ .x = task.?.x, .y = task.?.y, .width = TASK_WIDTH, .height = TASK_HEIGHT })) {
        //                 switch (state_machine) {
        //                     .TaskConnectChild => {
        //                         if (selected_task.?.hasChildId(task.?.id)) {
        //                             try tlist.taskRemoveChildId(selected_task.?.id, task.?.id, true);
        //                         } else {
        //                             tlist.taskAddChildId(selected_task.?.id, task.?.id, true) catch |e| if (tt.Tlist.Error.TaskCanNotBeGrandChildOfItSelf != e) return e;
        //                         }
        //                         break :handle_state .TaskSelect;
        //                     },
        //                     .TaskConnectParent => {
        //                         if (selected_task.?.hasParentId(task.?.id)) {
        //                             try tlist.taskRemoveParentId(selected_task.?.id, task.?.id, true);
        //                         } else {
        //                             tlist.taskAddParentId(selected_task.?.id, task.?.id, true) catch |e| if (tt.Tlist.Error.TaskCanNotBeGrandChildOfItSelf != e) return e;
        //                         }
        //                         break :handle_state .TaskSelect;
        //                     },
        //                     .TaskConnectNext => {
        //                         if (selected_task.?.hasNextId(task.?.id)) {
        //                             try tlist.taskRemoveNextId(selected_task.?.id, task.?.id);
        //                         } else {
        //                             tlist.taskAddNextId(selected_task.?.id, task.?.id) catch |e| if (tt.Tlist.Error.TaskCanNotBeNextOfItSelf != e) return e;
        //                         }
        //                         break :handle_state .TaskSelect;
        //                     },
        //                     .TaskConnectPrev => {
        //                         if (selected_task.?.hasPreviousId(task.?.id)) {
        //                             try tlist.taskRemovePreviousId(selected_task.?.id, task.?.id);
        //                         } else {
        //                             tlist.taskAddPreviousId(selected_task.?.id, task.?.id) catch |e| if (tt.Tlist.Error.TaskCanNotBeNextOfItSelf != e) return e;
        //                         }
        //                         break :handle_state .TaskSelect;
        //                     },
        //                     else => {
        //                         selected_task = task.?.id;
        //                         if (0 != delta.x or 0 != delta.y) break :handle_state .TaskMove;
        //                         break :handle_state .TaskSelect;
        //                     },
        //                 }
        //             }
        //         }
        //     }
        //
        //     // we ask the help of Allah
        //
        //     if (.TlistMenu == state_machine and rl.isMouseButtonDown(.mouse_button_left) and rl.checkCollisionPointRec(rl.getMousePosition(), control_panel.rec)) break :handle_state .TlistMenu;
        //
        //     if (rl.isMouseButtonDown(.mouse_button_right)) {
        //         control_panel.rec.x = mouse_pos.x;
        //         control_panel.rec.y = mouse_pos.y;
        //         break :handle_state .TlistMenu;
        //     }
        //
        //     // if no task was clicked
        //     break :handle_state .Idle;
        // };

        // keyboard state by the will of Allah
        // s: start selecting tasks
        //     m: start moving the task
        //         key_left: move to left
        //         key_right: move to right
        //         key_up: move to up
        //         key_down: move to down
        //         Esc: cancel to .TaskSelect
        //     d: delete the task
        //     r: rename the task
        //     key_right: next non null id
        //     key_left: previous non null id
        //     Esc: cancel
        // m: menu
        //     s: save
        //     Esc: cancel
        // n: add new task
        //     enter: ok
        //     Esc: cancel
        state_machine = handle_state: {
            switch (state_machine) {
                .Idle => {
                    if (rl.isKeyPressed(.key_s)) break :handle_state .TaskSelect;
                    if (rl.isKeyPressed(.key_m)) break :handle_state .ViewMove;
                    if (rl.isKeyPressed(.key_n)) {
                        const vec2 = rl.getScreenToWorld2D(.{ .x = 600 - (control_panel.rec.width / 2), .y = 300 - (control_panel.rec.height / 2) }, camera);
                        control_panel.rec.x = vec2.x;
                        control_panel.rec.y = vec2.y;
                        break :handle_state .TlistMenu;
                    }
                },
                .TlistMenu => {
                    if (rl.isKeyPressed(.key_escape)) break :handle_state .Idle;
                    if (0 != control_panel.buffer[0] and rl.isKeyPressed(.key_enter)) {
                        const task = try tt.Task.new(allocator);
                        task.setName(&control_panel.buffer);
                        task.x = control_panel.rec.x;
                        task.y = control_panel.rec.y;
                        try tlist.addTask(task);
                        control_panel.buffer[0] = 0;
                        break :handle_state .Idle;
                    }
                },
                .TaskSelect => {
                    if (rl.isKeyPressed(.key_escape)) break :handle_state .Idle;
                    if (null == tlist.data) break :handle_state .Idle;
                    if (null == selected_task) {
                        get_first_task: for (tlist.data.?) |task| {
                            if (null == task) continue :get_first_task;
                            selected_task = task;
                            break :get_first_task;
                        }
                        if (null == selected_task) break :handle_state .Idle;
                    }

                    if (rl.isKeyPressed(.key_m)) break :handle_state .TaskMove;
                    if (rl.isKeyPressed(.key_d)) {
                        const id = selected_task.?.id;
                        try tlist.removeTaskById(selected_task.?.id, true);
                        selected_task = null;
                        get_next_task: for (tlist.data.?[id..]) |task| {
                            if (null == task) continue :get_next_task;
                            selected_task = task;
                            break :get_next_task;
                        }
                        break :handle_state .TaskSelect;
                    }
                    if (rl.isKeyPressed(.key_r)) break :handle_state .TaskRename;
                    if (rl.isKeyPressed(.key_right)) {
                        get_next_task: for (tlist.data.?[selected_task.?.id + 1 ..]) |task| {
                            if (null == task) continue :get_next_task;
                            selected_task = task;
                            camera.target = rl.Vector2{ .x = selected_task.?.x - 600, .y = selected_task.?.y - 300 };
                            break :get_next_task;
                        }
                        break :handle_state .TaskSelect;
                    }
                    if (rl.isKeyPressed(.key_left)) {
                        // var i: u32 = selected_task.?.id - 1;
                        // get_previous_task: while (i > 0) : (i -= 0) {
                        //     if (null == tlist.data.?[i]) continue :get_previous_task;
                        //     selected_task = tlist.data.?[i];
                        //     break :get_previous_task;
                        // }
                        // if (i == selected_task.?.id and null != tlist.data.?[0]) selected_task = tlist.data.?[0];
                        // break :handle_state .TaskSelect;
                        get_previous_task: for (tlist.data.?[0..selected_task.?.id]) |task| {
                            if (null == task) continue :get_previous_task;
                            selected_task = task;

                            camera.target = rl.Vector2{ .x = selected_task.?.x - 600, .y = selected_task.?.y - 300 };
                        }
                        break :handle_state .TaskSelect;
                    }
                },
                .TaskMove => {
                    if (rl.isKeyDown(.key_escape)) break :handle_state .Idle;
                    if (rl.isKeyDown(.key_up)) selected_task.?.y -= 4;
                    if (rl.isKeyDown(.key_down)) selected_task.?.y += 4;
                    if (rl.isKeyDown(.key_left)) selected_task.?.x -= 4;
                    if (rl.isKeyDown(.key_right)) selected_task.?.x += 4;
                },
                .ViewMove => {
                    if (rl.isKeyDown(.key_escape)) break :handle_state .Idle;
                    if (rl.isKeyDown(.key_up)) camera.target.y -= 4;
                    if (rl.isKeyDown(.key_down)) camera.target.y += 4;
                    if (rl.isKeyDown(.key_left)) camera.target.x -= 4;
                    if (rl.isKeyDown(.key_right)) camera.target.x += 4;
                },
                else => {
                    if (rl.isKeyPressed(.key_escape)) break :handle_state .Idle;
                },
            }

            break :handle_state state_machine;
        };

        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(rl.Color.gray);

        camera.begin();
        defer camera.end();
        // -------------------------------------------------------------------------------------------------------------------------------------
        //                                                      draw tasks
        // -------------------------------------------------------------------------------------------------------------------------------------

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

        draw_to_state: {
            switch (state_machine) {
                .TlistMenu => {
                    rl.drawRectangleRec(control_panel.rec, rl.Color.brown);
                    _ = rgui.GuiTextBox(.{ .x = control_panel.rec.x + 1, .y = control_panel.rec.y + 5, .width = control_panel.rec.width - 2, .height = 15 }, &control_panel.buffer, 34, true);
                },
                .TaskSelect, .TaskMove => {
                    if (null == selected_task) break :draw_to_state;
                    var vec = rl.Vector2{ .x = selected_task.?.x, .y = selected_task.?.y + (TASK_HEIGHT / 3) };
                    rl.drawCircleV(vec, 15, rl.Color.blue);
                    vec.x += TASK_WIDTH;
                    rl.drawCircleV(vec, 15, rl.Color.blue);
                    vec.x -= TASK_WIDTH / 2;
                    vec.y = selected_task.?.y;
                    rl.drawCircleV(vec, 15, rl.Color.blue);
                    vec.y += TASK_HEIGHT;
                    rl.drawCircleV(vec, 15, rl.Color.blue);
                },
                .TaskConnectChild => {
                    if (null == selected_task) break :draw_to_state;
                    rl.drawLineBezier(rl.Vector2{ .x = selected_task.?.x + (TASK_WIDTH / 2), .y = selected_task.?.y + TASK_HEIGHT }, rl.getMousePosition(), 7, rl.Color.orange);
                },
                .TaskConnectParent => {
                    if (null == selected_task) break :draw_to_state;
                    rl.drawLineBezier(rl.Vector2{ .x = selected_task.?.x + (TASK_WIDTH / 2), .y = selected_task.?.y }, rl.getMousePosition(), 7, rl.Color.orange);
                },
                .TaskConnectNext => {
                    if (null == selected_task) break :draw_to_state;
                    rl.drawLineBezier(rl.Vector2{ .x = selected_task.?.x + TASK_WIDTH, .y = selected_task.?.y + (TASK_HEIGHT / 3) }, rl.getMousePosition(), 7, rl.Color.beige);
                },
                .TaskConnectPrev => {
                    if (null == selected_task) break :draw_to_state;
                    rl.drawLineBezier(rl.Vector2{ .x = selected_task.?.x, .y = selected_task.?.y + (TASK_HEIGHT / 3) }, rl.getMousePosition(), 7, rl.Color.beige);
                },
                else => {},
            }
        }
        {
            var state_name: [64]u8 = undefined;
            _ = try std.fmt.bufPrint(&state_name, "{any}", .{state_machine});
            rgui.GuiDrawText(&state_name, .{ .x = camera.target.x + camera.offset.x, .y = camera.target.y + camera.offset.y, .width = 500, .height = 50 }, 0, .{ .r = 0, .g = 0, .b = 0, .a = 255 });
            // std.debug.print("alhamdo li Allah: {any}\n", .{state_machine});
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
