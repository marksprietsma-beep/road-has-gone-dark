#!/usr/bin/env node
import {readFile, writeFile} from "node:fs/promises";
import {resolve} from "node:path";
import {stringifyCanonical} from "./canonical-json.mjs";

const target = process.argv[2];
if (!target) {
  console.error("Usage: sanitize-godot-json.mjs <file.json>");
  process.exit(2);
}

const path = resolve(target);
const parsed = JSON.parse(await readFile(path, "utf8"));
await writeFile(path, stringifyCanonical(parsed));
console.log(`Sanitized for Godot JSON: ${path}`);
