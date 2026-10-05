import {sha, canonical} from './core.mjs';
export const RENDERER_VERSION = 'trhgd-text-1';
// No RNG, context inference, source note interpolation or truth creation here.
export function render(r) {
  const f = r.facts;
  switch (r.type) {
    case 'site': return `A ${f.subtype} retains ${f.condition}. Built as a ${f.original_purpose} ${f.period}, it later changed: ${f.later_event}.`;
    case 'origin': return `${f.local_memory} ${f.tradition}`;
    case 'character': return `From ${r.context.display_name}, they were ${f.upbringing}. They became a ${f.formative_role}, learning through ${f.training}. After ${f.formative_event}, they chose ${f.motivation}. ${f.dominant_trait[0].toUpperCase() + f.dominant_trait.slice(1)}, they worry about ${f.concern}.`;
    case 'mundane-item': return `An ordinary ${f.base_type}, ${f.condition}. With ${f.material}, it served ${f.previous_owners} for ${f.previous_use}; ${f.small_history}.`;
    case 'rare-item': return `A ${f.material} ${f.base_type} with ${f.physical_marking}. Made for ${f.original_purpose}, it is ${f.reputation}.`;
    default: throw Error('Unsupported renderer record');
  }
}
export function renderingArtifact(enrichment) {
  const prose = enrichment.records.map(r => ({id: r.id, scope: r.scope, text: render(r)}));
  return {renderer_version: RENDERER_VERSION, enrichment_sha: enrichment.enrichment_sha, prose, rendering_sha: sha(canonical([RENDERER_VERSION, prose]))};
}
