#!/usr/bin/env node
import {createHash} from "node:crypto";
import {mkdir, writeFile} from "node:fs/promises";
import {createRequire} from "node:module";
import {dirname, resolve} from "node:path";
import {fileURLToPath, pathToFileURL} from "node:url";
import FlatQueue from "./flatqueue-compat.mjs";
import {serializeCanonicalJson} from "./canonical-json.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const root = resolve(here, "../..");
const vendor = resolve(root, "vendor/azgaar");
const requireVendor = createRequire(resolve(vendor, "package.json"));
const [{JSDOM}, {createServer}, aleaModule] = await Promise.all([
  import(pathToFileURL(requireVendor.resolve("jsdom")).href),
  import(pathToFileURL(requireVendor.resolve("vite")).href),
  import(pathToFileURL(requireVendor.resolve("alea")).href)
]);

const args = process.argv.slice(2);
const value = flag => args[args.indexOf(flag) + 1];
const seed = value("--seed");
const output = value("--output");
if (!seed || !output || args.includes("--help")) {
  console.error("Usage: generate-azgaar.mjs --seed <seed> --output <file.json>");
  process.exit(args.includes("--help") ? 0 : 2);
}

const dom = new JSDOM("<!doctype html><html><body></body></html>", {url: "http://localhost/"});
const exposeDomGlobal = key => {
  const descriptor = Object.getOwnPropertyDescriptor(globalThis, key);
  if (!descriptor || descriptor.writable || descriptor.set) {
    globalThis[key] = dom.window[key];
    return;
  }
  if (descriptor.configurable) {
    Object.defineProperty(globalThis, key, {
      value: dom.window[key],
      configurable: true,
      writable: true
    });
    return;
  }
  throw new Error(`Cannot install jsdom global: ${key}`);
};
for (const key of ["window", "document", "navigator", "Node", "Range", "DOMRect", "localStorage", "HTMLElement", "SVGElement"]) {
  exposeDomGlobal(key);
}
// Legacy modules publish model services on window and later read them as globals.
Object.setPrototypeOf(globalThis, dom.window);
globalThis.$ = () => ({dialog() {}, selectmenu() {}, slider() {}});
dom.window.$ = globalThis.$;

// Azgaar's legacy seed component still reads aleaPRNG as a global. Expose the
// pinned npm dependency without modifying vendored source.
globalThis.aleaPRNG = aleaModule.default ?? aleaModule;
dom.window.aleaPRNG = globalThis.aleaPRNG;

// Several non-migrated generators still expect FlatQueue from Azgaar's classic
// browser bundle in public/libs. The source handoff omits public/, so expose a
// project-owned compatible queue implementation for headless generation.
globalThis.FlatQueue = FlatQueue;
dom.window.FlatQueue = FlatQueue;

const server = await createServer({
  root: vendor,
  configFile: resolve(vendor, "vite.config.ts"),
  server: {middlewareMode: true},
  appType: "custom",
  logLevel: "error"
});
try {
  const entry = await server.ssrLoadModule(resolve(here, "headless-entry.ts"));
  const world = await entry.generateCanonicalWorld(seed);
  const bytes = serializeCanonicalJson(world);
  await mkdir(dirname(resolve(output)), {recursive: true});
  await writeFile(resolve(output), bytes);
  console.log(`${createHash("sha256").update(bytes).digest("hex")}  ${output}`);
} finally {
  await server.close();
  dom.window.close();
}
