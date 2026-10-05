// Player helper: bundled Node only, same pinned generator and recipe, no shell.
import {isAbsolute, dirname, join} from 'node:path';
import {fileURLToPath} from 'node:url';
import http from 'node:http';
import https from 'node:https';
import {syncBuiltinESMExports} from 'node:module';
const args = process.argv.slice(2);
if (args.length !== 4 || args[0] !== '--seed' || args[2] !== '--output' ||
    !/^[A-Za-z0-9_-]{1,128}$/.test(args[1]) || !isAbsolute(args[3])) {
  console.error('Expected --seed <ASCII identifier> --output <absolute JSON path>');
  process.exit(2);
}
const offline = () => {throw Error('World generation is offline; outbound HTTP is disabled');};
globalThis.fetch = offline;
http.get = http.request = https.get = https.request = offline;
syncBuiltinESMExports();
const timer = setTimeout(() => {console.error('World generation exceeded 120 seconds'); process.exit(124);}, 120000);
try {
  process.argv = [process.execPath, join(dirname(fileURLToPath(import.meta.url)), 'generate-azgaar.mjs'), ...args];
  await import('./generate-azgaar.mjs');
} finally { clearTimeout(timer); }
