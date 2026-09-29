import {readFile} from "node:fs/promises";
const path = process.argv[2];
if (!path) throw new Error("usage: validate-fixture.mjs <canonical-world.json>");
const world = JSON.parse(await readFile(path, "utf8"));
for (const key of ["cells", "states", "provinces", "settlements", "cultures", "religions", "biomes", "rivers", "routes", "markers"]) {
  if (!(key in world)) throw new Error(`missing canonical field: ${key}`);
}
if (!world.map?.width || !world.map?.height || !world.map?.bounds) throw new Error("missing map dimensions or bounds");
if (world.generator?.version !== "1.153.1") throw new Error("unexpected Azgaar version");
console.log(`validated ${path}`);
