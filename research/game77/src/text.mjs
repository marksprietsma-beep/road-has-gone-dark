import {sha, canonical} from './core.mjs';
export const RENDERER_VERSION = 'trhgd-text-2';
export function renderMemory(memory, concise = false) {
  if (typeof memory === 'string') return memory; // archived pre-structured trials only
  switch (memory.event) {
    case 'unfinished-work-completed': return concise ? 'Neighbours completed work left behind by departing craftspeople.' : 'A generation of departing craftspeople left work unfinished; their neighbours completed it.';
    case 'shared-workshop': return concise ? 'Households once shared a workshop during repairs to their own roofs.' : 'Several households once shared a single workshop while their own roofs were repaired.';
    case 'shared-apprenticeship': return 'A local craftsperson taught apprentices from more than one household.';
    default: throw Error('Unsupported stored memory event');
  }
}
export function renderTradition(tradition) {
  if (typeof tradition === 'string') return tradition; // archived trials
  switch (tradition.practice) {
    case 'place-for-absent': return "Families set aside a place at the table for absent relatives at the year's last gathering.";
    case 'tool-handoff': return 'Old household tools are passed to a younger relative when a new household is formed.';
    case 'token-exchange': return "Neighbours exchange small handmade tokens at the year's first gathering.";
    default: throw Error('Unsupported stored tradition');
  }
}
// No RNG, context inference, source note interpolation or truth creation here.
export function render(r) {
  const f = r.facts;
  switch (r.type) {
    case 'site': return `A ${f.subtype} retains ${f.condition}. Built as a ${f.original_purpose} ${f.period}, it later changed: ${f.later_event}.`;
    case 'origin': return `${renderMemory(f.local_memory)} ${renderTradition(f.tradition)}`;
    case 'character': return `From ${r.context.display_name}, they were ${f.upbringing}. They became a ${f.formative_role}, learning through ${f.training}. After ${f.formative_event}, they chose ${f.motivation}. ${f.dominant_trait[0].toUpperCase() + f.dominant_trait.slice(1)}, they worry about ${f.concern}.`;
    case 'mundane-item': return `An ordinary ${f.base_type}, ${f.condition}. With ${f.material}, it served ${f.previous_owners} for ${f.previous_use}; ${f.small_history}.`;
    case 'rare-item': return `A ${f.material} ${f.base_type} with ${f.physical_marking}. Made for ${f.original_purpose}, it is ${f.reputation}.`;
    default: throw Error('Unsupported renderer record');
  }
}
export function renderingArtifact(enrichment, {rendererVersion = RENDERER_VERSION, renderRecord = render} = {}) {
  const prose = enrichment.records.map(r => ({id: r.id, scope: r.scope, text: renderRecord(r)}));
  return {renderer_version: rendererVersion, enrichment_sha: enrichment.enrichment_sha, prose, rendering_sha: sha(canonical([rendererVersion, prose]))};
}
