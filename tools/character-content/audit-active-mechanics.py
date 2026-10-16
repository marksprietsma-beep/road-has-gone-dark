"""Conservative mechanics inventory, not a claim that all records have native proof.

Ignores names, class aliases, requirements and numeric progression labels. Expands
referenced status/creature/form/weapon/feature definitions before grouping effects.
The structural count additionally folds numbers, damage dice and formula scaling.
Both counts are upper bounds on distinct design ideas, not a quality/balance score.
"""
from pathlib import Path
import argparse,json,hashlib,re
root=Path(__file__).resolve().parents[2]
def audit(version):
 p=json.loads((root/f'data/rules/trhgd-character-v{version}.json').read_text(encoding='utf-8'))
 tables={key:{r['id']:r for r in p[key]}for key in ['statuses','creatures','features','equipment','resources']}
 reachable=set();powers={r['id']:r for r in p['psychic_powers']}
 for f in p['features']:
  # Exclude orphan legacy abilities left in the immutable source tables.
  used=any(any(t['id']==f['id']for t in c['features'])or any(f['id']in o['features']for g in c.get('career_choices',[])for o in g['options'])for c in p['classes'])or any(f['id']in r['features']for r in p['ancestries']+p['feats'])or any(r['feature_id']==f['id']for r in p['creatures'])
  if used:
   reachable.update(f['abilities'])
   if f.get('known_power')in powers:reachable.update(powers[f['known_power']]['variants'])
 def normalize(value,structural,seen=()):
  if isinstance(value,list):return [normalize(v,structural,seen)for v in value]
  if not isinstance(value,dict):
   if structural and isinstance(value,(int,float))and not isinstance(value,bool):return 'positive'if value>0 else'negative'if value<0 else'zero'
   if structural and isinstance(value,str)and re.fullmatch(r'\d+d\d+',value):return 'damage-dice'
   return value
  if structural and value.get('op')in ['sum','multiply','floor_divide','min','max','class_level','casting_level','level','manifesting_modifier']:
   encoded=json.dumps(value)
   return {'scaling_formula':'progression'if any(word in encoded for word in ['class_level','casting_level','manifesting_modifier','"level"'])else'attribute'if 'modifier'in encoded or 'attribute'in encoded else'stat'if '"stat"'in encoded else'fixed'}
  result={}
  for key,v in value.items():
   if key in ['name','description','provenance','art_status','visual_profile']or key=='id'and 'op'not in value:continue
   table= 'statuses'if key=='id'and value.get('op')in ['apply_status','remove_status']else'features'if key=='feature_id'else'equipment'if key in ['weapon_id','attack_weapon']else'creatures'if key=='creature_id'else None
   if table and isinstance(v,str)and v in tables[table]:
    if (table,v)in seen:result[key]={'recursive':table};continue
    row={k:x for k,x in tables[table][v].items()if k!='id'}
    result[key]=normalize(row,structural,seen+((table,v),));continue
   if key=='id'and value.get('op')in ['class_level','casting_level']:result[key]='own-progression';continue
   if structural and key=='resources'and isinstance(v,dict):
    result[key]=sorted([{'refresh':tables['resources'].get(r,{}).get('refresh','unknown'),'cost':'paid'if cost else'free'}for r,cost in v.items()],key=lambda r:json.dumps(r,sort_keys=True));continue
   if key=='resources'and isinstance(v,dict):
    result[key]=sorted([normalize({'refresh':tables['resources'].get(r,{}).get('refresh','unknown'),'capacity':tables['resources'].get(r,{}).get('capacity',{}),'cost':cost},structural,seen)for r,cost in v.items()],key=lambda r:json.dumps(r,sort_keys=True));continue
   if key=='class_id':result[key]='own-class';continue
   result[key]=normalize(v,structural,seen)
  return result
 exact={};structural={};considered=0;skipped={'passive_or_trigger':0,'delivery_wrappers':0,'psychic_augmentation':0,'base_verbs':0,'no_active_effect':0,'unreachable_legacy':0}
 for a in p['abilities']:
  reason='unreachable_legacy'if a['id']not in reachable else'delivery_wrappers'if a.get('channel_spell')else'base_verbs'if a['id']in p['rules']['base_abilities']else'passive_or_trigger'if 'passive'in a['tags']or a.get('trigger')or a.get('timing',{}).get('kind')!='instant'else'psychic_augmentation'if a.get('psychic_power')and a['id']!=next(r for r in p['psychic_powers']if r['id']==a['psychic_power'])['variants'][0]else'no_active_effect'if not a['effects']and 'weapon_strike'not in a['tags']else None
  if reason:skipped[reason]+=1;continue
  considered+=1
  mechanics={k:a[k]for k in ['effects','cost','targeting','attack_weapon']if k in a}
  mechanics['weapon_strike']='weapon_strike'in a['tags']
  for groups,fold in [(exact,False),(structural,True)]:
   signature=normalize(mechanics,fold)
   if fold:
    targeting=signature['targeting'];targeting['range']='melee'if int(a['targeting'].get('range',1))<=1 else'ranged'
    key=json.dumps(signature,sort_keys=True,separators=(',',':'))
   else:key=json.dumps(signature,sort_keys=True,separators=(',',':'))
   digest=hashlib.sha256(key.encode()).hexdigest()
   groups.setdefault(digest,{'signature':signature,'records':[]})['records'].append(a['id'])
 return dict(pack=p['pack_id'],candidate_active_records=considered,effect_and_cost_signatures=len(exact),conservative_structural_groups=len(structural),skipped=skipped,structural_groups=structural,method='Names, class gates, channel deliveries and psychic augmentation are not new identities. Structural groups additionally fold numerical progression/scaling. This is a conservative source inventory; native execution evidence is separate.')
if __name__=='__main__':
 a=argparse.ArgumentParser();a.add_argument('--versions',nargs='+',type=int,default=[14,15]);a.add_argument('--output',required=True);args=a.parse_args()
 Path(args.output).write_text(json.dumps({str(v):audit(v)for v in args.versions},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
