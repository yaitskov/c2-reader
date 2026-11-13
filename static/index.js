import { WASI, OpenFile, File, ConsoleStdout } from "https://cdn.jsdelivr.net/npm/@bjorn3/browser_wasi_shim@0.3.0/dist/index.js";
import ghc_wasm_jsffi from "./ghc_wasm_jsffi.js";
import { load, push, pop } from "./idb.js";
import { unzip } from "./zip.js";
import { persist, list, get, remove } from "./blobstore.js";

globalThis.c2readerIdb = { load, push, pop };
globalThis.c2zip = { unzip };
globalThis.c2blob = { persist, list, get, remove };

const rawExample = document.createElement("div");
rawExample.id = "raw-example";
rawExample.className = "raw-example";
rawExample.textContent = "Existing DOM node";
globalThis.rawExample = rawExample;

const args = [];
const env = ["GHCRTS=-H64m"];
const fds = [
  new OpenFile(new File([])),
  ConsoleStdout.lineBuffered((msg) => console.log(`[WASI stdout] ${msg}`)),
  ConsoleStdout.lineBuffered((msg) => console.warn(`[WASI stderr] ${msg}`)),
];
const options = { debug: false };
const wasi = new WASI(args, env, fds, options);

const instance_exports = {};
const { instance } = await WebAssembly.instantiateStreaming(fetch("/app.wasm"), {
  wasi_snapshot_preview1: wasi.wasiImport,
  ghc_wasm_jsffi: ghc_wasm_jsffi(instance_exports),
});
Object.assign(instance_exports, instance.exports);

wasi.initialize(instance);
await instance.exports.hs_start(globalThis.example);
