"""Append confirmed bounded corrections; historical1–30 are immutable."""
from pathlib import Path
import hashlib,json,re
ROOT=Path(__file__).resolve().parents[2]
def content():
 p=json.loads((ROOT/'data/rules/trhgd-character-v30.json').read_text(encoding='utf-8'))
 p.update(pack_id='trhgd-character-v31',rules_version='31.0.0')
 prov=dict(origin='Original TRHGD Monk and Paladin mechanical corrections; no sourcebook prose copied',license='Original project-authored content',revision='game123-monk-paladin-acceptance')
 p['provenance']=dict(p['provenance'],revision=prov['revision'])
 abilities={r['id']:r for r in p['abilities']};features={r['id']:r for r in p['features']};statuses={r['id']:r for r in p['statuses']}
 flurry=abilities['flurry'];flurry['requires_weapon']='unarmed';flurry['requirements']=dict(op='tag',id='active_unarmed_weapon')
 flurry['description']='Two strikes with the current unarmed weapon, each at -2 attack, for one main action and no ki. Held weapons, natural forms and manifestations do not qualify. Existing Monk armour restrictions remain.';flurry['provenance']=prov
 smite=abilities['smite'];smite['requires_melee']=True
 smite['requirements']=dict(op='any',args=[dict(op='tag',id='active_'+kind+'_weapon')for kind in ['melee','unarmed','natural']])
 smite['description']='A melee strike against a hostile creature in actual melee reach. Positive Charisma adds to attack and Paladin level to damage; one main action and one smite use, spent even on a miss. Ranged weapons do not qualify. No alignment or piety subsystem is implied.';smite['provenance']=prov
 for level in [1,6]:
  aid=f'monk-wind-{level}';row=abilities[aid]
  for modifier in statuses[aid+'-status']['modifiers']:modifier['type']='insight'
  statuses[aid+'-status']['provenance']=prov
  row['description']='Gain +2 insight stride and Reflex for three global round boundaries. One main action and one ki. Stacks with permanent speed and Evasion training; same-type insight bonuses retain their normal maximum.'
  if level==6:row['description']+=' Also grants nonstacking temporary HP equal to Monk level under the existing separate buffer policy.'
  row['provenance']=prov;features[aid+'-feature']['description']=row['description'];features[aid+'-feature']['provenance']=prov
 for cls in p['classes']:
  if cls['id']!='monk':continue
  for group in cls['career_choices']:
   if group['at']not in [1,6]:continue
   for option in group['options']:
    if option['id']=='wind':option['description']=abilities[f"monk-wind-{group['at']}"]['description']
  cls['provenance']=prov
 return p
def enable_versions(text):
 text=re.sub(r'"trhgd-character-v30"(\s*)\]',r'"trhgd-character-v30","trhgd-character-v31"\1]',text)
 text=text.replace('["trhgd-character-v30","30.0.0",3]]','["trhgd-character-v30","30.0.0",3],["trhgd-character-v31","31.0.0",3]]')
 text=text.replace('pack_id=="trhgd-character-v30"','pack_id in ["trhgd-character-v30","trhgd-character-v31"]')
 text=text.replace('get("pack_id")=="trhgd-character-v30"','get("pack_id") in ["trhgd-character-v30","trhgd-character-v31"]')
 return text.replace('const NEW_PACK := "trhgd-character-v30"','const NEW_PACK := "trhgd-character-v31"')
if __name__=='__main__':
 p=content();out=ROOT/'data/rules/trhgd-character-v31.json';out.write_text(json.dumps(p,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
 pin={k:p[k]for k in ['pack_id','schema_version','rules_version','engine_schema']};pin['content_hash']=hashlib.sha256(json.dumps(p,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()
 path=ROOT/'data/rules/packs.json';manifest=json.loads(path.read_text(encoding='utf-8'));manifest['packs']=[r for r in manifest['packs']if r['rules_ref']['pack_id']!=p['pack_id']];manifest['packs'].append(dict(path='res://data/rules/'+out.name,rules_ref=pin));path.write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8',newline='\n')
 for file in (ROOT/'scripts').rglob('*.gd'):
  before=file.read_text(encoding='utf-8');after=enable_versions(before)
  if after!=before:file.write_text(after,encoding='utf-8',newline='\n')
 print(json.dumps(pin))
