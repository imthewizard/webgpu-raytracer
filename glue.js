import { js_print_str, get_zig_context, wasmModule } from "./main.js"

let device
let context
let presentationFormat

const canvas = document.getElementById("canvas")

let computeModule
let baseShaderModule
let screen_texture

let vertfrag_pipeline
let vertfrag_bindgroup

let compute_pipeline
let compute_bindgroup
let zig_context_buffer

export async function initWebGPU() {
	if (!navigator.gpu) {
		alert("browser does not support WebGPU")
		return
	}

	const adapter = await navigator.gpu.requestAdapter();
	if (!adapter) {
		alert("browser supports WebGPU, but it might be disabled")
		return
	}

	device = await adapter?.requestDevice();
	device.lost.then((info) => {
		console.error(`WebGPU device lost: ${info.message}`)

		if (info.reason !== "destroyed") {
			initWebGPU()
		}
	})

	screen_texture = device.createTexture({
		size: [640, 480],
		format: "rgba8unorm",
		usage: GPUTextureUsage.STORAGE_BINDING | GPUTextureUsage.TEXTURE_BINDING | GPUTextureUsage.RENDER_ATTACHMENT,
	})

	baseShaderModule = await loadShader("./triangle.wgsl")
	computeModule = await loadShader("./compute.wgsl")

	presentationFormat = navigator.gpu.getPreferredCanvasFormat()

	context = canvas.getContext("webgpu")
	context.configure({
		device,
		format: presentationFormat,
	})

	vertfrag_pipeline = device.createRenderPipeline({
		label: "triangle",
		layout: "auto",
		vertex: {
			entryPoint: "vertexMain",
			module: baseShaderModule,
		},
		fragment: {
			entryPoint: "fragmentMain",
			module: baseShaderModule,
			targets: [{ format: presentationFormat }],
		},
	})
	vertfrag_bindgroup = device.createBindGroup({
		label: "vertfrag bindgroup",
		layout: vertfrag_pipeline.getBindGroupLayout(0),
		entries: [
			{ binding: 0, resource: screen_texture.createView() },
			{ binding: 1, resource: device.createSampler() },
		],
	})

	compute_pipeline = device.createComputePipeline({
		label: "compute",
		layout: "auto",
		compute: {
			module: computeModule,
		},
	})
	zig_context_buffer = device.createBuffer({
		size: get_zig_context().byteLength,
		usage: GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST
	})
	device.queue.writeBuffer(zig_context_buffer, 0, get_zig_context());
	compute_bindgroup = device.createBindGroup({
		label: "compute bindgroup",
		layout: compute_pipeline.getBindGroupLayout(0),
		entries: [
			{ binding: 0, resource: { buffer: zig_context_buffer } },
			{ binding: 1, resource: screen_texture },
		],
	})
}

async function loadShader(file) {
	const response = await fetch(file);

	if (!response.ok) {
		throw new Error(`Failed to load shader: ${file}`)
	}

	const code = await response.text()

	return device.createShaderModule({ label: file, code: code })
}

function invokeComputeShader() {
	const module = computeModule

	const encoder = device.createCommandEncoder({
		label: "compute encoder",
	})
	const pass = encoder.beginComputePass({
		label: "compute pass",
	})
	pass.setPipeline(compute_pipeline)
	pass.setBindGroup(0, compute_bindgroup)
	pass.dispatchWorkgroups(640 / 16, 480 / 16) // hardcoded
	pass.end()

	const commandBuffer = encoder.finish()
	device.queue.submit([commandBuffer])
}

function invokeVertFragShader() {
	const module = baseShaderModule

	const renderPassDescriptor = {
		label: "canvas renderPass",
		colorAttachments: [
			{
				clearValue: [0.3, 0.3, 0.3, 1],
				loadOp: "clear",
				storeOp: "store",
			},
		],
	}
	renderPassDescriptor.colorAttachments[0].view = context.getCurrentTexture().createView()

	const encoder = device.createCommandEncoder({label: "encoder"})

	const pass = encoder.beginRenderPass(renderPassDescriptor)
	pass.setPipeline(vertfrag_pipeline)
	pass.setBindGroup(0, vertfrag_bindgroup)
	pass.draw(6)
	pass.end()

	const commandBuffer = encoder.finish()
	device.queue.submit([commandBuffer])
}

export const importObject = {
	env: {
		js_print_str: js_print_str,
		drawTriangle: function() {
			update()
		},
	}
}

function update() {
	device.queue.writeBuffer(zig_context_buffer, 0, get_zig_context());
	invokeComputeShader()
	invokeVertFragShader()

	requestAnimationFrame(wasmModule.instance.exports.new_frame)
}

// Glue code
