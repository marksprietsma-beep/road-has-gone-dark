"""Append v16 competence repairs; never execute historical pack generators."""
from pathlib import Path
import hashlib,json
root=Path(__file__).resolve().parents[2]
p=json.loads((root/'data/rules/trhgd-character-v15.json').read_text())
p.update(pack_id='trhgd-character-v16',rules_version='16.0.0')
p['provenance']['revision']='game126-character-completeness'
def approach(skill,activities,label,information,event,outcome,provisions=0,gain=0,reveal=False,dc=0):
 return dict(skill=skill,activities=activities,min_ranks=1,label=label,information=information,event=event,outcome=outcome,provisions=provisions,gain=gain,reveal=reveal,dc_adjustment=dc)
p['rules']['skill_approaches']=[
 approach('athletics',['lost_supplies','abandoned_shelter'],'Haul the recoverable stores','Use trained hauling to recover more of the supplies already reported here; a failed attempt completes no objective.','recover','recovered',provisions=1,gain=4,dc=2),
 approach('stealth',['camp_access','salvage_dispute','road_passage'],'Seek quiet access','Attempt access without bargaining away supplies. This does not defeat the occupants or claim the site is cleared.','negotiate','peaceful_access',dc=2),
 approach('acrobatics',['old_work','unusual_traces'],'Make a quick survey','Attempt a faster survey of the reported remains; failure produces no discovery or XP. No climbing or flight is simulated.','quick','investigated',reveal=True,dc=2),
 approach('spellcraft',['old_work','unusual_traces'],'Assess an arcane interpretation','Assess whether an arcane interpretation fits the existing report. This check does not establish that magic is present.','inspect','investigated',reveal=True),
 approach('animal-handling',['unusual_traces'],'Assess animal behaviour','Assess animal behaviour as one possible explanation for the reported tracks. This does not invent an animal encounter.','inspect','investigated',reveal=True),
]
a=next(c for c in p['classes'] if c['id']=='archmage')
assert a['requirements']['args'][-1]['op']=='any'
a['requirements']['args'][-1]=dict(op='spell_tier',id='arcane',min=7)
a['description']+=' Entry requires permanent access to an actual legal seventh-tier arcane spell, not nominal slot capacity or a temporary effect.'
path=root/'data/rules/trhgd-character-v16.json';path.write_text(json.dumps(p,ensure_ascii=False,indent=2)+'\n')
mp=root/'data/rules/packs.json';manifest=json.loads(mp.read_text())
pin={k:p[k] for k in ['pack_id','schema_version','rules_version','engine_schema']};pin['content_hash']=hashlib.sha256(json.dumps(p,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()
manifest['packs']=[x for x in manifest['packs'] if x['rules_ref']['pack_id']!=p['pack_id']]+[dict(path='res://data/rules/'+path.name,rules_ref=pin)]
mp.write_text(json.dumps(manifest,indent=2)+'\n');print(json.dumps(pin))
