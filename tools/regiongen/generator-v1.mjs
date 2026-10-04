/** One-cell pipeline. Full truth and public exports are deliberately separate. */
import {buildCellContext,hash,isOwnedDryLand,polygonArea} from './cell-region.mjs';
import {townForgeDecoration} from './town-forge-adapter.mjs';
import {composeLocalRegion} from './compose-local-region.mjs';
import {generateContextualSites,contextualPlayerSiteView} from './contextual-sites-v2.mjs';
import {buildLandscapePresentation} from './landscape-presentation.mjs';
import {buildHexOverlay,hexCentre} from './hex-overlay.mjs';
import {buildSharedIcons,renderSharedIcon,SITE_ROLES} from './shared-map-icons.mjs';
import {renderConstrainedRegion} from './render-constrained-region.mjs';
import {renderReadableLabels} from './site-icons.mjs';
export async function generateCellRegion(world,cellId,fingerprint,sidecar){
 const ctx=buildCellContext(world,cellId,fingerprint,sidecar);
 const provider=await townForgeDecoration(world,ctx);
 const region=composeLocalRegion(world,ctx,provider);
 region.id=ctx.id;region.generation_version=1;
 region.provider.commit=provider.provider.commit;
 region.provider.seed=provider.id;
 region.local_sites_v2=generateContextualSites(world,region);
 for(const site of region.local_sites_v2.sites){
  site.provenance=site.kind==='hometown'?'source_exact':'generated_local';
  if(site.kind!=='hometown')site.knowledge=hash(site.id+':initial-knowledge').slice(0,1)<'5'?'rumoured':'hidden';
 }
 region.landscape_presentation_v1=buildLandscapePresentation(world,region);
 // Town Forge actually contributes source-filtered woodland marks, while the
 // continuous field and atlas trees above are ours. Provider water/roads excluded.
 region.landscape_presentation_v1.provider_marks=region.landscape.trees.map(t=>({...t,provenance:'inferred_visual',origin:'town_forge_filtered'}));
 region.inferred_fine_v1=region.landscape_presentation_v1.terrain;
 region.hex_overlay_v1=buildHexOverlay(ctx);
 for(const h of region.hex_overlay_v1.cells){h.id=`hex:v1:${ctx.generation_world_seed}:${h.axial.join(':')}`;h.world_centre=hexCentre(h.axial);h.owned=isOwnedDryLand(ctx,h.centre)}
 region.world_icon_roles_v1=buildSharedIcons(world,ctx);
 const bounds=ctx.space.source_bounds,area=ctx.parent_cell.polygon_area;
 region.scale={cell_id:cellId,source_polygon_area:area,source_recorded_area:ctx.parent_cell.source_area,view_span_source_units:bounds.right-bounds.left,view_area:(bounds.right-bounds.left)**2,view_to_cell_area:(bounds.right-bounds.left)**2/area,hex_pitch_source_units:1,hex_area_source_units:Math.sqrt(3)/2,cell_area_to_hex_area:area/(Math.sqrt(3)/2),owned_dry_hex_centres:region.hex_overlay_v1.cells.filter(c=>c.owned).length,physical_km:'UNCALIBRATED'};
 region.provenance={coasts_cells_burgs_routes:'source_exact',rivers:'source_approximation',landscape:'inferred_visual',minor_sites:'generated_local'};
 return region;
}
export function publicRegion(region,discoveries={}){
 const copy=structuredClone(region),view=contextualPlayerSiteView(region.local_sites_v2,discoveries);
 copy.local_sites_v2={schema_version:2,sites:view.visible,rumours:view.rumours};
 copy.source_context.source_landmarks=(region.source_context.source_landmarks||[]).filter(s=>['discovered','visited'].includes(discoveries[s.id]??s.knowledge)).map(s=>({...s,knowledge:discoveries[s.id]??s.knowledge}));
 copy.export_scope='PUBLIC_KNOWN_ONLY';return copy;
}
export function developerRegion(region){const copy=structuredClone(region);copy.export_scope='DEVELOPER_FULL_TRUTH';return copy}
export function renderRegion(region){
 let svg=renderConstrainedRegion(region,region.inferred_fine_v1);
 const ctx=region.source_context,p=ctx.parent_cell.local_polygon;
 const boundary=`<polygon points="${p.map(a=>a.join(',')).join(' ')}" fill="none" stroke="#a88448" stroke-width="2" stroke-dasharray="7 5"/>`;
 const sites=region.local_sites_v2.sites.filter(s=>s.kind!=='hometown');
 const macro=(ctx.source_landmarks||[]).map(s=>renderSharedIcon(s.kind,s.position)).join('\n');
 const marks=sites.map(s=>renderSharedIcon(SITE_ROLES[s.kind]??'statues',s.position)).join('\n');
 const scope=`<text x="24" y="925" font-family="Georgia,serif" font-size="13" fill="#514530">${region.export_scope==='DEVELOPER_FULL_TRUTH'?'DEVELOPER FULL TRUTH — undiscovered sites shown':'PUBLIC — known locations only'}</text>`;
 return svg.replace('</svg>',boundary+macro+marks+renderReadableLabels(sites,false,ctx.source_burgs.map(b=>b.local_position))+scope+'</svg>');
}
