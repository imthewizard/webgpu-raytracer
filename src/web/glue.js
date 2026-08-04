import { js_print_str } from "./main.js"

let device
let context
let presentationFormat

const canvas = document.getElementById("canvas")

let computeModule
let baseShaderModule
let screen_texture

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

	const pipeline = device.createComputePipeline({
		label: "compute",
		layout: "auto",
		compute: {
			module,
		},
	})

	const bindGroup = device.createBindGroup({
		label: "compute bindGroup",
		layout: pipeline.getBindGroupLayout(0),
		entries: [
			{ binding: 0, resource: screen_texture },
		],
	})

	const encoder = device.createCommandEncoder({
		label: "compute encoder",
	})
	const pass = encoder.beginComputePass({
		label: "compute pass",
	})
	pass.setPipeline(pipeline)
	pass.setBindGroup(0, bindGroup)
	pass.dispatchWorkgroups(640 / 16, 480 / 16) // hardcoded
	pass.end()

	const commandBuffer = encoder.finish()
	device.queue.submit([commandBuffer])
}

function invokeVertFragShader() {
	const module = baseShaderModule

	const pipeline = device.createRenderPipeline({
		label: "triangle",
		layout: "auto",
		vertex: {
			entryPoint: "vertexMain",
			module,
		},
		fragment: {
			entryPoint: "fragmentMain",
			module,
			targets: [{ format: presentationFormat }],
		},
	})

	const bindGroup = device.createBindGroup({
		label: "vertfrag bindGroup",
		layout: pipeline.getBindGroupLayout(0),
		entries: [
			{ binding: 0, resource: screen_texture.createView() },
			{ binding: 1, resource: device.createSampler() },
		],
	})

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
	pass.setPipeline(pipeline)
	pass.setBindGroup(0, bindGroup)
	pass.draw(6)
	pass.end()

	const commandBuffer = encoder.finish()
	device.queue.submit([commandBuffer])
}

export const importObject = {
	env: {
		js_print_str: js_print_str,
		drawTriangle: function() {
			// (async() => {
			// 	await invokeComputeShader()
			// 	await invokeVertFragShader()
			// })
			invokeComputeShader()
			invokeVertFragShader()
		},
	}
}


// Glue code
