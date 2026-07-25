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
    const device: c.WGPUDevice = try requestDeviceSync(instance, adapter, &device_descriptor);
    defer c.wgpuDeviceRelease(device);
    // could release adapter here
}

fn wgpuString2Zig(wgpu_str: c.WGPUStringView) []const u8 {
    return wgpu_str.data[0..wgpu_str.length];
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
