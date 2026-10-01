import {readFile} from "node:fs/promises";
const path = process.argv[2];
if (!path) throw new Error("usage: validate-fixture.mjs <canonical-world.json>");
const world = JSON.parse(await readFile(path, "utf8"));

function validateUnicode(value, dataPath = "$") {
  if (typeof value === "string") {
    for (let offset = 0; offset < value.length; offset++) {
      const code = value.charCodeAt(offset);
      if (code >= 0xd800 && code <= 0xdbff) {
        const next = value.charCodeAt(offset + 1);
        if (next >= 0xdc00 && next <= 0xdfff) {
          offset++;
          continue;
        }
        throw new Error(`unpaired UTF-16 surrogate at ${dataPath}, string offset ${offset}`);
      }
      if (code >= 0xdc00 && code <= 0xdfff) {
        throw new Error(`unpaired UTF-16 surrogate at ${dataPath}, string offset ${offset}`);
      }
    }
    return;
  }
  if (Array.isArray(value)) {
    value.forEach((item, index) => validateUnicode(item, `${dataPath}[${index}]`));
    return;
  }
  if (value && typeof value === "object") {
    for (const [key, item] of Object.entries(value)) {
      validateUnicode(key, `${dataPath} (object key)`);
      validateUnicode(item, `${dataPath}.${key}`);
    }
  }
}

validateUnicode(world);
for (const key of ["cells", "states", "provinces", "settlements", "cultures", "religions", "biomes", "rivers", "routes", "markers"]) {
  if (!(key in world)) throw new Error(`missing canonical field: ${key}`);
}
if (!world.map?.width || !world.map?.height || !world.map?.bounds) throw new Error("missing map dimensions or bounds");
if (world.generator?.version !== "1.153.1") throw new Error("unexpected Azgaar version");
console.log(`validated ${path}`);
