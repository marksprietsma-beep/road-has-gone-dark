import {readFileSync,existsSync} from 'node:fs';
import {join} from 'node:path';
import test from 'node:test';
import assert from 'node:assert/strict';
import {SEMANTICS,SITE_ROLES,settlementRole} from '../../tools/regiongen/shared-map-icons.mjs';
test('one manifest supplies truthful atlas/local semantics and original approved artwork',()=>{
 for(const role of new Set([...SEMANTICS.settlement_roles,...Object.values(SITE_ROLES),...Object.values(SEMANTICS.marker_aliases),SEMANTICS.fallback])){
  const path=join('assets/map_icons/trials/game-icons',role+'.svg');assert(existsSync(path));assert.match(readFileSync(path,'utf8'),/<svg/);
 }
 for(const role of SEMANTICS.settlement_roles)assert.equal(settlementRole({group:role}),role);
 assert.equal(settlementRole({group:'trading_post'}),'trading');
 assert.equal(settlementRole({group:'unrecognised',capital:1}),'capital');
 for(const kind of ['camp','clearing','roadside','dangerous_woods'])assert.equal(SITE_ROLES[kind],'encounters');
 assert.equal(SITE_ROLES.ruins,'ruins');assert.equal(SEMANTICS.marker_aliases.caves,'cave');
 const credits=JSON.parse(readFileSync('assets/map_icons/trials/game-icons/landmark_sources.json'));
 assert.match(credits.licence,/CC BY 3.0/);assert.equal(credits.upstreamCommit,'82d948812bfe3f269ef8f731dcdb07b08160edc4');
});
