#!/usr/bin/env node
import {readFile, writeFile} from "node:fs/promises";
import {resolve} from "node:path";

const target = process.argv[2];
if (!target) {
  console.error("Usage: sanitize-godot-json.mjs <file.json>");
  process.exit(2);
}

function sanitizeGodotString(value) {
  let output = "";
  for (let i = 0; i < value.length; i++) {
    const code = value.charCodeAt(i);
    if (code >= 0xd800 && code <= 0xdbff) {
      const next = value.charCodeAt(i + 1);
      if (next >= 0xdc00 && next <= 0xdfff) {
        output += value[i] + value[i + 1];
        i++;
      } else {
        output += "\uFFFD";
      }
    } else if (code >= 0xdc00 && code <= 0xdfff) {
      output += "\uFFFD";
    } else {
      output += value[i];
    }
  }
  return output;
}

function sanitizeForGodot(value) {
  if (typeof value === "string") return sanitizeGodotString(value);
  if (Array.isArray(value)) return value.map(sanitizeForGodot);
  if (value && typeof value === "object") {
    return Object.fromEntries(Object.entries(value).map(([key, item]) => [key, sanitizeForGodot(item)]));
  }
  return value;
}

const path = resolve(target);
const parsed = JSON.parse(await readFile(path, "utf8"));
await writeFile(path, JSON.stringify(sanitizeForGodot(parsed), null, 2) + "\n");
console.log(`Sanitized for Godot JSON: ${path}`);
