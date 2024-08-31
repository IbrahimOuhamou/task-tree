// بسم الله الرحمن الرحيم
// la ilaha illa Allah Mohammed rassoul Allah
const std = @import("std");

const dvui = @import("dvui");
const SDLBackend = @import("SDLBackend");

const c = @cImport({
    @cInclude("SDL2/SDL.h");
});

var gpa_instance = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpa_instance.allocator();

var window: *c.SDL_Window = undefined;
var renderer: *c.SDL_Renderer = undefined;

pub fn main() !void {
    std.debug.print("بسم الله الرحمن الرحيم\n", .{});

    // init
    {
        if (c.SDL_Init(c.SDL_INIT_VIDEO) < 0) {
            std.debug.print("Couldn't initialize SDL: {s}\n", .{c.SDL_GetError()});
            return error.BackendError;
        }

        window = c.SDL_CreateWindow("DVUI SDL Ontop Example", c.SDL_WINDOWPOS_UNDEFINED, c.SDL_WINDOWPOS_UNDEFINED, @as(c_int, @intCast(640)), @as(c_int, @intCast(480)), c.SDL_WINDOW_ALLOW_HIGHDPI | c.SDL_WINDOW_RESIZABLE) orelse {
            std.debug.print("Failed to open window: {s}\n", .{c.SDL_GetError()});
            return error.BackendError;
        };

        _ = c.SDL_SetHint(c.SDL_HINT_RENDER_SCALE_QUALITY, "linear");

        renderer = c.SDL_CreateRenderer(window, -1, c.SDL_RENDERER_PRESENTVSYNC) orelse {
            std.debug.print("Failed to create renderer: {s}\n", .{c.SDL_GetError()});
            return error.BackendError;
        };

        _ = c.SDL_SetRenderDrawBlendMode(renderer, c.SDL_BLENDMODE_BLEND);
    }

    // create SDL backend using existing window and renderer, app still owns the window/renderer
    var backend = SDLBackend.init(window, renderer);
    defer backend.deinit();

    // init dvui Window (maps onto a single OS window)
    var win = try dvui.Window.init(@src(), gpa, backend.backend(), .{});
    defer win.deinit();

    main_loop: while (true) {

        // marks the beginning of a frame for dvui, can call dvui functions after this
        try win.begin(std.time.nanoTimestamp());

        // send events to dvui if they belong to floating windows
        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&event) != 0) {
            // some global quitting shortcuts
            switch (event.type) {
                c.SDL_KEYDOWN => {
                    if (((event.key.keysym.mod & c.KMOD_CTRL) > 0) and event.key.keysym.sym == c.SDLK_q) {
                        break :main_loop;
                    }
                },
                c.SDL_QUIT => {
                    break :main_loop;
                },
                else => {},
            }

            if (try backend.addEvent(&win, event)) {
                // dvui handles this event as it's for a floating window
            } else {
                // dvui doesn't handle this event, send it to the underlying application
            }
        }

        // clear the window
        _ = c.SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
        _ = c.SDL_RenderClear(renderer);

        // try dvui_floating_stuff();

        // marks end of dvui frame, don't call dvui functions after this
        // - sends all dvui stuff to backend for rendering, must be called before renderPresent()
        _ = try win.end(.{});

        // cursor management
        if (win.cursorRequestedFloating()) |cursor| {
            // cursor is over floating window, dvui sets it
            backend.setCursor(cursor);
        } else {
            // cursor should be handled by application
            backend.setCursor(.bad);
        }

        // render frame to OS
        backend.renderPresent();
    }

    c.SDL_DestroyRenderer(renderer);
    c.SDL_DestroyWindow(window);
    c.SDL_Quit();
}
