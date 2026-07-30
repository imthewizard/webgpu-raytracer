const std = @import("std");

const c = @cImport({
    @cInclude("emscripten.h");
    @cInclude("emscripten/html5.h");
    @cInclude("webgpu/webgpu.h");
});

const WGPUError = error {
    FailedToGetAdapter,
    FailedToGetDevice,
};

var global_device: c.WGPUDevice = undefined;
var global_surface: c.WGPUSurface = undefined;
var global_queue : c.WGPUQueue = undefined;

pub fn main() !void {
    const descriptor: c.WGPUInstanceDescriptor = .{
        .requiredFeatureCount = 1,
        .requiredFeatures = @ptrCast(&c.WGPUInstanceFeatureName_TimedWaitAny),
    };
    const instance: c.WGPUInstance = c.wgpuCreateInstance(&descriptor).?;
    defer c.wgpuInstanceRelease(instance);

    const adapter: c.WGPUAdapter = try requestAdapterSync(instance);
    defer c.wgpuAdapterRelease(adapter);

    var properties: c.WGPUAdapterInfo = undefined;
    properties.nextInChain = null;
    if ( c.wgpuAdapterGetInfo(adapter, &properties) == 1 ) {
        std.log.info("vendorID: {}\n vendorName: {s}\n arch: {s}\n name: {s}\n desc: {s}",
            .{properties.vendorID, wgpuString2Zig(properties.vendor), wgpuString2Zig(properties.architecture), wgpuString2Zig(properties.device), wgpuString2Zig(properties.description)});
    }

    const device_descriptor: c.WGPUDeviceDescriptor = .{
        .nextInChain = null,
        .label = .{.data = null, .length = 0},
        .requiredFeatureCount = 0,
        .requiredFeatures = null,
        .requiredLimits = null,
        .defaultQueue = .{.nextInChain = null, .label = .{.data = null, .length = 0}},

        .uncapturedErrorCallbackInfo = .{.nextInChain = null, .callback = uncapturedErrorCallbackInfo, .userdata1 = null, .userdata2 = null},
    };
    // const device: c.WGPUDevice = try requestDeviceSync(instance, adapter, &device_descriptor);
    // defer c.wgpuDeviceRelease(device);
    global_device = try requestDeviceSync(instance, adapter, &device_descriptor);
    defer c.wgpuDeviceRelease(global_device);


    // const queue: c.WGPUQueue = c.wgpuDeviceGetQueue(global_device);
    global_queue = c.wgpuDeviceGetQueue(global_device);
    defer c.wgpuQueueRelease(global_queue);

    global_surface = getSurface(instance, adapter, global_device);
    defer c.wgpuSurfaceRelease(global_surface);
    defer c.wgpuSurfaceUnconfigure(global_surface);
    // could release adapter here

    c.emscripten_set_main_loop(loop, 0, true);

    std.log.info("Finished", .{});
}

fn loop() callconv(.c) void {
    var surface_tex: c.WGPUSurfaceTexture = .{
        .nextInChain = null,
        .texture = null,
        .status = 0,
    };
    c.wgpuSurfaceGetCurrentTexture(global_surface, &surface_tex);

    if (surface_tex.status == c.WGPUSurfaceGetCurrentTextureStatus_SuccessOptimal) {
        const target_view: c.WGPUTextureView = c.wgpuTextureCreateView(
            surface_tex.texture,
            &c.WGPUTextureViewDescriptor{
                .nextInChain = null,
                .label = zig2wgpuString("Surface tex view"),
                .format = c.WGPUTextureFormat_Undefined,
                .dimension = c.WGPUTextureViewDimension_2D,
                .baseMipLevel = 0,
                .mipLevelCount = c.WGPU_MIP_LEVEL_COUNT_UNDEFINED,
                .baseArrayLayer = 0,
                .arrayLayerCount = c.WGPU_ARRAY_LAYER_COUNT_UNDEFINED,
                .aspect = c.WGPUTextureAspect_Undefined,
                .usage = c.WGPUTextureUsage_None,
            }
        );
        defer c.wgpuTextureRelease(surface_tex.texture);
        defer c.wgpuTextureViewRelease(target_view);

        const encoder: c.WGPUCommandEncoder = c.wgpuDeviceCreateCommandEncoder(global_device, null);
        defer c.wgpuCommandEncoderRelease(encoder);

        // Render pass
        const render_pass_desc: c.WGPURenderPassDescriptor = .{
            .nextInChain = null,
            .label = .{.data = null, .length = 0},
            .colorAttachmentCount = 1,
            .colorAttachments = &c.WGPURenderPassColorAttachment{
                .nextInChain = null,
                .view = target_view,
                .depthSlice = c.WGPU_DEPTH_SLICE_UNDEFINED,
                .resolveTarget = null,
                .loadOp = c.WGPULoadOp_Clear,
                .storeOp = c.WGPUStoreOp_Store,
                .clearValue = c.WGPUColor{.r = 1.0, .g = 0.8, .b = 0.55, .a = 1.0},
            },
            .depthStencilAttachment = null,
            .occlusionQuerySet = null,
            .timestampWrites = null,
        };
        const render_pass: c.WGPURenderPassEncoder = c.wgpuCommandEncoderBeginRenderPass(encoder, &render_pass_desc);
        defer c.wgpuRenderPassEncoderRelease(render_pass);
        c.wgpuRenderPassEncoderEnd(render_pass);

        const cmd_buffer = c.wgpuCommandEncoderFinish(encoder, null);
        defer c.wgpuCommandBufferRelease(cmd_buffer);
        c.wgpuQueueSubmit(global_queue, 1, &cmd_buffer);
    }
}

fn wgpuString2Zig(wgpu_str: c.WGPUStringView) []const u8 {
    return wgpu_str.data[0..wgpu_str.length];
}

fn zig2wgpuString(zig_str: []const u8) c.WGPUStringView {
    return .{.data = zig_str.ptr, .length = zig_str.len};
}

fn requestAdapterSync(inst: c.WGPUInstance) WGPUError!c.WGPUAdapter {
    const Data = struct {
        adapter: c.WGPUAdapter
    };
    var data: ?Data = null;

    const lambda = struct {
        fn onAdapterRequestEnded(status: c.WGPURequestAdapterStatus,
            recv_adapter: c.WGPUAdapter,
            message: c.WGPUStringView,
            user_data1: ?*anyopaque,
            _: ?*anyopaque,) callconv(.c) void {
            if (status == c.WGPURequestAdapterStatus_Success) {
                const actual_data: *?Data = @ptrCast(@alignCast(user_data1));
                actual_data.* = .{.adapter = recv_adapter};
            } else {
                std.log.err("Failed to get WebGPU adapter: {s}", .{wgpuString2Zig(message)});
            }
        }
    };

    const callback_info: c.WGPURequestAdapterCallbackInfo = .{
        .nextInChain = null,
        .mode = c.WGPUCallbackMode_WaitAnyOnly,
        .callback = lambda.onAdapterRequestEnded,
        .userdata1 = @ptrCast(&data),
        .userdata2 = null,
    };

    var future_info: c.WGPUFutureWaitInfo = .{
        .future = c.wgpuInstanceRequestAdapter(inst, null, callback_info),
    };
    const wait_status: c.WGPUWaitStatus = c.wgpuInstanceWaitAny(inst, 1, @ptrCast(&future_info), 5 * std.time.ns_per_s);

    if ((data != null) and (wait_status == c.WGPUWaitStatus_Success)) {
        return data.?.adapter;
    } else {
        return WGPUError.FailedToGetAdapter;
    }
}

fn requestDeviceSync(inst: c.WGPUInstance, adapter: c.WGPUAdapter, descriptor: *const c.WGPUDeviceDescriptor) WGPUError!c.WGPUDevice {
    const Data = struct {
        device: c.WGPUDevice,
    };
    var data: ?Data = null;

    const lambda = struct {
        fn onDeviceRequestEnded(status: c.WGPURequestDeviceStatus,
            recv_device: c.WGPUDevice,
            message: c.WGPUStringView,
            user_data1: ?*anyopaque,
            _: ?*anyopaque,) callconv(.c) void {
            if (status == c.WGPURequestDeviceStatus_Success) {
                const actual_data: *?Data = @ptrCast(@alignCast(user_data1));
                actual_data.* = .{.device = recv_device};
            } else {
                std.log.err("Failed to get WebGPU device: {s}", .{wgpuString2Zig(message)});
            }
        }
    };

    const callback_info: c.WGPURequestDeviceCallbackInfo = .{
        .nextInChain = null,
        .mode = c.WGPUCallbackMode_WaitAnyOnly,
        .callback = lambda.onDeviceRequestEnded,
        .userdata1 = @ptrCast(&data),
        .userdata2 = null,
    };

    var future_info: c.WGPUFutureWaitInfo = .{
        .future = c.wgpuAdapterRequestDevice(adapter, descriptor, callback_info),
    };
    const wait_status: c.WGPUWaitStatus = c.wgpuInstanceWaitAny(inst, 1, @ptrCast(&future_info), 5 * std.time.ns_per_s);

    if ((data != null) and (wait_status == c.WGPUWaitStatus_Success)) {
        return data.?.device;
    } else {
        return WGPUError.FailedToGetDevice;
    }
}

fn uncapturedErrorCallbackInfo(device: [*c]const c.WGPUDevice, err_type: c.WGPUErrorType, message: c.WGPUStringView, _:?*anyopaque, _:?*anyopaque) callconv (.c) void {
    _ = device;
    std.log.err("Error in device: WGPUErrorType {d}, msg: {s}", .{err_type, wgpuString2Zig(message)});
}

fn getSurface(instance: c.WGPUInstance, adapter: c.WGPUAdapter, device: c.WGPUDevice) c.WGPUSurface {
    var ext: c.WGPUEmscriptenSurfaceSourceCanvasHTMLSelector = .{
        .chain = .{.next = null, .sType = c.WGPUSType_EmscriptenSurfaceSourceCanvasHTMLSelector},
        .selector = zig2wgpuString("canvas"),
    };
    const surface: c.WGPUSurface = c.wgpuInstanceCreateSurface(instance,
        &c.WGPUSurfaceDescriptor{
            .label = zig2wgpuString("Surface"),
            .nextInChain = &ext.chain,
        },
    );

    var width: c_int = undefined;
    var height: c_int = undefined;
    _ = c.emscripten_get_canvas_element_size("#canvas", &width, &height);

    var surface_capabilities: c.WGPUSurfaceCapabilities = .{.nextInChain = null};
    _ = c.wgpuSurfaceGetCapabilities(surface, adapter, &surface_capabilities);
    defer c.wgpuSurfaceCapabilitiesFreeMembers(surface_capabilities);

    c.wgpuSurfaceConfigure(surface, &c.WGPUSurfaceConfiguration{
        .nextInChain = null,
        .device = device,
        .format = surface_capabilities.formats[0],
        .usage = c.WGPUTextureUsage_RenderAttachment,
        .width = @intCast(width),
        .height = @intCast(height),
        .viewFormatCount = 0,
        .viewFormats = null,
        .alphaMode = c.WGPUCompositeAlphaMode_Auto,
        .presentMode = c.WGPUPresentMode_Fifo,
    });

    return surface;
}
