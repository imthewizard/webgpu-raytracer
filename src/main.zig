const std = @import("std");

const Context = extern struct {
    camera_position: [3]f32,
    padding: f32,
};

var ctx: Context = .{
    .camera_position = [_]f32{0.0, 1.0, -2.0},
    .padding = 0,
};

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
    log("New frame");
}
