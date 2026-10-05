import {ContentSeed, canonical, seal, sha} from './core.mjs';
export const GENERATOR_VERSION = 'trhgd-staged-1';
const idFor = (type, ctx, instance) => `${type}:${ctx.source_kind}:${ctx.source_id}:${instance}`;
export function generate(type, ctx, {pack, digest}, {instance = '0', playthrough_id = null} = {}) {
  if (!ctx.world?.id || !Number.isInteger(ctx.source_id) || !Number.isInteger(ctx.cell_id)) throw Error('Missing immutable context');
  if (type === 'character' && !playthrough_id) throw Error('Character requires explicit playthrough scope');
  const scope = type === 'character' ? `playthrough:${playthrough_id}` : 'world';
  const id = idFor(type, ctx, instance), seed = new ContentSeed(ctx.world.id, scope, GENERATOR_VERSION, digest).child(id);
  const choose = (field, choices) => seed.pick(field, choices);
  const base = {id, type, scope, source: {world_id: ctx.world.id, cell_id: ctx.cell_id, kind: ctx.source_kind, id: ctx.source_id}, versions: {schema: 1, generator: GENERATOR_VERSION, pack: pack.version, pack_sha: digest}, seed: seed.digest('identity'), context: structuredClone(ctx), provenance: {facts: 'TRHGD generated immutable fiction; not Azgaar history', pack_authorship: pack.authorship}, tags: []};
  const isForest = /forest|woodland/i.test(ctx.biome.value ?? '');
  let facts, secret, rumours = [];
  if (type === 'site') {
    if (ctx.source_kind !== 'markers') throw Error('Site requires a real marker');
    const markerType = ctx.marker_type;
    if (!['ruins', 'dungeons'].includes(markerType)) throw Error('Unsupported site prototype');
    facts = {subtype: markerType === 'ruins' ? 'ruined structure' : 'subterranean site', original_purpose: choose('purpose', pack.site_purposes), period: choose('period', pack.site_periods), creator_group: ctx.culture.value, creator_identity_status: ctx.culture.value ? 'TRHGD assigned from current source culture; not historical proof' : 'unknown', later_event: choose('event', pack.site_events), condition: choose('condition', pack.site_conditions), material_theme: 'worked stone', encounter_suggestions: ['inspection', 'unstable-masonry'], active_occupants: null};
    secret = {lower_room: true, contents: 'a damaged tally of repair materials', reveal_token: `${id}:lower-room`};
    rumours = [{id: `${id}:rumour:0`, text: 'A sealed lower room is said to hold a hoard of coins.', verdict: 'partially-true', truth_fields: ['lower_room'], false_fields: ['coins']}, {id: `${id}:rumour:1`, text: 'Some say the surviving stones were brought from a distant royal palace.', verdict: 'false', truth_fields: [], false_fields: ['royal-palace-origin']}];
    base.tags = [markerType === 'ruins' ? 'ruin' : 'dungeon', 'stonework', 'underground'];
  } else if (type === 'origin') {
    if (ctx.source_kind !== 'settlements') throw Error('Origin requires hometown');
    facts = {local_memory: choose('history', pack.origin_histories), tradition: choose('tradition', pack.origin_traditions), scope: 'public local memory', culture_id: ctx.culture_id};
    secret = null; base.tags = ['local-memory', 'public-tradition'];
  } else if (type === 'character') {
    if (ctx.source_kind !== 'settlements') throw Error('Character requires hometown');
    // Harbour work requires a source port. Never infer an ocean-going childhood.
    const roles = ctx.port.value > 0 ? ['harbour repair apprentice', 'toolmaker apprentice'] : isForest ? ['woodworker apprentice', 'toolmaker apprentice'] : ['repairer apprentice', 'toolmaker apprentice'];
    facts = {birthplace: {burg_id: ctx.source_id, cell_id: ctx.cell_id}, upbringing: choose('family', ['raised by relatives who repaired household tools', 'raised in a household that shared work with neighbours']), formative_role: choose('occupation', roles), training: 'practical instruction from an older craftsperson', formative_event: choose('event', pack.formative_events), motivation: choose('motivation', pack.motivations), concern: choose('concern', pack.concerns), contact: 'an older neighbour who taught repairs', local_knowledge: ['household repair customs'], cultural_influence: ctx.culture.value, dominant_trait: choose('trait', pack.traits), exclusions: ['no unexplained ocean career', 'no opposed dominant traits', 'no unsupported inheritance'], mechanics: null};
    secret = {private_fact: 'kept an unfinished practice piece instead of admitting a mistake', reveal_token: `${id}:private`}; base.tags = ['former-apprentice', 'practical-upbringing'];
  } else if (type === 'mundane-item') {
    facts = {base_type: 'hand axe', material: 'iron head and wooden handle', quality: 'ordinary', origin_culture: ctx.culture.value, maker: 'a household tool workshop', age: 'one generation of use', condition: choose('condition', pack.item_conditions), construction: 'a plain socket fitted to a replaceable handle', previous_use: 'cutting kindling and trimming repair timber', previous_owners: 'two related households', small_history: 'the handle was replaced while the original head was kept'};
    secret = null; base.tags = ['mundane', 'household-tool', 'mechanics-neutral'];
  } else if (type === 'rare-item') {
    facts = {base_type: 'survey weight', material: 'bronze', maker: 'a small measuring-tool workshop', origin_culture: ctx.culture.value, age: 'several generations', original_purpose: 'checking workshop balances', owners_events: ['used by successive craftspeople', 'kept after newer weights replaced it'], physical_marking: choose('mark', pack.rare_marks), reputation: 'remembered by a few local craftspeople for its careful finish', exceptional_descriptor: 'unusually precise workmanship; no magical or numerical effect asserted'};
    secret = {hidden_fact: 'a later owner filed one edge to correct a worn balance', reveal_token: `${id}:edge`};
    rumours = [{id: `${id}:rumour:0`, text: 'It is said never to have needed adjustment.', verdict: 'false', truth_fields: [], false_fields: ['never-adjusted']}]; base.tags = ['rare-craft', 'provenance', 'mechanics-neutral'];
  } else throw Error('Unsupported content type');
  const record = {...base, facts, rumours, secret}; validateRecord(record); return record;
}
export function validateRecord(r) {
  if (r.type === 'character') {
    if (r.context.port.value <= 0 && /harbour|dock|sailor/.test(r.facts.formative_role)) throw Error('Inland maritime contradiction');
    if (Array.isArray(r.facts.dominant_trait) || !['patient','reserved','careful','inquisitive'].includes(r.facts.dominant_trait)) throw Error('Conflicting dominant traits');
    if (!r.scope.startsWith('playthrough:') || r.facts.birthplace.burg_id !== r.source.id) throw Error('Character identity mismatch');
  }
  if (r.type === 'site' && (!['ruins','dungeons'].includes(r.context.marker_type) || r.source.cell_id !== r.context.cell_id)) throw Error('Site anchor mismatch');
  if (r.type === 'mundane-item' && r.facts.material !== 'iron head and wooden handle') throw Error('Invalid material for template');
  if (r.rumours.some(x => !['true','false','partially-true','distorted'].includes(x.verdict))) throw Error('Missing rumour metadata');
  return true;
}
export function envelope(world, packInfo, records, {scope = 'world'} = {}) {
  if (records.some(r => r.scope !== scope)) throw Error('Mixed world/playthrough enrichment scope');
  const sorted = [...records].sort((a,b) => (a.scope + '/' + a.id) < (b.scope + '/' + b.id) ? -1 : (a.scope + '/' + a.id) > (b.scope + '/' + b.id) ? 1 : 0);
  if (new Set(sorted.map(r => `${r.scope}/${r.id}`)).size !== sorted.length) throw Error('Duplicate content identity');
  return seal({schema_version: 1, scope, base_world: world, provider: 'trhgd-staged', generator_version: GENERATOR_VERSION, content_pack_version: packInfo.pack.version, content_pack_sha: packInfo.digest, deterministic_enrichment_seed: sha(canonical([world.id, GENERATOR_VERSION, packInfo.digest])), records: sorted});
}
