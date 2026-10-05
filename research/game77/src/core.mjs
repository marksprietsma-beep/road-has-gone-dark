import {createHash} from 'node:crypto';
import {readFileSync, mkdirSync, writeFileSync, linkSync, unlinkSync} from 'node:fs';
import {dirname} from 'node:path';
export function canonical(value) {
  if (value === null || typeof value !== 'object') {
    if (typeof value === 'number' && !Number.isFinite(value)) throw Error('Non-finite JSON');
    if (value === undefined) throw Error('Undefined is not canonical JSON');
    return JSON.stringify(value);
  }
  if (Array.isArray(value)) return '[' + value.map(canonical).join(',') + ']';
  return '{' + Object.keys(value).sort().map(k => JSON.stringify(k) + ':' + canonical(value[k])).join(',') + '}';
}
export const sha = value => createHash('sha256').update(value).digest('hex');
export class ContentSeed {
  constructor(worldId, scope, version, packDigest, path = []) {
    if (![worldId, scope, version, packDigest, ...path].every(x => typeof x === 'string' && x.length > 0)) throw Error('Seed components must be nonempty strings');
    this.parts = [worldId, scope, version, packDigest]; this.path = [...path];
  }
  child(id) { return new ContentSeed(...this.parts, [...this.path, id]); }
  digest(field) { return sha(canonical(['trhgd-content-seed-v1', ...this.parts, this.path, field])); }
  pick(field, options) {
    if (!Array.isArray(options) || !options.length) throw Error('Empty choice');
    // Rejection avoids modulo bias. Each field has its own counter; no mutable RNG.
    const bound = BigInt(options.length), limit = (1n << 256n) / bound * bound;
    for (let n = 0; ; n++) {
      const x = BigInt('0x' + this.digest(`${field}:${n}`));
      if (x < limit) return structuredClone(options[Number(x % bound)]);
    }
  }
}
export function loadPack(path) {
  const pack = JSON.parse(readFileSync(path, 'utf8'));
  if (pack.schema_version !== 1 || !pack.version || pack.authorship !== 'TRHGD original research content') throw Error('Unsupported pack');
  return {pack, digest: sha(canonical(pack))};
}
export function seal(payload) { return {...payload, enrichment_sha: sha(canonical(payload))}; }
export function verify(envelope, expectedWorld) {
  const {enrichment_sha, ...payload} = envelope;
  if (envelope.schema_version !== 1 || envelope.base_world?.id !== expectedWorld.id || envelope.base_world?.sha256 !== expectedWorld.sha256 || sha(canonical(payload)) !== enrichment_sha) throw Error('Invalid sidecar identity or digest');
  return envelope;
}
export function writeImmutable(path, envelope) {
  const data = canonical(envelope) + '\n'; mkdirSync(dirname(path), {recursive: true});
  // Exclusive sibling + atomic hard-link publishes complete bytes without clobbering.
  // Crash leftovers are not a committed sidecar and never loaded as one.
  const temp = path + '.' + process.pid + '.tmp';
  writeFileSync(temp, data, {flag: 'wx'});
  try { linkSync(temp, path); }
  catch (e) { if (e.code !== 'EEXIST' || readFileSync(path, 'utf8') !== data) throw e; }
  finally { unlinkSync(temp); }
  return path;
}
