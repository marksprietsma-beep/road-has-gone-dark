// Player helper: bundled Node only, same pinned generator and recipe, no shell.
import {isAbsolute, dirname, join} from 'node:path';
import {fileURLToPath} from 'node:url';
import {spawn} from 'node:child_process';
const args = process.argv.slice(2);
if (args.length !== 4 || args[0] !== '--seed' || args[2] !== '--output' ||
    !/^[A-Za-z0-9_-]{1,128}$/.test(args[1]) || !isAbsolute(args[3])) {
  console.error('Expected --seed <ASCII identifier> --output <absolute JSON path>');
  process.exit(2);
}
// A separate parent stays responsive even if synchronous generator work stalls.
const child = spawn(process.execPath, [join(dirname(fileURLToPath(import.meta.url)), 'offline-generate.mjs'), ...args], {stdio:'inherit', shell:false});
let timedOut = false;
const timer = setTimeout(() => {
  timedOut = true;
  console.error('World generation exceeded 120 seconds');
  child.kill('SIGKILL');
}, 120000);
child.on('error', error => {clearTimeout(timer); console.error(error); process.exitCode = 1;});
child.on('exit', code => {clearTimeout(timer); process.exitCode = timedOut ? 124 : (code ?? 1);});
