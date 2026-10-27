"""Four Windows-reproduced corrections; preserve all released v1–v32 bytes/pins."""
from pathlib import Path
import hashlib,json,re
ROOT=Path(__file__).resolve().parents[2]
def content():
 p=json.loads((ROOT/'data/rules/trhgd-character-v32.json').read_text(encoding='utf-8'))
 p.update(pack_id='trhgd-character-v33',rules_version='33.0.0')
 prov=dict(origin='Original TRHGD Grove Warden and Bonded Summoner corrections; no sourcebook prose copied',license='Original project-authored content',revision='game163-grove-summoner-acceptance')
 p['provenance']=dict(p['provenance'],revision=prov['revision'])
 classes={x['id']:x for x in p['classes']};grove=classes['grove-warden'];bonded=classes['bonded-summoner']
 nature=[x['id']for x in grove['career_choices'][0]['options']]
 grove['requirements']['args'] += [dict(op='spell_tier',id='divine',min=3),dict(op='any',args=[dict(op='class_level',id=identity,min=3)for identity in nature])]
 grove['description']='Three earned prestige levels: advance a selected existing nature caster, protect nearby living allies and owned creatures through a finite sanctuary, and spend Grove Favour on renewal. Requires permanent divine tier3 magic, Spirit Reserve and an existing eligible nature parent. Body-form suppression, actual range/line of sight and global expiry remain; no forest-travel engine.'
 grove['provenance']=prov
 parents=[x for x in p['classes']if x.get('class_kind')=='base'and x.get('casting_tradition')=='arcane'and x.get('spell_mode')]
 bonded['requirements']['args'] += [dict(op='spell_tier',id='arcane',min=3),dict(op='any',args=[dict(op='class_level',id=x['id'],min=1)for x in parents])]
 bonded['career_choices']=[dict(id='bonded-casting',name='Existing arcane progression',at=1,options=[dict(id=x['id'],name=x['name'],description='Each prestige level advances only this existing caster: its own casting attribute, spell tiers, repertoire and slots. Prepared/spontaneous restrictions and finite class-call reserve remain independent; no unrelated base-class powers or borrowed slots. A junior parent advances from its own level.',features=[],requirements=dict(op='class_level',id=x['id'],min=1),advance_casting=x['id'],progression_class='bonded-summoner')for x in parents])]
 bonded['description']='Five earned prestige levels: explicitly advance an existing arcane caster and keep a separate finite reserve of supernatural creature calls. Selected temporary creatures have their own turns, natural attacks and distinct finite special actions. One active summon per owner across spells and class calls; existing durations and species remain. No permanent Ranger bond or second summon engine.'
 bonded['provenance']=prov
 feature_ids={x['id']for x in bonded['features']}
 calls={a for f in p['features']if f['id']in feature_ids for a in f['abilities']}
 for a in p['abilities']:
  if a['id']in calls and any(e.get('op')=='summon'for e in a['effects']):
   assert not a['tags'];a['tags']=['supernatural'];a['description']+=' Supernatural calling is suppressed in an altered body; the unchanged main/use cost and shared one-summon limit still apply.';a['provenance']=prov
 return p

def enable_versions(text):
 text=re.sub(r'"trhgd-character-v32"(\s*)\]',r'"trhgd-character-v32","trhgd-character-v33"\1]',text)
 text=text.replace('["trhgd-character-v32","32.0.0",3]]','["trhgd-character-v32","32.0.0",3],["trhgd-character-v33","33.0.0",3]]')
 text=text.replace('pack_id=="trhgd-character-v32"','pack_id in ["trhgd-character-v32","trhgd-character-v33"]')
 text=text.replace('get("pack_id")=="trhgd-character-v32"','get("pack_id") in ["trhgd-character-v32","trhgd-character-v33"]')
 return text.replace('const NEW_PACK := "trhgd-character-v32"','const NEW_PACK := "trhgd-character-v33"')
if __name__=='__main__':
 p=content();(ROOT/'data/rules/trhgd-character-v33.json').write_text(json.dumps(p,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
 pin={k:p[k]for k in ['pack_id','schema_version','rules_version','engine_schema']};pin['content_hash']=hashlib.sha256(json.dumps(p,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()
 path=ROOT/'data/rules/packs.json';m=json.loads(path.read_text(encoding='utf-8'));m['packs']=[r for r in m['packs']if r['rules_ref']['pack_id']!=p['pack_id']];m['packs'].append(dict(path='res://data/rules/trhgd-character-v33.json',rules_ref=pin));path.write_text(json.dumps(m,indent=2)+'\n',encoding='utf-8',newline='\n')
 for f in (ROOT/'scripts').rglob('*.gd'):
  before=f.read_text(encoding='utf-8');after=enable_versions(before)
  if before!=after:f.write_text(after,encoding='utf-8',newline='\n')
 print(json.dumps(pin))
