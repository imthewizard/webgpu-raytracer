import { initWebGPU, importObject } from "./glue.js"

export let wasmModule

export function get_zig_context() {
	const ptr = wasmModule.instance.exports.get_context()
	const size = wasmModule.instance.exports.get_context_size()
	return new Uint8Array(wasmModule.instance.exports.memory.buffer, ptr, size)
}

export function js_print_str(ptr, len) {
	const memBuffer = new Uint8Array(wasmModule.instance.exports.memory.buffer)
	const decoder = new TextDecoder("utf-8")
	const msg = decoder.decode(memBuffer.subarray(ptr, ptr + len))
	console.log(msg)
}

async function js_main() {
	await WebAssembly.instantiateStreaming(fetch("webgpu_raytracer.wasm"), importObject).then(obj => { wasmModule = obj })
	await initWebGPU()
	wasmModule.instance.exports.init();
}

js_main()
