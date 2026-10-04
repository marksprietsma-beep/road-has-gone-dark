// Extend the unchanged GAME-67 UI and interaction module. No model/sample copy.
const own=path=>new URL(path,import.meta.url).href;
const inherited=path=>new URL('../game67/'+path,import.meta.url).href;
const response=await fetch(inherited('index.html'));
if(!response.ok)throw Error('GAME-67 baseline is required');
const documentTemplate=new DOMParser().parseFromString(await response.text(),'text/html');
for(const script of documentTemplate.querySelectorAll('script'))script.remove();
document.body.replaceChildren(...[...documentTemplate.body.children].map(e=>document.importNode(e,true)));
const base=document.createElement('base');base.href=inherited('');document.head.append(base);
for(const path of [inherited('viewer.css'),own('viewer.css')]){const css=document.createElement('link');css.rel='stylesheet';css.href=path;document.head.append(css)}
const $=id=>document.getElementById(id),NS='http://www.w3.org/2000/svg';
document.querySelector('header .eyebrow').textContent='THE ROAD HAS GONE DARK / GAME-69 VISUAL RESEARCH';
document.querySelector('header h1').textContent='Detailed towns, inspectable places';
document.querySelector('header .subtitle').textContent='Compare original artwork, the GAME-67 geometry proof, and an interactive original-art overlay.';
document.querySelector('footer a').href=own('README.md');
const controls=document.createElement('section');controls.className='art-controls';controls.innerHTML='<label>Visual comparison<select id="art-mode"><option value="C">C · Original artwork + facilities</option><option value="B">B · GAME-67 geometry + facilities</option><option value="A">A · Original GAME-63 (complete research)</option></select></label><p id="art-description"></p><button id="alignment-toggle" aria-pressed="false">Alignment diagnostic</button>';
document.querySelector('main').prepend(controls);
const disclaimer=document.createElement('p');disclaimer.id='art-disclaimer';disclaimer.textContent='Research comparison only. Original geometry, artwork and facilities; synthetic coastline and uncalibrated scale. No permanent renderer selected.';
document.querySelector('.notes').before(disclaimer);
const frameResponse=await fetch(own('art/frames.json'));if(!frameResponse.ok)throw Error('Original artwork frame metadata failed to load');
const frames=await frameResponse.json(),loaded=new Map(),failed=new Map();
const legacyRoles={inn:'inns',tavern:'inns',shop:'trading',smithy:'mine',guildhall:'capital',chapel:'monastery',manor:'fort',guardhouse:'fort',stable:'village',warehouse:'trading',pier:'canoes',well:'water-sources',mill:'hamlet'};
let mode='C',diagnostic=false;
function attr(el,key,value){if(el.getAttribute(key)!==String(value))el.setAttribute(key,value)}
function asset(slug,audience){return own(`art/${slug}.${mode==='A'||audience==='developer'?'original':'public'}.svg`)}
function preload(url){if(loaded.has(url)||failed.has(url))return;loaded.set(url,false);const img=new Image();img.src=url;img.decode().then(()=>{loaded.set(url,true);update()}).catch(()=>{failed.set(url,true);$('art-description').textContent='Artwork could not load; this is not a validated visual proof';update()})}
function update(){
 const state=window.game67State;if(!state){window.game69State=null;return}
 const frame=frames.find(f=>f.slug===state.slug);if(!frame)throw Error('Unknown original artwork frame');
 $('stage').style.background=mode==='B'?'#decba5':frame.background;
 document.body.dataset.artMode=mode;document.body.dataset.alignment=String(diagnostic);
 const terrain=$('terrain');let image=terrain.querySelector('#original-art');
 if(!image){image=document.createElementNS(NS,'image');image.id='original-art';terrain.prepend(image)}
 const url=asset(state.slug,state.audience);
 for(const[k,v]of Object.entries({href:url,x:frame.frame.x,y:frame.frame.y,width:frame.frame.width,height:frame.frame.height,preserveAspectRatio:'none'}))attr(image,k,v);
 if(mode!=='B')preload(url);
 for(const marker of document.querySelectorAll('.marker')){const type=marker.dataset.type,icon=marker.querySelector('image');if(icon)attr(icon,'href',mode==='B'?inherited(`assets/${legacyRoles[type]||'unidentified'}.svg`):own(`assets/${type}.svg`))}
 for(const row of document.querySelectorAll('.place-row')){const img=row.querySelector('img');const src=mode==='B'?inherited(`assets/${legacyRoles[row.dataset.type]||'unidentified'}.svg`):own(`assets/${row.dataset.type}.svg`);if(img.src!==src)img.src=src}
 // Only anonymous building footprints are drawn by the optional diagnostic.
 // Do not fetch source fixtures or privileged alignment records in public mode.
 if(diagnostic){for(const path of terrain.children){if(path.tagName==='path'&&path.getAttribute('fill')==='#ae9170'){if(!path.classList.contains('roof-diagnostic'))path.classList.add('roof-diagnostic')}}}
 const description=mode==='A'?'Complete original research illustration · no facility overlays · developer context':mode==='B'?'Unchanged GAME-67 geometry renderer and original proxy icons':'Original vector artwork with measured alignment and semantic Game-icons overlays';
 if($('art-description').textContent!==description&&!failed.has(url))$('art-description').textContent=description;
 window.game69State={...state,mode,artUrl:mode==='B'?null:url,frame:frame.frame,artLoaded:mode==='B'||loaded.get(url)===true,artFailed:failed.has(url),diagnostic,selectedId:state.selectedId};
}
function changeMode(){mode=$('art-mode').value;diagnostic=false;$('alignment-toggle').setAttribute('aria-pressed','false');
 if(mode==='A'&&!$('developer').checked){$('developer').checked=true;$('developer').dispatchEvent(new Event('change'))}
 if(mode!=='A'&&$('developer').checked){$('developer').checked=false;$('developer').dispatchEvent(new Event('change'))}
 update();
}
$('art-mode').onchange=changeMode;
// Installed before the inherited listener: opting out of developer inspection
// also leaves the complete-original comparison so public mode cannot display it.
$('developer').addEventListener('change',()=>{if(mode==='A'&&!$('developer').checked){mode='C';$('art-mode').value='C'}update()});
$('alignment-toggle').onclick=()=>{diagnostic=!diagnostic;$('alignment-toggle').setAttribute('aria-pressed',String(diagnostic));update()};
const observer=new MutationObserver(update);
observer.observe($('terrain'),{childList:true,attributes:true,subtree:true});observer.observe($('markers'),{childList:true});observer.observe($('place-index'),{childList:true});
await import(inherited('viewer.mjs'));
update();
