import { initWebGPU, importObject } from "./glue.js"

let wasmModule

export function js_print_str(ptr, len) {
	const memBuffer = new Uint8Array(wasmModule.instance.exports.memory.buffer)
	const decoder = new TextDecoder("utf-8")
	const msg = decoder.decode(memBuffer.subarray(ptr, ptr + len))
	console.log(msg)
}

async function js_main() {
	await initWebGPU()

	await WebAssembly.instantiateStreaming(fetch("webgpu_raytracer.wasm"), importObject).then(obj => {
		wasmModule = obj

		wasmModule.instance.exports.init()
	})
	console.log("Loaded")
}

js_main()
