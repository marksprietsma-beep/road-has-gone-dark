import {readFile} from "node:fs/promises";
import {findLoneSurrogate} from "../../tools/worldgen/canonical-json.mjs";
const path = process.argv[2];
if (!path) throw new Error("usage: validate-fixture.mjs <canonical-world.json>");
const world = JSON.parse(await readFile(path, "utf8"));

function validateUnicode(value, dataPath = "$") {
  if (typeof value === "string") {
    const offset = findLoneSurrogate(value);
    if (offset !== -1) throw new Error(`lone surrogate at ${dataPath}, UTF-16 offset ${offset}`);
    return;
  }
  if (Array.isArray(value)) {
    value.forEach((item, index) => validateUnicode(item, `${dataPath}[${index}]`));
    return;
  }
  if (value && typeof value === "object") {
    for (const [key, item] of Object.entries(value)) {
      const keyOffset = findLoneSurrogate(key);
      if (keyOffset !== -1) throw new Error(`lone surrogate in key at ${dataPath}, UTF-16 offset ${keyOffset}`);
      validateUnicode(item, `${dataPath}[${JSON.stringify(key)}]`);
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
