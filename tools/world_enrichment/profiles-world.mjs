// Versioned extension to GAME-79. The V1 compiler and package bytes stay unchanged.
import{readFileSync,writeFileSync,mkdirSync,existsSync,renameSync,rmSync}from'node:fs';
import{dirname,resolve,join}from'node:path';
import{fileURLToPath}from'node:url';
import{canonical,sha}from'./core.mjs';
import{compileProfiles,PROFILE_VERSION,profilePack,profilePackSha}from'./profile-framework.mjs';
import{PROFILE_RENDERER}from'./profile-text.mjs';
const root=resolve(dirname(fileURLToPath(import.meta.url)),'../..');
export function verifyProfileRuntime(){
 const bytes=readFileSync(join(root,'data/world_enrichment/runtime-profiles-v2.json')),m=JSON.parse(bytes);
 if(m.schema_version!==2||m.generator_version!==PROFILE_VERSION||m.content_pack_sha!==profilePackSha||m.renderer_version!==PROFILE_RENDERER)throw Error('Unsupported profile runtime');
 for(const[p,d]of Object.entries(m.files))if(sha(readFileSync(join(root,p)))!==d)throw Error('Profile runtime integrity failure: '+p);
 return {...m,runtime_manifest_sha:sha(bytes)};
}
export function compileProfileWorld(path){
 const runtime=verifyProfileRuntime(),out=compileProfiles(path);
 const projection={schema_version:2,world_id:out.world.base.id,world_sha:out.world.base.sha256,states:{},regions:{},hometowns:{}};
 for(const group of ['states','regions','hometowns'])for(const[id,r]of Object.entries(out.profiles[group]))projection[group][id]={record_id:r.id,...r.source,name:r.name,parents:r.parents,tags:r.tags.filter(t=>!['mine','border','river'].includes(t)),compact_summary:r.public.compact_summary,full_summary:r.public.full_summary,...(group==='hometowns'?{memory:r.public.local_memory,tradition:r.public.tradition}:{} )};
 const sidecar={schema_version:2,base_world:out.world.base,origin_v1:out.origins.descriptor,generator_version:PROFILE_VERSION,content_pack_version:profilePack.version,content_pack_sha:profilePackSha,profiles:out.profiles};
 const enrichment=canonical(sidecar)+'\n',publicBytes=canonical(projection)+'\n';
 const descriptor={schema_version:2,provider:'trhgd-hierarchical-lexicon',generator_version:PROFILE_VERSION,content_pack_version:profilePack.version,content_pack_sha:profilePackSha,renderer_version:PROFILE_RENDERER,base_world_id:out.world.base.id,base_world_sha:out.world.base.sha256,enrichment_sha:sha(enrichment),public_projection_sha:sha(publicBytes),runtime_manifest_sha:runtime.runtime_manifest_sha,state_count:Object.keys(projection.states).length,region_count:Object.keys(projection.regions).length,origin_count:Object.keys(projection.hometowns).length,origin_v1_sha:out.origins.descriptor.enrichment_sha};
 return {...out,projection,sidecar,enrichment,publicBytes,descriptor};
}
export function verifyProfileDirectory(path,worldPath){
 const expected=compileProfileWorld(worldPath);
 for(const[name,bytes]of [['enrichment.json',expected.enrichment],['public.json',expected.publicBytes],['descriptor.json',canonical(expected.descriptor)+'\n']])if(readFileSync(join(path,name),'utf8')!==bytes)throw Error('Profile validation failed: '+name);
 return expected.descriptor;
}
export function publishProfiles(path,worldPath){
 if(existsSync(path))return verifyProfileDirectory(path,worldPath);
 const out=compileProfileWorld(worldPath),pending=path+'.pending-'+process.pid;
 mkdirSync(dirname(path),{recursive:true});mkdirSync(pending);
 try{for(const[name,bytes]of [['enrichment.json',out.enrichment],['public.json',out.publicBytes],['descriptor.json',canonical(out.descriptor)+'\n']])writeFileSync(join(pending,name),bytes,{flag:'wx'});
 verifyProfileDirectory(pending,worldPath);
 if(existsSync(path)){verifyProfileDirectory(path,worldPath);rmSync(pending,{recursive:true});}else renameSync(pending,path);
 }catch(e){rmSync(pending,{recursive:true,force:true});throw e;}
 return out.descriptor;
}
if(process.argv[1]&&resolve(process.argv[1])===fileURLToPath(import.meta.url)){
 try{const a=process.argv.slice(2);if(a.length!==4||a[0]!=='--world'||a[2]!=='--output')throw Error('Expected --world <path> --output <profiles-v2 directory>');console.log(JSON.stringify(publishProfiles(resolve(a[3]),resolve(a[1]))));}catch(e){console.error(e.message);process.exitCode=1;}
}
