"""Append only confirmed Ranger/owned-companion repairs; released1–31 are immutable."""
from pathlib import Path
import hashlib,json,re
ROOT=Path(__file__).resolve().parents[2]
def content():
 p=json.loads((ROOT/'data/rules/trhgd-character-v31.json').read_text(encoding='utf-8'))
 p.update(pack_id='trhgd-character-v32',rules_version='32.0.0')
 prov=dict(origin='Original TRHGD Ranger and Beast Steward mechanical corrections; no sourcebook prose copied',license='Original project-authored content',revision='game161-ranger-steward-acceptance')
 p['provenance']=dict(p['provenance'],revision=prov['revision'])
 abilities={r['id']:r for r in p['abilities']};features={r['id']:r for r in p['features']};statuses={r['id']:r for r in p['statuses']}
 aimed=abilities['aimed-shot'];aimed['requirements']=dict(op='tag',id='active_ranged_weapon')
 aimed['description']='An attack with the actual active ranged weapon at +2 accuracy, spending both main action and movement. No tracker resolve cost. Held melee/unarmed, natural forms and melee manifestations cannot make this shot.';aimed['provenance']=prov
 for level in [1,6]:
  aid=f'ranger-archery-{level}';row=abilities[aid]
  for modifier in statuses[aid+'-status']['modifiers']:
   if modifier['stat']=='damage':modifier['when']=dict(op='tag',id='attack_ranged_weapon')
  statuses[aid+'-status']['provenance']=prov
  row['description']='One main action and one tracker resolve: +2 training ranged accuracy and damage for three global-round boundaries. Damage applies only to an actual ranged weapon attack; melee weapons, natural attacks and melee departure reactions receive no Archery damage. Normal same-type bonus stacking remains.'
  if level==6:row['description']+=' Also grants nonstacking temporary HP equal to Ranger level.'
  row['provenance']=prov;features[aid+'-feature']['description']=row['description'];features[aid+'-feature']['provenance']=prov
 for cls in p['classes']:
  if cls['id']!='ranger':continue
  for group in cls['career_choices']:
   if group['id']not in ['ranger-choice-1','ranger-choice-6']:continue
   for option in group['options']:
    if option['id']=='archery':option['description']=abilities[f"ranger-archery-{group['at']}"]['description']
  cls['provenance']=prov
 return p
def enable_versions(text):
 text=re.sub(r'"trhgd-character-v31"(\s*)\]',r'"trhgd-character-v31","trhgd-character-v32"\1]',text)
 text=text.replace('["trhgd-character-v31","31.0.0",3]]','["trhgd-character-v31","31.0.0",3],["trhgd-character-v32","32.0.0",3]]')
 text=text.replace('pack_id=="trhgd-character-v31"','pack_id in ["trhgd-character-v31","trhgd-character-v32"]')
 text=text.replace('get("pack_id")=="trhgd-character-v31"','get("pack_id") in ["trhgd-character-v31","trhgd-character-v32"]')
 text=text.replace('const NEW_PACK := "trhgd-character-v31"','const NEW_PACK := "trhgd-character-v32"')
 if 'class_name RulesEntities' in text:
  text=text.replace('pet.runtime.hp=maxi(0,int(pet.runtime.hp)-deficit)','pet.runtime.hp=0 if source.rules_ref().pack_id=="trhgd-character-v32" and int(previous.record.runtime.hp)==0 else maxi(0,int(pet.runtime.hp)-deficit)')
 return text
if __name__=='__main__':
 p=content();out=ROOT/'data/rules/trhgd-character-v32.json';out.write_text(json.dumps(p,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
 pin={k:p[k]for k in ['pack_id','schema_version','rules_version','engine_schema']};pin['content_hash']=hashlib.sha256(json.dumps(p,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()
 path=ROOT/'data/rules/packs.json';manifest=json.loads(path.read_text(encoding='utf-8'));manifest['packs']=[r for r in manifest['packs']if r['rules_ref']['pack_id']!=p['pack_id']];manifest['packs'].append(dict(path='res://data/rules/'+out.name,rules_ref=pin));path.write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8',newline='\n')
 for file in (ROOT/'scripts').rglob('*.gd'):
  before=file.read_text(encoding='utf-8');after=enable_versions(before)
  if after!=before:file.write_text(after,encoding='utf-8',newline='\n')
 print(json.dumps(pin))
