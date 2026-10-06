// Deterministic fact-bound Rant rendering; no private/source marker text accepted.
import {compile} from '../../vendor/content/rant/engine.js';
import {canonical,sha} from './core.mjs';
export const PROFILE_RENDERER='trhgd-profile-rant-2';
export function renderProfile(record,pack,compact=false){
 if(Object.keys(record).sort().join('|')!=='domain|id|name|public|render_seed'||record.public.secret||record.public.provenance)throw Error('Profile renderer requires an allowlisted public record');
 const f=record.public;
 const values=Object.fromEntries(Object.entries(f.prose_facts).map(([k,v])=>[k,{name:k,subs:['default'],entries:[{forms:[String(v)],classes:[]}]}]));
 const patterns={state:'{<posture> communities centred on|A <posture> society known for} <economy>, with <custom>.',region:'{[case:first]<role> focused on|[case:first]<role> specialising in} <economy> within <parent>.',hometown:'{[case:first]<role> whose households value|[case:first]<role> with a tradition of} <custom>.'};
 const pattern=compact?patterns[record.domain]:pack.render_patterns[record.domain];
 const result=compile(pattern).run({seed:sha(canonical([PROFILE_RENDERER,record.render_seed,f])),dictionary:{tables:values}}).replace(/\s+/g,' ').trim();
 if(!result||/undefined|\[object|[<>]|\b(?:km|kilomet|bonus|discount|travel time)\b/i.test(result))throw Error('Invalid profile prose: '+result);
 return result[0].toUpperCase()+result.slice(1);
}
