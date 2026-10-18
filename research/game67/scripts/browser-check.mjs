// Runs against a local static server. Playwright is supplied by the existing
// locked Azgaar development tools; no provider runtime executes here.
import {chromium} from '../../../vendor/azgaar/node_modules/playwright/index.mjs';
import {readFile,writeFile,mkdir} from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
import {resolve} from 'node:path';
import assert from 'node:assert/strict';
const base=process.env.GAME67_URL||'http://127.0.0.1:8767';
const root=fileURLToPath(new URL('..',import.meta.url)),out=resolve(root,'evidence');await mkdir(out,{recursive:true});
const browser=await chromium.launch({executablePath:process.env.CHROMIUM_PATH||'/usr/bin/chromium',headless:true,args:['--no-sandbox']});
const results=[],captures=[],errors=[],requests=[];
const check=(name,fn)=>fn().then(()=>results.push({name,status:'passed'}));
try {
 const context=await browser.newContext({viewport:{width:1360,height:1000},deviceScaleFactor:1});
 const page=await context.newPage();page.on('pageerror',e=>errors.push(e.message));page.on('request',r=>requests.push(r.url()));
 await page.goto(base);await page.waitForFunction(()=>window.game67State?.slug==='batan');
 await check('Public startup fetches public payload only',async()=>{assert(!requests.some(u=>u.includes('.developer.json')||u.includes('/fixtures/')));assert.equal(await page.locator('.place-row').count(),4)});
 for(const[slug,type]of [['batan','inn'],['albanes','guildhall'],['thilranlena','warehouse']]) {
  await page.selectOption('#settlement',slug);await page.waitForFunction(s=>window.game67State?.slug===s,slug);
  await page.waitForTimeout(100);
  await page.screenshot({path:resolve(out,`${slug}-fit.png`),fullPage:true});captures.push(`${slug}-fit.png`);
  await check(`${slug}: original roofs and meaningful selectable facility`,async()=>{
   const model=JSON.parse(await readFile(resolve(root,'samples',slug+'.public.json')));assert.equal(await page.locator('#place-index .place-row').count(),model.establishments.length);
   assert(await page.locator(`#markers [data-type="${type}"]`).count()>0 || slug==='batan');
   await page.locator(`.place-row[data-type="${type}"]`).first().click();assert((await page.locator('#inspection').textContent()).includes('Existing building'));
   assert((await page.locator('#inspection').textContent()).includes('provider-generated'));
  });
  await page.getByRole('button',{name:'District view',exact:true}).click();await page.screenshot({path:resolve(out,`${slug}-medium.png`),fullPage:true});captures.push(`${slug}-medium.png`);
  await page.getByRole('button',{name:'Premises view',exact:true}).click();await page.screenshot({path:resolve(out,`${slug}-close.png`),fullPage:true});captures.push(`${slug}-close.png`);
  await check(`${slug}: labels are readable and do not overlap`,async()=>{
   const boxes=await page.locator('.marker-label').evaluateAll(es=>es.map(e=>{const b=e.getBoundingClientRect();return{x:b.x,y:b.y,w:b.width,h:b.height,font:getComputedStyle(e).fontSize}}));
   for(const b of boxes)assert(parseFloat(b.font)>=12);
   for(let i=0;i<boxes.length;i++)for(let j=i+1;j<boxes.length;j++){const a=boxes[i],b=boxes[j];assert(!(a.x<b.x+b.w&&a.x+a.w>b.x&&a.y<b.y+b.h&&a.y+a.h>b.y),'label collision')}
  });
  await check(`${slug}: fit, wheel zoom and drag pan`,async()=>{
   await page.click('#fit');const start=await page.evaluate(()=>window.game67State.view);const box=await page.locator('#stage').boundingBox();
   await page.mouse.move(box.x+box.width/2,box.y+box.height/2);await page.mouse.wheel(0,-300);const zoomed=await page.evaluate(()=>window.game67State.view);assert(zoomed.w<start.w);
   await page.mouse.move(box.x+40,box.y+150);await page.mouse.down();await page.mouse.move(box.x+110,box.y+210);await page.mouse.up();const moved=await page.evaluate(()=>window.game67State.view);assert.notEqual(moved.x,zoomed.x);
   await page.click('#fit');const restored=await page.evaluate(()=>window.game67State.view);assert.equal(restored.w,start.w);
  });
 }
 await page.selectOption('#settlement','albanes');await page.waitForFunction(()=>window.game67State?.slug==='albanes');
 const dev=JSON.parse(await readFile(resolve(root,'samples/albanes.developer.json'))),hidden=dev.establishments.find(e=>e.knowledge==='unknown');
 await check('Public map, index and DOM omit hidden facility identity',async()=>{
  assert(!(await page.content()).includes(hidden.id));assert(!(await page.evaluate(()=>window.game67State.establishmentIds)).includes(hidden.id));
 });
 await page.screenshot({path:resolve(out,'albanes-public.png'),fullPage:true});captures.push('albanes-public.png');
 await page.check('#developer');await page.waitForFunction(()=>window.game67State?.audience==='developer');
 await check('Developer opt-in fetches separate privileged data and reveals actual unknown shop',async()=>{
  assert(requests.some(u=>u.includes('albanes.developer.json')));assert((await page.locator('#mode').textContent()).includes('DEVELOPER'));
  await page.locator(`.place-row[data-id="${hidden.id}"]`).click();assert((await page.locator('#inspection').textContent()).includes('unknown'));
 });
 await check('Developer unknown labels are collision free',async()=>{
  const boxes=await page.locator('.marker-label').evaluateAll(es=>es.map(e=>{const b=e.getBoundingClientRect();return{x:b.x,y:b.y,w:b.width,h:b.height}}));
  for(let i=0;i<boxes.length;i++)for(let j=i+1;j<boxes.length;j++){const a=boxes[i],b=boxes[j];assert(!(a.x<b.x+b.w&&a.x+a.w>b.x&&a.y<b.y+b.h&&a.y+a.h>b.y))}
 });
 await page.screenshot({path:resolve(out,'albanes-developer-hidden.png'),fullPage:true});captures.push('albanes-developer-hidden.png');
 await check('Public download from developer view omits hidden record',async()=>{
  const downloadPromise=page.waitForEvent('download');await page.click('#export');const download=await downloadPromise;const file=await download.path();const data=JSON.parse(await readFile(file));assert.equal(data.audience,'public');assert(!JSON.stringify(data).includes(hidden.id));
 });
 await check('Hypothetical discovery persists in the exported public snapshot',async()=>{
  await page.getByRole('button',{name:'Mark discovered (demo)'}).click();
  const downloadPromise=page.waitForEvent('download');await page.click('#export');const download=await downloadPromise;const data=JSON.parse(await readFile(await download.path()));assert(data.establishments.some(e=>e.id===hidden.id&&e.knowledge==='discovered'));
 });
 await page.uncheck('#developer');await page.waitForFunction(()=>window.game67State?.audience==='public');
 await check('Returning to public clears privileged selection and state',async()=>{assert.equal(await page.evaluate(()=>window.game67State.selectedId),null);assert(!(await page.content()).includes(hidden.id));assert(!(await page.evaluate(()=>window.game67State.establishmentIds)).includes(hidden.id))});
 await check('Filter index and markers agree',async()=>{await page.selectOption('#filter','outdoor');assert.equal(await page.locator('.place-row').count(),5);assert(await page.locator('.marker:not(.outdoor)').count()===0);await page.selectOption('#filter','all')});
 const mobile=await browser.newContext({viewport:{width:390,height:844},deviceScaleFactor:1,isMobile:true,hasTouch:true});const mp=await mobile.newPage();mp.on('pageerror',e=>errors.push(e.message));await mp.goto(base);await mp.waitForFunction(()=>window.game67State?.slug==='batan');
 for(const[slug,type]of [['batan','inn'],['albanes','guildhall'],['thilranlena','warehouse']]) {
  await mp.selectOption('#settlement',slug);await mp.waitForFunction(s=>window.game67State?.slug===s,slug);
  await mp.screenshot({path:resolve(out,`${slug}-mobile-fit.png`),fullPage:true});captures.push(`${slug}-mobile-fit.png`);
  await mp.locator(`.place-row[data-type="${type}"]`).first().tap();await mp.getByRole('button',{name:'Premises view',exact:true}).tap();
  await check(`${slug}: mobile selection, detail panel and no horizontal overflow`,async()=>{assert(await mp.locator('#inspection').isVisible());assert(await mp.evaluate(()=>document.documentElement.scrollWidth<=window.innerWidth));assert(await mp.evaluate(()=>window.game67State.selectedId!==null))});
  await mp.screenshot({path:resolve(out,`${slug}-mobile-close.png`),fullPage:true});captures.push(`${slug}-mobile-close.png`);
 }
 await check('Mobile two-finger pinch changes the map scale',async()=>{
  await mp.locator('#stage').scrollIntoViewIfNeeded();const box=await mp.locator('#stage').boundingBox(),cdp=await mobile.newCDPSession(mp);const before=await mp.evaluate(()=>window.game67State.view.w),x=box.x+box.width/2,y=box.y+box.height/2;
  await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{x:x-25,y,id:1},{x:x+25,y,id:2}]});
  await cdp.send('Input.dispatchTouchEvent',{type:'touchMove',touchPoints:[{x:x-60,y,id:1},{x:x+60,y,id:2}]});
  await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});assert((await mp.evaluate(()=>window.game67State.view.w))<before);
 });
 await check('Mobile map markers support touch selection',async()=>{
  await mp.selectOption('#settlement','batan');await mp.waitForFunction(()=>window.game67State?.slug==='batan');
  await mp.selectOption('#settlement','thilranlena');await mp.waitForFunction(()=>window.game67State?.slug==='thilranlena');assert.equal(await mp.evaluate(()=>window.game67State.selectedId),null);
  await mp.locator('#stage').scrollIntoViewIfNeeded();await mp.locator('.marker[data-type=warehouse]').tap();assert.notEqual(await mp.evaluate(()=>window.game67State.selectedId),null);assert((await mp.locator('#inspection').textContent()).includes('Warehouse'));
 });
 await check('No browser script errors',async()=>assert.deepEqual(errors,[]));
 await writeFile(resolve(out,'browser-results.json'),JSON.stringify({browser:browser.version(),viewport:[1360,1000],mobile:[390,844],results,captures,errors},null,2)+'\n');
 console.log(`PASS ${results.length} browser checks; ${captures.length} actual PNG captures; no page errors`);
} finally {await browser.close()}
