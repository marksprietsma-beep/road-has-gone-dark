"""Account for the pinned GAME-88 transcription; never infer that an entry is playable.

Usage: python tools/character-content/coverage.py /path/to/DND35-CHARACTER-OPTIONS-CATALOGUE.md
The input must be the research branch's c09e586 snapshot, not arbitrary live index pages.
Existing authored statuses/exceptions survive regeneration by stable source ID.
"""
import argparse,hashlib,json,pathlib,re
root=pathlib.Path(__file__).resolve().parents[2]
parser=argparse.ArgumentParser();parser.add_argument('catalogue',type=pathlib.Path);parser.add_argument('--check',action='store_true');args=parser.parse_args()
text=args.catalogue.read_text(encoding='utf-8');target=root/'docs/implementation/game104/COVERAGE.json'
previous=json.loads(target.read_text());assert hashlib.sha256(text.encode()).hexdigest()==previous['source']['sha256'],'Wrong research revision; review before replacing the source pin'
prior={r['id']:r for r in previous['entries']}
sections=[('base_class',text.split('# 1. ')[1].split('# 2. ')[0].split('## Variant-class mechanisms')[0]),('ancestry',text.split('# 2. ')[1].split('## TRHGD interpretation')[0]),('prestige',text.split('# 3. ')[1].split('## What prestige classes')[0])]
entries=[]
for category,section in sections:
 group='';rows={}
 for line in section.splitlines():
  if line.startswith('## '):group=line[3:]
  names=[]
  if line.startswith('- '):names=[line[2:].strip()]
  elif category=='base_class' and line.startswith('Core DMG'):
   names=re.search(r'\*\*(.*?)\*\*',line).group(1).split(', ')+['Magewright','Religious Adept','Urban Adept']
  elif category=='base_class' and group and line and not line.startswith(('#','The','---')) and line.endswith('.'):
   names=line.rstrip('.').split(', ')
  for name in names:
   if category=='base_class' and len(name)>45:continue
   stable=category+'-'+re.sub('[^a-z0-9]+','-',name.lower()).strip('-')
   if name not in rows:
    assert stable in prior,'New source entry requires explicit design/licensing review: '+name
    rows[name]=dict(prior[stable]);rows[name]['source_groups']=[]
   rows[name]['source_groups'].append(group)
 entries.extend(rows.values())
assert len({r['id']for r in entries})==len(entries)
assert {r['id']for r in entries}==set(prior),'Lost or fabricated research entries'
for row in entries:
 assert row['status']in ['researched','designed','implemented','mechanically_validated','playable']
 assert row['playable']==(row['status']=='playable')
 assert row['licensing']['strategy'] and row['intended_implementation']['kind']
 if row['playable']:assert row.get('evidence'),'Playable requires concrete journey evidence'
 if row['intended_implementation']['kind']=='exception':assert row.get('exception_reason')
 if row['category']=='base_class' and row['source_groups']==['NPC / non-adventurer class families']:
  row['intended_implementation']['kind']='npc_capability_or_optional_career'
 row['design_key']=row['id'] # Separate from a released rules ID; not an invented production option.
 row['blocking_subsystems']=['typed inherited traits, body/size/senses/resistance, source-specific design'] if row['category']=='ancestry' else ['specific feature progression and action/casting/resource support','real creation, advancement, combat and persistence proof']
 row['next_action']='Write an original per-entry design preserving its distinct concepts; verify licence before any source text/data reuse.'
previous['entries']=entries
previous['counts']={c:sum(r['category']==c for r in entries)for c,_ in sections}
previous['counts']['adventurer_base_classes']=sum(r['category']=='base_class' and r['source_groups']!=['NPC / non-adventurer class families']for r in entries)
previous['counts']['npc_class_families']=8
encoded=json.dumps(previous,indent=2)+'\n'
if args.check:assert target.read_text()==encoded,'Coverage drift; regenerate and review'
else:target.write_text(encoded)
print(json.dumps({'counts':previous['counts'],'covered':len(entries),'playable_catalogue_entries':sum(r['playable']for r in entries)}))
