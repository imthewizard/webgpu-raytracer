const std = @import("std");

// pub const std_options = struct {
//     pub const logFn = wasmLogFn;
// };

extern fn drawTriangle() void;
extern fn js_print_str(ptr: [*]const u8, len: usize) void;


fn log(msg: []const u8) void {
    js_print_str(msg.ptr, msg.len);
}


export fn init() void {
    drawTriangle();
    // std.log.info("Finished", .{});
    log("Finished");
}
