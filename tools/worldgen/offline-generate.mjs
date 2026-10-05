// Internal worker; the validated helper parent enforces a wall-clock deadline.
import {dirname, join} from 'node:path';
import {fileURLToPath} from 'node:url';
import http from 'node:http';
import https from 'node:https';
import {syncBuiltinESMExports} from 'node:module';
const args = process.argv.slice(2);
const offline = () => {throw Error('World generation is offline; outbound HTTP is disabled');};
globalThis.fetch = offline;
http.get = http.request = https.get = https.request = offline;
syncBuiltinESMExports();
try {
  process.argv = [process.execPath, join(dirname(fileURLToPath(import.meta.url)), 'generate-azgaar.mjs'), ...args];
  await import('./generate-azgaar.mjs');
} catch (error) { console.error(error); process.exitCode = 1; }
