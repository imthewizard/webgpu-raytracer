const std = @import("std");

const Key = enum(u8) {
    W,
    A,
    S,
    D,
};

const Context = extern struct {
    camera_position: [3]f32,
    padding: f32,
};

var ctx: Context = .{
    .camera_position = [_]f32{0.0, 1.0, -2.0},
    .padding = 0,
};

const velocity = 0.1;
const left = [_]f32{-velocity, 0.0, 0.0};
const right = [_]f32{velocity, 0.0, 0.0};
const forward = [_]f32{0.0, 0.0, velocity};
const backward = [_]f32{0.0, 0.0, -velocity};

fn add_vec(a: [3]f32, b: [3]f32) [3]f32 {
    return [_]f32{
        a[0] + b[0],
        a[1] + b[1],
        a[2] + b[2],
    };
}

extern fn drawTriangle() void;
extern fn js_print_str(ptr: [*]const u8, len: usize) void;

fn log(msg: []const u8) void {
    js_print_str(msg.ptr, msg.len);
}

export fn init() void {
    new_frame();
}

export fn get_context() [*]const u8 {
    return @ptrCast(&ctx);
}

export fn get_context_size() usize {
    return @sizeOf(Context);
}

export fn new_frame() void {
    drawTriangle();
}

export fn on_keydown(code: u8) void {
    const key: Key = @enumFromInt(code);

    switch (key) {
        .W => ctx.camera_position = add_vec(ctx.camera_position, forward),
        .A => ctx.camera_position = add_vec(ctx.camera_position, left),
        .S => ctx.camera_position = add_vec(ctx.camera_position, backward),
        .D => ctx.camera_position = add_vec(ctx.camera_position, right),
    }
}
