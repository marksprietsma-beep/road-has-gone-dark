import {render} from './text.mjs';
// Explicit knowledge is caller-owned Layer C. Verdicts and private facts never
// ride along with public/rumour payloads. This is projection, not save mutation.
export function project(record, knowledge = {}) {
  if (knowledge.world_id !== record.source.world_id) return null;
  const known = new Set(knowledge.known_entities ?? []);
  if (record.type === 'site' && !known.has(record.id)) return null;
  if (record.type === 'character' && knowledge.playthrough_id !== record.scope.slice('playthrough:'.length)) return null;
  const payload = {id: record.id, type: record.type, text: render(record), tags: record.tags.filter(tag => tag !== 'underground')};
  const heard = new Set(knowledge.heard_rumours ?? []);
  payload.rumours = record.rumours.filter(r => heard.has(r.id)).map(r => ({id: r.id, text: r.text, label: 'Rumour'}));
  const discovered = new Set(knowledge.discovered_tokens ?? []);
  if (record.secret && discovered.has(record.secret.reveal_token)) {
    const {reveal_token, ...facts} = record.secret;
    payload.discoveries = facts;
  }
  return payload;
}
export function originPayload(enrichment, burgId) {
  const record = enrichment.records.find(r => r.type === 'origin' && r.source.kind === 'settlements' && r.source.id === burgId);
  if (!record) return null;
  // Deliberate allowlist: no source note, seed, tags, rumours, secrets, neighbours.
  return {schema_version: 1, world_id: enrichment.base_world.id, burg_id: burgId, enrichment_sha: enrichment.enrichment_sha, content_pack_version: enrichment.content_pack_version, record_id: record.id, label: 'Local memory', text: render(record)};
}
