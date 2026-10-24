"""Append only the verified advanced-casting corrections; keep1–27 immutable."""
from pathlib import Path
import hashlib,json
root=Path(__file__).resolve().parents[2];p=json.loads((root/'data/rules/trhgd-character-v27.json').read_text(encoding='utf-8'))
p.update(pack_id='trhgd-character-v28',rules_version='28.0.0');p['provenance']=dict(p['provenance'],revision='duskblade-archmage-acceptance')
changed=[]
for row in p['abilities']:
 if not row['id'].startswith('high-arcana-'):continue
 row['tags'].append('supernatural')
 row['description']+=' Supernatural; unavailable while a form suppresses supernatural casting.'
 if row['id'].startswith('high-arcana-force-'):
  row['effects'][0]['dc']['args'][1]={'op':'casting_modifier','id':'archmage'}
  row['description']+=' The save DC uses the casting attribute of your permanently selected arcane progression.'
 if row['id'].startswith('high-arcana-ward-'):
  level=int(row['id'].rsplit('-',1)[1])
  clears=['weakened','arcane-tether'] if level>=3 else []
  if level==5:clears+=['slowed','unsteady-concentration','stillness-lattice']
  if clears:
   row['effects']=[{'op':'remove_status','id':sid}for sid in clears]+row['effects']
   row['name']='High arcana: '+('cleansing ward'if level==3 else'liberating ward')
   row['description']+=' Also clears '+', '.join(sid.replace('-',' ')for sid in clears)+'. No universal dispel, resurrection, restored actions or resources.'
  row['description']+=' Ward lasts three global boundaries: Defence+2 and fire/cold/electricity resistance3. The separate temporary-HP buffer is10+2 per Archmage level and never stacks.'
 row['provenance']=dict(row['provenance'],revision='duskblade-archmage-acceptance');changed.append(row['id'])
assert len(changed)==6
archmage=next(row for row in p['classes']if row['id']=='archmage')
for group in archmage['career_choices']:
 if not group['id'].startswith('high-arcana-'):continue
 level=int(group['at'])
 for option in group['options']:
  if option['id']=='force':option['description']=f'Main action and one High Arcana use: range5, enemy burst radius1; Reflex negates {8+3*level} force damage and off-balance. DC15 + your permanently selected caster modifier + save-DC bonuses.'
  else:
   option['description']='Main action and one High Arcana use: range5, allied radius1. Defence+2 and elemental resistance3 for three global boundaries; separate nonstacking buffer10+2 per Archmage level.'
   if level>=3:option['description']+=' Clears Weakened and Arcane tether.'
   if level==5:option['description']+=' Also clears Slowed, Unsteady concentration and Stillness lattice. It does not restore spent actions; a caster whose main action is suppressed needs an ally.'

(root/'data/rules/trhgd-character-v28.json').write_text(json.dumps(p,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
pin={k:p[k]for k in ['pack_id','schema_version','rules_version','engine_schema']};pin['content_hash']=hashlib.sha256(json.dumps(p,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()
f=root/'data/rules/packs.json';manifest=json.loads(f.read_text(encoding='utf-8'));manifest['packs']=[r for r in manifest['packs']if r['rules_ref']['pack_id']!=p['pack_id']];manifest['packs'].append({'path':'res://data/rules/'+p['pack_id']+'.json','rules_ref':pin});f.write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8',newline='\n');print(json.dumps({'rules_ref':pin,'changed_abilities':changed}))
