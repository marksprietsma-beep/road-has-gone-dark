import {readFile} from "node:fs/promises";

const path = process.argv[2];
if (!path) throw new Error("usage: validate-fixture.mjs <canonical-world.json>");

const world = JSON.parse(await readFile(path, "utf8"));

const assertValidUnicode = (value, location = "$") => {
  if (typeof value === "string") {
    for (let index = 0; index < value.length; index++) {
      const code = value.charCodeAt(index);
      if (code >= 0xd800 && code <= 0xdbff) {
        const next = index + 1 < value.length ? value.charCodeAt(index + 1) : -1;
        if (next >= 0xdc00 && next <= 0xdfff) {
          index++;
          continue;
        }
        throw new Error(`unpaired lead surrogate at ${location}[${index}]`);
      }
      if (code >= 0xdc00 && code <= 0xdfff) {
        throw new Error(`unpaired trail surrogate at ${location}[${index}]`);
      }
    }
    return;
  }

  if (Array.isArray(value)) {
    value.forEach((item, index) => assertValidUnicode(item, `${location}[${index}]`));
    return;
  }

  if (value && typeof value === "object") {
    for (const [key, item] of Object.entries(value)) {
      assertValidUnicode(key, `${location}{key}`);
      assertValidUnicode(item, `${location}.${key}`);
    }
  }
};

for (const key of ["cells", "states", "provinces", "settlements", "cultures", "religions", "biomes", "rivers", "routes", "markers"]) {
  if (!(key in world)) throw new Error(`missing canonical field: ${key}`);
}
if (!world.map?.width || !world.map?.height || !world.map?.bounds) throw new Error("missing map dimensions or bounds");
if (world.generator?.version !== "1.153.1") throw new Error("unexpected Azgaar version");
assertValidUnicode(world);

console.log(`validated ${path}`);
