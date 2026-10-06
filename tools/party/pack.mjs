import {readFileSync} from 'node:fs';
import {sha,canonical} from '../world_enrichment/core.mjs';
export const pack=JSON.parse(readFileSync(new URL('../../data/world_enrichment/trhgd-party-v1.json',import.meta.url)));
export const packSha=sha(canonical(pack));
export const VERSION='trhgd-party-1';
export const lookup=(group,id)=>{const row=pack[group].find(r=>r.id===id);if(!row)throw Error('Unknown '+group+' ID: '+id);return row;};
