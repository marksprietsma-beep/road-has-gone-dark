"""GAME-146: append v20; original movement/precision/fencing adaptations."""
from pathlib import Path
import json,hashlib,copy
root=Path(__file__).resolve().parents[2]
p=copy.deepcopy(json.loads((root/'data/rules/trhgd-character-v19.json').read_text()))
p.update(pack_id='trhgd-character-v20',rules_version='20.0.0')
p['provenance']['revision']='game146-mobile-precision'
def row(cat,id):return next(x for x in p[cat] if x['id']==id)
# Equipment descriptors, not ancestry/class enums.
row('equipment','shortblade')['tags'].append('fencing_weapon')
row('equipment','mail')['tags'].append('medium_armor')
condition={'op':'tag','id':'fencing_ready'}
f=row('features','swashbuckler-finesse')
for m in f['modifiers']:m['when']=condition
f['description']='Use Dexterity instead of lower Strength for Travel Blade attack accuracy in light/no armour without a shield. No ranged or natural-weapon benefit.'
for a in p['abilities']:
 if a['id'].startswith(('swashbuckler-technique-','swashbuckler-master-')) or a['id'].startswith('duelist-power-'):
  a['requires_fencing']=True;a['requires_melee']=True
  a['strike_effects']=a['effects'];a['effects']=[]
  if a['id'].startswith('swashbuckler'):a['name']=a['name'].replace('Disarming flourish','Fencing flourish')
  a['description']='Main action and listed resolve/uses; light/no armour, Travel Blade, no shield, no transformed body. Only a confirmed melee hit delivers the listed fencing/weakening effects. A miss or concealment spends the action/resource without effects. Does not disarm.'
# Scout weapon control follows the same confirmed-hit contract; a missed shot
# cannot inflict Off Balance or clear the shooter's conditions for free.
for a in p['abilities']:
 if a['id'].startswith('scout-') and 'weapon_strike' in a['tags']:
  a['strike_effects']=a['effects'];a['effects']=[]
  a['description']='Main action and listed Scout resolve; weapon targeting/range apply. Only a confirmed hit delivers the listed control, recovery or temporary-HP effects. Misses/concealment still spend action and resolve. Skirmish additionally requires actual movement this activation.'
row('abilities','precision')['description']='First confirmed ordinary weapon hit per activation against an enemy threatened by an adjacent allied melee combatant. +2 damage per two combined Rogue/Arcane Trickster levels (rounded up); concealment and misses do not qualify. Reactions do not trigger it. Can combine with actual-movement skirmish on that same hit.'
# Prestige progression grants the same executable consumer, not an independent proc.
fid='arcane-trickster-opening'
p['features'].append(dict(id=fid,name='Trickster opening',abilities=['precision'],resources=[],modifiers=[],tags=[],senses=[],hooks=[],grants=[],description='Arcane Trickster levels contribute to the shared Rogue precision progression; one opening per activation, never an extra automatic attack.',provenance=dict(f['provenance'],revision='game146-mobile-precision')))
cls=row('classes','arcane-trickster')
# Class feature schedule uses {at,id} records.
cls['features'].append(dict(at=1,id=fid))
path=root/'data/rules/trhgd-character-v20.json';path.write_text(json.dumps(p,ensure_ascii=False,indent=2)+'\n')
pin={k:p[k]for k in ['pack_id','schema_version','rules_version','engine_schema']};pin['content_hash']=hashlib.sha256(json.dumps(p,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()
mp=root/'data/rules/packs.json';m=json.loads(mp.read_text());m['packs']=[x for x in m['packs']if x['rules_ref']['pack_id']!=p['pack_id']]+[dict(path='res://data/rules/'+path.name,rules_ref=pin)];mp.write_text(json.dumps(m,indent=2)+'\n')
print(json.dumps(pin))
