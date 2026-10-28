"""Bounded existing-career v34 corrections; every released v1–v33 stays immutable."""
from pathlib import Path
import hashlib,json,re
ROOT=Path(__file__).resolve().parents[2]
def content():
 p=json.loads((ROOT/'data/rules/trhgd-character-v33.json').read_text(encoding='utf-8'))
 p.update(pack_id='trhgd-character-v34',rules_version='34.0.0')
 prov=dict(origin='Original TRHGD Dragon Disciple and Warshaper adaptations; no sourcebook prose copied',license='Original project-authored content',revision='game167-dragon-warshaper-acceptance')
 p['provenance']=dict(p['provenance'],revision=prov['revision'])
 classes={x['id']:x for x in p['classes']};abilities={x['id']:x for x in p['abilities']};statuses={x['id']:x for x in p['statuses']};features={x['id']:x for x in p['features']}
 dragon=classes['dragon-disciple'];morph=classes['warshaper']
 parents=[x for x in p['classes']if x.get('class_kind')=='base'and x.get('casting_tradition')=='arcane'and x.get('spell_mode')]
 dragon['requirements']['args'] += [dict(op='spell_tier',id='arcane',min=3),dict(op='any',args=[dict(op='class_level',id=x['id'],min=1)for x in parents])]
 dragon['career_choices'][0]['options']=[dict(id=x['id'],name=x['name'],description='Every two Dragon levels advance only this existing caster once, from its own level and casting attribute. Prepared/spontaneous choices and class pools stay independent; no unrelated base-class powers.',features=[],requirements=dict(op='class_level',id=x['id'],min=1),advance_casting=x['id'],progression_class='dragon-disciple',advance_ratio=2)for x in parents]
 dragon['description']='Ten earned prestige levels: permanent level5, Arcana4 and actual arcane tier3 magic; choose an existing arcane parent. Scales and improved unarmed claws retain original ancestry. A finite draconic reserve competes between single-target breath, self ward, weakening breath and a two-use clustered crownfire burst. Supernatural powers are suppressed while transformed; no flight or ancestry replacement.'
 dragon['provenance']=prov
 features['dragon-disciple-scales'].update(name='Draconic scales and claws',description='Permanent defence +2 training and unarmed damage 1d6. Uses actual equipment/proficiency and the original ancestry; not an extra body form or a free weapon action.',provenance=prov)
 names={1:'Ember breath',4:'Scale mantle',7:'Weakening breath',10:'Crownfire breath'}
 for at,name in names.items():
  a=abilities['dragon-disciple-technique-'+str(at)];a.update(name=name,tags=['supernatural'],provenance=prov)
  features['dragon-disciple-technique-'+str(at)+'-feature'].update(name=name,description='Finite draconic technique; competes for the same reserve and main action. Fire resistance '+str(at)+'.',provenance=prov)
 abilities['dragon-disciple-technique-1']['description']='One main action and one draconic use: enemy within4/line of sight, fire5 + Dragon level; Reflex DC11 + Charisma modifier + save DC bonus halves damage. Fire resistance applies. Suppressed in a transformed body.'
 ward=abilities['dragon-disciple-technique-4'];ward['effects']=[dict(op='temporary_hp',amount=dict(op='sum',args=[dict(op='const',value=4),dict(op='class_level',id='dragon-disciple')])),dict(op='apply_status',id='dragon-disciple-scale-mantle')];ward['targeting']=dict(kind='self',range=0,radius=0)
 ward['description']='One main action and one draconic use: self gains4 + Dragon level temporary HP (maximum, never stacking or healing) and +2 condition defence for3 global rounds. Competes with breath; suppressed in a transformed body. The buffer is absorbed by damage and does not expire with the defence status.'
 p['statuses'].append(dict(id='dragon-disciple-scale-mantle',tags=[],duration=dict(type='round',amount=3,expiry='global_round_start'),stacking='refresh',modifiers=[dict(stat='defence',type='condition',value=dict(op='const',value=2))],effects=[],provenance=prov))
 weak=abilities['dragon-disciple-technique-7'];weak['effects'].append(dict(op='save',save='fortitude',dc=dict(op='sum',args=[dict(op='const',value=14),dict(op='modifier',id='CHA'),dict(op='stat',id='save_dc')]),on_failure=[dict(op='apply_status',id='weakened')],on_success=[]))
 weak['description']='One main action and one draconic use: original saved fire breath, plus an independent Fortitude DC14 + Charisma modifier + save DC bonus. Failure applies the existing three-round Weakened condition: melee attack and weapon damage -2. Fire resistance and each save resolve independently; no invented fear/forced-movement engine. Suppressed in a transformed body.'
 crown=abilities['dragon-disciple-technique-10'];crown['cost']['resources']['dragon-disciple-uses']=2;crown['targeting']['radius']=1
 crown['description']='One main action and TWO draconic uses: original Reflex-saved fire damage to an enemy within4 and its living nearby allies within1, subject to existing area line of sight. Each target saves independently; fire resistance applies. Spacing counters the burst. No friendly fire expansion; suppressed in a transformed body.'
 morph['description']='Five earned prestige levels requiring permanent level5, BAB4 and Druid Shape. Paid three-round natural bodies share one finite reserve: Predatory frame, Longclaw reach3, or Ironhide physical resistance2. Actual claws, attributes, equipment suppression, original health, reversion and expiry use the existing body authority. Original ancestry and owned creatures are retained.';morph['provenance']=prov
 for at,name in [(1,'Predatory frame'),(3,'Longclaw frame'),(5,'Ironhide frame')]:
  a=abilities['warshaper-technique-'+str(at)];a.update(name=name,provenance=prov)
  f=features['warshaper-technique-'+str(at)+'-feature'];f.update(name=name,description='Paid alternate natural frame; original body/health/equipment return on reversion or expiry.',provenance=prov)
  s=statuses['warshaper-technique-'+str(at)+'-form'];s['modifiers'][0]['type']='untyped';s['provenance']=prov
  if at==3:s['modifiers'].append(dict(stat='reach',type='untyped',value=dict(op='const',value=1)))
  if at==5:s['capabilities']=dict(resistances=dict(physical=2))
  a['description']='One main action and one morphic use: large natural body for3 global rounds; claws1d10, STR+'+str(s['body_form']['attributes']['STR'])+', DEX-2, '+('reach3; +1 defence beyond bear anatomy'if at==3 else'reach2; +2 defence beyond bear anatomy and physical resistance2'if at==5 else'reach2')+'. Equipment melds; magic is suppressed. May replace another form or revert; original HP, ancestry, conditions, companions and summon ownership remain. No flight or automatic healing.'
 for r in p['resources']:
  if r['id']=='dragon-disciple-uses':r.update(name='Draconic reserve',provenance=prov)
  if r['id']=='warshaper-uses':r.update(name='Morphic reserve',provenance=prov)
 return p

def enable_versions(text):
 text=re.sub(r'"trhgd-character-v33"(\s*)\]',r'"trhgd-character-v33","trhgd-character-v34"\1]',text)
 text=text.replace('["trhgd-character-v33","33.0.0",3]]','["trhgd-character-v33","33.0.0",3],["trhgd-character-v34","34.0.0",3]]')
 text=text.replace('pack_id=="trhgd-character-v33"','pack_id in ["trhgd-character-v33","trhgd-character-v34"]')
 text=text.replace('get("pack_id")=="trhgd-character-v33"','get("pack_id") in ["trhgd-character-v33","trhgd-character-v34"]')
 return text.replace('const NEW_PACK := "trhgd-character-v33"','const NEW_PACK := "trhgd-character-v34"')
if __name__=='__main__':
 p=content();(ROOT/'data/rules/trhgd-character-v34.json').write_text(json.dumps(p,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
 pin={k:p[k]for k in ['pack_id','schema_version','rules_version','engine_schema']};pin['content_hash']=hashlib.sha256(json.dumps(p,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()
 path=ROOT/'data/rules/packs.json';m=json.loads(path.read_text(encoding='utf-8'));m['packs']=[r for r in m['packs']if r['rules_ref']['pack_id']!=p['pack_id']];m['packs'].append(dict(path='res://data/rules/trhgd-character-v34.json',rules_ref=pin));path.write_text(json.dumps(m,indent=2)+'\n',encoding='utf-8',newline='\n')
 for f in (ROOT/'scripts').rglob('*.gd'):
  before=f.read_text(encoding='utf-8');after=enable_versions(before)
  if before!=after:f.write_text(after,encoding='utf-8',newline='\n')
 print(json.dumps(pin))
