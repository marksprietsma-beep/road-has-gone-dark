"""Independent GAME-133 archive and native receipt checks; no rules reimplementation."""
from pathlib import Path
import argparse,json,hashlib,struct,zipfile,subprocess
p=argparse.ArgumentParser();p.add_argument('review',type=Path);p.add_argument('evidence',type=Path);p.add_argument('--source',required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args()
archive=next(a.review.rglob('game133-spell-repertoires-windows-x64.zip'))
with zipfile.ZipFile(archive)as z:
 assert z.testzip()is None;names=z.namelist();assert len(names)==len(set(names))
 assert all(not n.startswith('/')and'..'not in Path(n).parts for n in names)
 assert not any('road-has-gone-dark-qa'in n for n in names)
 def read(suffix):return z.read(next(n for n in names if n.endswith(suffix)))
 for suffix in ['/road-has-gone-dark.exe','/worldgen-helper/node.exe']:
  b=read(suffix);offset=struct.unpack_from('<I',b,0x3c)[0]
  assert b[:2]==b'MZ'and b[offset:offset+4]==b'PE\0\0'and struct.unpack_from('<H',b,offset+4)[0]==0x8664
 manifest=subprocess.check_output(['git','show',a.source+':data/rules/packs.json'])
 assert read('/CHARACTER-RULES-MANIFEST.json')==manifest
 assert read('/CORE-CHARACTER-CONTENT.json')==subprocess.check_output(['git','show',a.source+':data/rules/trhgd-character-v18.json'])
 meta=json.loads(read('/distribution.json'));assert meta['source_commit']==a.source and meta['platform']=='win32'and meta['arch']=='x64'
 assert meta['executable_sha256']==hashlib.sha256(read('/road-has-gone-dark.exe')).hexdigest()
 assert read('/START-HERE.txt')and read('/artwork/ART-CREDITS.txt')
pin=next(x['rules_ref']for x in json.loads(manifest)['packs']if x['rules_ref']['pack_id']=='trhgd-character-v18')
sha=hashlib.file_digest(archive.open('rb'),'sha256').hexdigest();assert Path(str(archive)+'.sha256').read_text().split()[0]==sha
proof=json.loads(next(a.evidence.rglob('distribution-proof.json')).read_text())
assert proof['source_commit']==a.source and proof['sha256']==sha and proof['rules_ref']==pin
assert proof['empty_path']and proof['production_launch']and proof['separate_process_restart']and not proof['source_helper_override']
for k,v in proof['proofs'].items():assert v['checks']>0 and v['failures']==0,k
for k in ['mechanics/proof.json','mechanics/restart-proof.json']:assert proof['proofs'][k]['rules_ref']==pin
for k in ['legacy/proof.json','legacy/restart-proof.json']:assert proof['proofs'][k]['rules_ref']['pack_id']=='trhgd-character-v16'
j=proof['proofs']['journey/proof.json'];assert j['earned_xp']==490 and j['xp_injected']is False and len(j['journeys'])==3
assert {x['character_id']for x in j['journeys']}==set(j['combat_actions'])
assert set(j['combat_actions'].values())=={'sorcerer-crystal-reservoir','druid-bramble-tether','attack'}
assert all(x['earned_xp']==490 and len(x['history'])==8 and not x['fixture']and x['rules_ref']==pin for x in j['journeys'])
assert proof['captures']['failures']==0 and len(proof['captures']['screenshots'])>=14
for file in ['proof.json','restart-proof.json']:
 c=proof['proofs']['connected/'+file];assert c['failures']==0 and c['checks']>0 and c['rules_ref']==pin
assert len(proof['proofs']['connected/proof.json']['casts'])==2 and proof['proofs']['connected/proof.json']['xp_injected']is False
for row in proof['captures']['screenshots']:
 f=next(a.evidence.rglob(row['file']));b=f.read_bytes();assert b[:8]==b'\x89PNG\r\n\x1a\n'and hashlib.sha256(b).hexdigest()==row['sha256']
 if not row['development_fixture']:assert row['earned_xp']==490
result=dict(source_commit=a.source,rules_ref=pin,archive=archive.name,sha256=sha,entries=len(names),zip_crc_and_paths=True,game_and_helper_machine='AMD64/0x8664',exact_manifest_and_content=True,production_launch=True,empty_path=True,separate_process_restart=True,earned_characters=3,earned_xp_each=490,earned_level=8,high_level_histories='development fixtures, not earned level20',screenshots=len(proof['captures']['screenshots']),all_receipts_pass=True,scope='Focused Sorcerer/Druid repertoire cohort, not complete character catalogue or human acceptance.')
a.output.write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result,indent=2))
