import { js_print_str } from "./main.js"

let device
let context
let presentationFormat

const canvas = document.getElementById("canvas")

let baseShaderModule

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

	baseShaderModule = await loadShader("./triangle.wgsl")

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

export const importObject = {
	env: {
		js_print_str: js_print_str,
		drawTriangle: function() {
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
			});

			const renderPassDescriptor = {
				label: "canvas renderPass",
				colorAttachments: [
					{
						clearValue: [0.3, 0.3, 0.3, 1],
						loadOp: "clear",
						storeOp: "store",
					},
				],
			};
			renderPassDescriptor.colorAttachments[0].view = context.getCurrentTexture().createView()

			const encoder = device.createCommandEncoder({label: "encoder"})

			const pass = encoder.beginRenderPass(renderPassDescriptor)
			pass.setPipeline(pipeline)
			pass.draw(3);
			pass.end();

			const commandBuffer = encoder.finish()
			device.queue.submit([commandBuffer])
		},
	}
}


// Glue code
