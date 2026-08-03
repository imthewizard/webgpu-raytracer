import { js_print_str } from "./main.js"

let device
let context
let presentationFormat

const canvas = document.getElementById("canvas")

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

	presentationFormat = navigator.gpu.getPreferredCanvasFormat()

	context = canvas.getContext("webgpu")
	context.configure({
		device,
		format: presentationFormat,
	})
}

export const importObject = {
	env: {
		js_print_str: js_print_str,
		drawTriangle: function() {
			const module = device.createShaderModule({
				label: "triangle",
				code: /* wgsl */ `
			  @vertex fn vs(
				@builtin(vertex_index) vertexIndex : u32
			  ) -> @builtin(position) vec4f {
				let pos = array(
				  vec2f( 0.0,  0.5),  // top center
				  vec2f(-0.5, -0.5),  // bottom left
				  vec2f( 0.5, -0.5)   // bottom right
				);

				return vec4f(pos[vertexIndex], 0.0, 1.0);
			  }

			  @fragment fn fs() -> @location(0) vec4f {
				return vec4f(1.0, 0.0, 0.0, 1.0);
			  }
			`,
			})

			const pipeline = device.createRenderPipeline({
				label: "triangle",
				layout: "auto",
				vertex: {
					entryPoint: "vs",
					module,
				},
				fragment: {
					entryPoint: "fs",
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
