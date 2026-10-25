"""Append the bounded v30 martial corrections; never rewrite released1–29."""
from pathlib import Path
import hashlib,json,re
ROOT=Path(__file__).resolve().parents[2]
def content():
 p=json.loads((ROOT/'data/rules/trhgd-character-v29.json').read_text(encoding='utf-8'))
 p.update(pack_id='trhgd-character-v30',rules_version='30.0.0')
 prov=dict(origin='Original bounded TRHGD Fighter and Barbarian corrections; no sourcebook prose copied',license='Original project-authored content',revision='game123-martial-acceptance')
 p['provenance']=dict(p['provenance'],revision=prov['revision'])
 features={r['id']:r for r in p['features']};abilities={r['id']:r for r in p['abilities']};statuses={r['id']:r for r in p['statuses']};classes={r['id']:r for r in p['classes']}
 for fid in ['fighter-veteran','point-blank-shot-feature']:
  for m in features[fid]['modifiers']:m['type']='untyped'
  features[fid]['provenance']=prov
 features['fighter-veteran']['description']='Veteran training adds another +1 to melee and ranged weapon attack.'
 features['point-blank-shot-feature']['description']='Ranged attacks gain +1, including alongside Fighter training. This original adaptation is a flat ranged bonus.'
 for style,kind in [('blade','melee'),('bow','ranged')]:
  for level in [1,6]:
   aid=f'fighter-{style}-{level}';row=abilities[aid];status=statuses[aid+'-status']
   row['requirements']=dict(op='tag',id='active_'+kind+'_weapon')
   for m in status['modifiers']:
    m['type']='insight'
    m['when']=dict(op='tag',id=('active_'if m['stat']=='defence'else'attack_')+kind+'_weapon')
   row['description']=('Requires an active melee weapon; unarmed and natural weapons do not qualify. Gain +2 insight melee attack and +1 insight defence'if style=='blade'else'Requires an active ranged weapon. Gain +2 insight ranged attack and +1 insight ranged-weapon damage')+' for three global round boundaries. Main action and one Fighter resolve. Same-type bonuses retain their normal maximum.'
   if level==6:row['description']+=' Also grants nonstacking temporary HP equal to Fighter level; the buffer follows the existing separate temporary-HP policy.'
   row['provenance']=prov;status['provenance']=prov
   features[aid+'-feature']['description']=row['description'];features[aid+'-feature']['provenance']=prov
 for group in classes['fighter']['career_choices']:
  if group['at']not in [1,6]:continue
  for option in group['options']:option['description']=abilities[f"fighter-{option['id']}-{group['at']}"]['description']
 classes['fighter']['description']='A trained martial specialist. Choose melee or ranged discipline, equip its weapon, and share finite resolve between discipline, recovery and advanced techniques. Guard competes for the main action and shared reaction.'
 classes['fighter']['provenance']=prov
 feature=features['barbarian-master-choice-resilient'];feature['modifiers']=[dict(stat='fortitude',type='untyped',value=dict(op='const',value=2))]
 feature['description']='Resilient mastery adds +2 Fortitude, including during Resilient rage.';feature['provenance']=prov
 for group in classes['barbarian']['career_choices']:
  if group['id']=='barbarian-choice-15':
   for option in group['options']:
    if option['id']=='resilient':option['description']='Persistent +2 Fortitude, stacking with Resilient rage training. Requires the original Resilient rage selection.'
 classes['barbarian']['provenance']=prov
 for r in p['resources']:
  if r['id']=='fighter-resolve':r['name']='Fighter resolve';r['provenance']=prov
 return p

def enable_versions(text):
 text=re.sub(r'"trhgd-character-v29"(\s*)\]',r'"trhgd-character-v29","trhgd-character-v30"\1]',text)
 text=text.replace('["trhgd-character-v29","29.0.0",3]]','["trhgd-character-v29","29.0.0",3],["trhgd-character-v30","30.0.0",3]]')
 return text.replace('const NEW_PACK := "trhgd-character-v29"','const NEW_PACK := "trhgd-character-v30"')
if __name__=='__main__':
 p=content();out=ROOT/'data/rules/trhgd-character-v30.json';out.write_text(json.dumps(p,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
 pin={k:p[k]for k in ['pack_id','schema_version','rules_version','engine_schema']};pin['content_hash']=hashlib.sha256(json.dumps(p,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()
 path=ROOT/'data/rules/packs.json';manifest=json.loads(path.read_text(encoding='utf-8'));manifest['packs']=[r for r in manifest['packs']if r['rules_ref']['pack_id']!=p['pack_id']];manifest['packs'].append(dict(path='res://data/rules/'+out.name,rules_ref=pin));path.write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8',newline='\n')
 for file in (ROOT/'scripts').rglob('*.gd'):
  before=file.read_text(encoding='utf-8');after=enable_versions(before)
  if after!=before:file.write_text(after,encoding='utf-8',newline='\n')
 print(json.dumps(pin))
