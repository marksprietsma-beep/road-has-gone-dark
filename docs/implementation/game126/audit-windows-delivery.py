"""Independent receipt/archive checks after the Windows job; no mechanical derivation."""
from pathlib import Path
import argparse,json,hashlib,struct,zipfile,subprocess
p=argparse.ArgumentParser(__doc__);p.add_argument('review',type=Path);p.add_argument('evidence',type=Path);p.add_argument('--source',required=True);p.add_argument('--output',type=Path,required=True);args=p.parse_args()
archive=next(args.review.rglob('game126-character-completeness-windows-x64.zip'))
with zipfile.ZipFile(archive)as z:
 assert z.testzip()is None;names=z.namelist();assert len(names)==len(set(names))
 assert all(not n.startswith('/') and '..'not in Path(n).parts for n in names)
 assert not any('road-has-gone-dark-qa' in n for n in names),'Diagnostic executable must not ship'
 def read(suffix):return z.read(next(n for n in names if n.endswith(suffix)))
 for suffix in ['/road-has-gone-dark.exe','/worldgen-helper/node.exe']:
  raw=read(suffix);offset=struct.unpack_from('<I',raw,0x3c)[0]
  assert raw[:2]==b'MZ' and raw[offset:offset+4]==b'PE\0\0' and struct.unpack_from('<H',raw,offset+4)[0]==0x8664
 expected_manifest=subprocess.check_output(['git','show',args.source+':data/rules/packs.json'])
 assert read('/CHARACTER-RULES-MANIFEST.json')==expected_manifest
 assert read('/CORE-CHARACTER-CONTENT.json')==subprocess.check_output(['git','show',args.source+':data/rules/trhgd-character-v16.json'])
 assert json.loads(read('/distribution.json'))['source_commit']==args.source
manifest=json.loads(expected_manifest);pin=next(r['rules_ref']for r in manifest['packs']if r['rules_ref']['pack_id']=='trhgd-character-v16')
sha=hashlib.file_digest(archive.open('rb'),'sha256').hexdigest();assert Path(str(archive)+'.sha256').read_text().split()[0]==sha
proof=json.loads(next(args.evidence.rglob('distribution-proof.json')).read_text())
assert proof['source_commit']==args.source and proof['sha256']==sha and proof['rules_ref']==pin
assert proof['empty_path'] and proof['production_launch'] and proof['separate_process_restart'] and not proof['source_helper_override']
for label,row in proof['proofs'].items():
 assert row['failures']==0 and row['checks']>0,label
 if row.get('rules_ref') and not label.startswith('legacy-v15/'):
  assert row['rules_ref']==pin,label
seen=set();actions=[];skills=set()
for i in range(4):
 row=proof['proofs'][f'journey-{i}'];ids={r['character_id']for r in row['journeys']}
 assert len(ids)==3 and set(row['combat_actions'])==ids,'Three actual adventurers, not companion/summon IDs'
 assert not ids&seen;seen|=ids
 assert all(action not in ['move','end']for action in row['combat_actions'].values())
 assert row['earned_xp']==360 and row['xp_injected']is False
 for r in row['journeys']:assert r['earned_xp']==360 and len(r['history'])==7 and not r['fixture'] and r['rules_ref']==pin
 actions+=list(row['combat_actions'].values());skills.update(row['skills'])
assert len(seen)==12
assert {'skill:'+s for s in ['athletics','stealth','acrobatics','spellcraft','animal-handling']}<=skills
witness=json.loads(next(args.evidence.rglob('audit/witnesses.json')).read_text())
assert witness['rules_ref']==pin and len(witness['classes'])==32
assert all(len(r['levels'])==20 and all(v['ok']for v in r['levels'].values())for r in witness['classes'].values())
compat=json.loads(next(args.evidence.rglob('compatibility/compatibility.json')).read_text())
assert compat['rules_ref']==pin and len(compat['validated'])==485 and not compat['no_current_fixture']
assert len({r['path']for r in compat['validated'].values()})==18
options=json.loads(next(args.evidence.rglob('options/options.json')).read_text())
assert options['rules_ref']==pin and len(options['options']['feats'])==82 and len(options['options']['ancestries'])==50
assert all(row['selectable']for cat in options['options'].values()for row in cat.values())
assert proof['legacy']['checks']==485 and proof['legacy']['failures']==0
result=dict(source_commit=args.source,rules_ref=pin,archive=archive.name,sha256=sha,archive_integrity=True,entries=len(names),game_and_helper_machine='AMD64/0x8664',exact_manifest_and_content=True,production_launch=True,empty_path=True,separate_process_restart=True,source_helper_override=False,actual_adventurer_action_ids_verified=12,level20_base_tracks=32,prestige_full_cap_histories=485,prestige_paths=18,feat_selections=82,heritage_births=50,new_skill_outcomes=sorted(skills),per_option_human_validation=False)
args.output.write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result,indent=2))
