import {chromium} from '../../../vendor/azgaar/node_modules/playwright/index.mjs';
import {readFile,writeFile,mkdir} from 'node:fs/promises';
import {resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import assert from 'node:assert/strict';
const here=fileURLToPath(new URL('..',import.meta.url)),out=resolve(here,'evidence');await mkdir(out,{recursive:true});
const url=process.env.GAME69_URL||'http://127.0.0.1:8769/game69/';
const manifest=JSON.parse(await readFile(resolve(here,'art/manifest.json'))),results=[],captures=[],projections=[],errors=[],badResponses=[];
const browser=await chromium.launch({executablePath:process.env.CHROMIUM_PATH||'/usr/bin/chromium',headless:true,args:['--no-sandbox']});
const check=async(name,fn)=>{await fn();results.push({name,status:'passed'})};
const wait=async(page,slug,audience='public',mode='C')=>{await page.waitForFunction(([s,a,m])=>window.game69State?.slug===s&&window.game69State.audience===a&&window.game69State.mode===m&&window.game69State.artLoaded,[slug,audience,mode]);await page.waitForLoadState('networkidle');await page.evaluate(()=>document.fonts.ready)};
const capture=async(page,name)=>{await page.screenshot({path:resolve(out,name+'.png'),fullPage:true});captures.push(name+'.png')};
const watch=page=>{page.on('pageerror',e=>errors.push(e.message));page.on('response',r=>{if(r.status()>=400&&!r.url().endsWith('/favicon.ico'))badResponses.push({url:r.url(),status:r.status()})})};
try{
 const desktop=await browser.newContext({viewport:{width:1360,height:1050},deviceScaleFactor:1}),page=await desktop.newPage(),requests=[];watch(page);page.on('request',r=>requests.push(r.url()));
 await page.goto(url);await wait(page,'batan');
 await check('Public initial load uses only public artwork, frames and GAME-67 samples',async()=>{assert(!requests.some(u=>u.includes('.original.svg')||u.includes('.developer.json')||u.includes('art/manifest.json')||u.includes('/fixtures/')));assert.equal(await page.locator('.place-row').count(),4)});
 for(const[slug,type,providerId]of [['batan','inn','bld:landmark:inn:trunk-street-0:R3'],['albanes','guildhall','b93'],['thilranlena','warehouse','b223']]){
  await page.selectOption('#settlement',slug);await wait(page,slug);await page.click('#fit');
  await capture(page,slug+'-C-fit');await page.locator('#stage').screenshot({path:resolve(out,slug+'-C-map.png')});captures.push(slug+'-C-map.png');
  const model=JSON.parse(await readFile(resolve(here,`../game67/samples/${slug}.public.json`))),entry=model.establishments.find(e=>e.type===type&&e.provenance.providerBuildingId===providerId);
  assert(entry);
  await check(`${slug}: exact original facilities and semantic marker asset`,async()=>{
   assert.equal(await page.locator('.place-row').count(),model.establishments.length);assert.equal(await page.evaluate(()=>window.game69State.establishmentIds.includes(window.game67State.selectedId)),false);
   await page.locator(`.place-row[data-id="${entry.id}"]`).click();assert((await page.locator('#inspection').textContent()).includes(providerId));
   assert((await page.locator(`.marker[data-id="${entry.id}"] image`).getAttribute('href')).endsWith(`/game69/assets/${type}.svg`));
   const actual=await page.locator('#selection-roof path').getAttribute('d'),building=model.buildings.find(b=>b.id===entry.buildingId),expected=building.polygon.map(r=>'M'+r.map(p=>p.join(',')).join('L')+'Z').join('');assert.equal(actual,expected);
   assert(Number(await page.locator('#selection-roof path').evaluate(e=>getComputedStyle(e).fillOpacity))<.3);
  });
  for(const[level,button]of [['medium','District view'],['close','Premises view']]){
   await page.getByRole('button',{name:button,exact:true}).click();await wait(page,slug);await capture(page,`${slug}-C-${level}`);
   const record=manifest.settlements.find(r=>r.slug===slug),binding=record.facilityBindings.find(f=>f.providerId===providerId),dims=await page.locator('#stage').evaluate(e=>({width:e.clientWidth,height:e.clientHeight})),view=await page.evaluate(()=>window.game69State.view);
   const residual=binding.facilityAnchorResidualLocal*dims.width/view.w;projections.push({slug,level,providerId,localResidual:binding.facilityAnchorResidualLocal,screenResidualPx:residual});
   await check(`${slug} ${level}: source artwork anchor and screen marker agree`,async()=>{
    assert(residual<.5);
    const rendered=await page.locator(`.marker[data-id="${entry.id}"]`).evaluate(e=>{const m=e.getScreenCTM();return{x:m.e,y:m.f}});
    const expected=await page.locator('#terrain').evaluate((e,p)=>{const q=new DOMPoint(...p).matrixTransform(e.getScreenCTM());return{x:q.x,y:q.y}},entry.position);
    assert(Math.hypot(rendered.x-expected.x,rendered.y-expected.y)<.01);
   });
   await check(`${slug} ${level}: readable collision-free labels`,async()=>{
    const boxes=await page.locator('.marker-label').evaluateAll(es=>es.map(e=>{const b=e.getBoundingClientRect();return{x:b.x,y:b.y,w:b.width,h:b.height,font:getComputedStyle(e).fontSize}}));
    for(const b of boxes)assert(parseFloat(b.font)>=12);
    for(let i=0;i<boxes.length;i++)for(let j=i+1;j<boxes.length;j++){const a=boxes[i],b=boxes[j];assert(!(a.x<b.x+b.w&&a.x+a.w>b.x&&a.y<b.y+b.h&&a.y+a.h>b.y))}
   });
  }
  await check(`${slug}: full original image is actually loaded, with exact measured frame`,async()=>{
   const frame=manifest.settlements.find(r=>r.slug===slug).frame;
   for(const[k,v]of Object.entries({x:frame.x,y:frame.y,width:frame.width,height:frame.height}))assert.equal(Number(await page.locator('#original-art').getAttribute(k)),v);
   assert(await page.locator('#original-art').isVisible());assert(!(await page.evaluate(()=>window.game69State.artFailed)));
  });
  await check(`${slug}: fit, drag and wheel keep original art and markers together`,async()=>{
   await page.click('#fit');const initial=await page.evaluate(()=>window.game69State.view),box=await page.locator('#stage').boundingBox();
   await page.mouse.move(box.x+40,box.y+100);await page.mouse.down();await page.mouse.move(box.x+100,box.y+150);await page.mouse.up();assert.notEqual((await page.evaluate(()=>window.game69State.view)).x,initial.x);
   await page.mouse.move(box.x+box.width/2,box.y+box.height/2);await page.mouse.wheel(0,-200);await page.waitForTimeout(100);assert((await page.evaluate(()=>window.game69State.view)).w<initial.w);
   await page.click('#fit');assert.equal((await page.evaluate(()=>window.game69State.view)).w,initial.w);
  });
  await check(`${slug}: anonymous-footprint alignment diagnostic toggles`,async()=>{
   await page.click('#alignment-toggle');assert.equal(await page.locator('#alignment-toggle').getAttribute('aria-pressed'),'true');assert(await page.locator('.roof-diagnostic').count()===model.buildings.length);
   await capture(page,slug+'-alignment');await page.click('#alignment-toggle');assert.equal(await page.locator('#alignment-toggle').getAttribute('aria-pressed'),'false');
  });
  // A is an explicitly privileged ORIGINAL-ART comparison, not a public map.
  await page.selectOption('#art-mode','A');await wait(page,slug,'developer','A');await page.click('#fit');
  await check(`${slug}: comparison A loads complete original only in developer context`,async()=>{assert(await page.locator('#developer').isChecked());assert(!(await page.locator('#markers').isVisible()));assert((await page.locator('#original-art').getAttribute('href')).endsWith('.original.svg'))});
  await capture(page,slug+'-A-fit');await page.locator('#stage').screenshot({path:resolve(out,slug+'-A-map.png')});captures.push(slug+'-A-map.png');
  await page.selectOption('#art-mode','B');await wait(page,slug,'public','B');await page.click('#fit');
  await check(`${slug}: comparison B reuses original GAME-67 render and proxy icons`,async()=>{
   assert(!(await page.locator('#original-art').isVisible()));assert(await page.locator('#markers').isVisible());
   await page.locator(`.place-row[data-id="${entry.id}"]`).click();assert((await page.locator(`.marker[data-id="${entry.id}"] image`).getAttribute('href')).includes('/game67/assets/'));await page.click('#fit');
  });
  // Reload the sample so A/B/C fit comparisons all have no selection.
  await page.selectOption('#settlement',slug==='batan'?'albanes':'batan');await wait(page,slug==='batan'?'albanes':'batan','public','B');
  await page.selectOption('#settlement',slug);await wait(page,slug,'public','B');await page.click('#fit');
  await capture(page,slug+'-B-fit');await page.locator('#stage').screenshot({path:resolve(out,slug+'-B-map.png')});captures.push(slug+'-B-map.png');
  await page.selectOption('#art-mode','C');await wait(page,slug);await page.click('#fit');
  await check(`${slug}: repeated settled render is pixel-identical`,async()=>{await page.mouse.move(0,0);await page.waitForTimeout(200);const a=await page.locator('#stage').screenshot();await page.waitForTimeout(200);const b=await page.locator('#stage').screenshot();assert(a.equals(b));});
 }
 await page.selectOption('#settlement','albanes');await wait(page,'albanes');
 const dev=JSON.parse(await readFile(resolve(here,'../game67/samples/albanes.developer.json'))),unknown=dev.establishments.find(e=>e.knowledge==='unknown');
 await check('Public payload, DOM, art metadata and export exclude hidden binding',async()=>{
  assert(!(await page.content()).includes(unknown.id));assert(!(await page.evaluate(()=>window.game69State.establishmentIds)).includes(unknown.id));
  const art=await page.request.get(await page.locator('#original-art').getAttribute('href'));assert(!(await art.text()).includes('data-building-id'));assert(!(await art.text()).includes(`data-id="${unknown.provenance.providerBuildingId}"`));
  const pending=page.waitForEvent('download');await page.click('#export');const download=await pending,data=JSON.parse(await readFile(await download.path()));assert.equal(data.audience,'public');assert(!JSON.stringify(data).includes(unknown.id));
 });
 await capture(page,'albanes-public');
 await page.check('#developer');await wait(page,'albanes','developer');await page.locator(`.place-row[data-id="${unknown.id}"]`).click();await capture(page,'albanes-developer');
 await check('Developer opt-in reveals original source art and unknown facility, public export remains sanitized',async()=>{
  assert((await page.locator('#original-art').getAttribute('href')).endsWith('.original.svg'));assert((await page.locator('#inspection').textContent()).includes('unknown'));
  const pending=page.waitForEvent('download');await page.click('#export');const data=JSON.parse(await readFile(await(await pending).path()));assert(!JSON.stringify(data).includes(unknown.id));
 });
 await page.uncheck('#developer');await wait(page,'albanes');
 await check('Returning to public removes privileged selection and switches artwork',async()=>{assert.equal(await page.evaluate(()=>window.game69State.selectedId),null);assert(!(await page.content()).includes(unknown.id));assert((await page.locator('#original-art').getAttribute('href')).endsWith('.public.svg'))});
 await page.selectOption('#art-mode','A');await wait(page,'albanes','developer','A');await page.uncheck('#developer');await wait(page,'albanes','public','C');
 await check('Leaving developer context automatically exits complete-art comparison A',async()=>assert.equal(await page.locator('#art-mode').inputValue(),'C'));
 const mobile=await browser.newContext({viewport:{width:390,height:844},deviceScaleFactor:1,isMobile:true,hasTouch:true}),mp=await mobile.newPage();watch(mp);await mp.goto(url);await wait(mp,'batan');
 for(const[slug,type]of [['batan','inn'],['albanes','guildhall'],['thilranlena','warehouse']]){
  await mp.selectOption('#settlement',slug);await wait(mp,slug);await capture(mp,slug+'-mobile-fit');
  await mp.locator(`.place-row[data-type="${type}"]`).first().tap();await mp.getByRole('button',{name:'Premises view',exact:true}).tap();await wait(mp,slug);await capture(mp,slug+'-mobile-close');
  await check(`${slug}: mobile source-art inspection, details and no overflow`,async()=>{assert((await mp.locator('#inspection').textContent()).includes('Existing building'));assert(await mp.evaluate(()=>document.documentElement.scrollWidth<=window.innerWidth));assert(await mp.locator('#original-art').isVisible());assert(await mp.evaluate(()=>window.game69State.selectedId!==null))});
 }
 await check('Mobile pinch zoom retains original-art frame',async()=>{
  await mp.locator('#stage').scrollIntoViewIfNeeded();const b=await mp.locator('#stage').boundingBox(),cdp=await mobile.newCDPSession(mp),x=b.x+b.width/2,y=b.y+b.height/2,before=await mp.evaluate(()=>window.game69State.view.w),frameBefore=await mp.locator('#original-art').getAttribute('x');
  await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{x:x-25,y,id:1},{x:x+25,y,id:2}]});await cdp.send('Input.dispatchTouchEvent',{type:'touchMove',touchPoints:[{x:x-60,y,id:1},{x:x+60,y,id:2}]});await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});assert((await mp.evaluate(()=>window.game69State.view.w))<before);assert.equal(await mp.locator('#original-art').getAttribute('x'),frameBefore);
 });
 await check('Mobile map marker selection works on original art',async()=>{
  await mp.selectOption('#settlement','batan');await wait(mp,'batan');await mp.selectOption('#settlement','thilranlena');await wait(mp,'thilranlena');await mp.locator('#stage').scrollIntoViewIfNeeded();await mp.locator('.marker[data-type=warehouse]').tap();assert(await mp.evaluate(()=>window.game69State.selectedId!==null));assert((await mp.locator('#inspection').textContent()).includes('Warehouse'));
 });
 await check('No browser script or artwork/icon loading errors',async()=>{assert.deepEqual(errors,[]);assert.deepEqual(badResponses,[])});
 await writeFile(resolve(out,'browser-results.json'),JSON.stringify({browser:browser.version(),desktop:[1360,1050],mobile:[390,844],results,captures,projections,errors,badResponses},null,2)+'\n');
 console.log(`PASS ${results.length} GAME-69 browser checks; ${captures.length} real PNG captures; no script/loading errors`);
}finally{await browser.close()}
