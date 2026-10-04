#!/usr/bin/env python3
"""Verify pinned Game-icons blobs and apply existing project ink preparation."""
import hashlib,json,urllib.request,xml.etree.ElementTree as E
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];PIN='82d948812bfe3f269ef8f731dcdb07b08160edc4';SVG='http://www.w3.org/2000/svg'
E.register_namespace('',SVG)
roles={'guildhall':'delapouite/round-table.svg','smithy':'lorc/anvil.svg','warehouse':'delapouite/warehouse.svg','stable':'delapouite/stable.svg','shop':'delapouite/shop.svg','pier':'delapouite/wooden-pier.svg','tavern':'lorc/beer-stein.svg','inn':'delapouite/bed.svg','chapel':'delapouite/church.svg','manor':'delapouite/family-house.svg','guardhouse':'delapouite/watchtower.svg','well':'delapouite/well.svg','mill':'delapouite/windmill.svg'}
with urllib.request.urlopen(f'https://api.github.com/repos/game-icons/icons/git/trees/{PIN}?recursive=1')as response:tree=json.load(response)
assert not tree.get('truncated');blobs={x['path']:x['sha']for x in tree['tree']if x['type']=='blob'}
records=[]
for role,path in roles.items():
    with urllib.request.urlopen(f'https://raw.githubusercontent.com/game-icons/icons/{PIN}/{path}')as response:raw=response.read()
    gitsha=hashlib.sha1(f'blob {len(raw)}\0'.encode()+raw).hexdigest();assert gitsha==blobs[path],path
    icon=E.fromstring(raw);children=list(icon)
    backdrop=next((el for el in children if el.tag.endswith('path')and el.attrib.get('d','').replace(' ','')in ['M00512v512H0z','M00h512v512H0z']),None)
    if backdrop is None:
        # Original Game-icons uses an explicit square black backdrop as first path.
        candidate=next((x for x in children if x.tag.endswith('path')),None)
        assert candidate is not None and candidate.attrib.get('d')=='M0 0h512v512H0z',path
        backdrop=candidate
    icon.remove(backdrop)
    icon.set('width','64');icon.set('height','64');icon.set('viewBox','0 0 512 512')
    for el in icon.iter():
        for attr in ['fill','stroke']:
            if el.attrib.get(attr)in ['#fff','#ffffff','white']:el.set(attr,'#28221b')
    prepared=E.tostring(icon,encoding='utf-8')
    (ROOT/f'assets/{role}.svg').write_bytes(prepared)
    records.append({'role':role,'source':path,'author':path.split('/')[0],'upstreamCommit':PIN,'gitBlobSha':gitsha,'sourceSha256':hashlib.sha256(raw).hexdigest(),'preparedSha256':hashlib.sha256(prepared).hexdigest(),'licence':'CC BY 3.0','preparation':'Removed original square backdrop; original white ink to project #28221b. Original paths retained.'})
(ROOT/'assets/icon-manifest.json').write_text(json.dumps(records,indent=2)+'\n')
print('PASS:',len(records),'verified Game-icons assets; exact pinned Git blob hashes')
