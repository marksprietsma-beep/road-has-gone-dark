"""Retain pushed v10 exactly; support high-Intelligence careers in immutable v11."""
from pathlib import Path
import copy,json,hashlib
root=Path(__file__).resolve().parents[2]
p=json.loads((root/'data/rules/trhgd-character-v10.json').read_text())
p.update(pack_id='trhgd-character-v11',rules_version='11.0.0')
prov={'origin':'Original TRHGD rank/career support; no proprietary prose or sourcebook data copied','license':'Original project-authored content','revision':'game112-rank-refinement'}
for id,name,attribute in [('nature','Nature','WIS'),('performance','Performance','CHA')]:
    p['skills'].append(dict(id=id,name=name,attribute=attribute,trained_only=False,max_rank='character_level',tags=[],modifiers=[],provenance=prov))
for row in p['classes']:
    if row['id'] in ['druid','ranger']:row['class_skills'].insert(0,'nature')
    if row['id']=='bard':row['class_skills'].insert(0,'performance')
# Actual training changes real resource capacity, using the same formula evaluator.
for pool in p['resources']:
    if pool['id']=='performance':pool['capacity']={'op':'sum','args':[pool['capacity'],{'op':'floor_divide','args':[{'op':'skill_rank','id':'performance'},{'op':'const','value':5}]}]}
for id,name,skill,cls,modifiers,capabilities in [
    ('natural-scholar','Natural scholar','nature','druid',[{'stat':'save_dc','type':'training','value':{'op':'floor_divide','args':[{'op':'skill_rank','id':'nature'},{'op':'const','value':5}]}}],{}),
    ('inspiring-performance','Inspiring performance','performance','bard',[],{'resource_bonuses':{'performance':{'op':'const','value':1}}}),
]:
    feature=id+'-feature'
    p['features'].append(dict(id=feature,name=name,abilities=[],resources=[],modifiers=modifiers,tags=[],senses=[],hooks=[],grants=[],description='Nature ranks improve actual spell DC by1 per5 ranks.' if skill=='nature' else 'Performance training adds one actual performance use.',capabilities=capabilities,provenance=prov))
    p['feats'].append(dict(id=id,name=name,requirements={'op':'all','args':[{'op':'class_level','id':cls,'min':3},{'op':'skill','id':skill,'min':4}]},features=[feature],repeatable=False,choice_parameters=[],provenance=prov))
p['provenance']=dict(prov,revision='game112-wave-one-refined')
(root/'data/rules/trhgd-character-v11.json').write_text(json.dumps(p,indent=2)+'\n')
mp=root/'data/rules/packs.json';m=json.loads(mp.read_text());m['packs']=[r for r in m['packs'] if r['rules_ref']['pack_id']!=p['pack_id']]
pin={k:p[k]for k in ['pack_id','schema_version','rules_version','engine_schema']};pin['content_hash']=hashlib.sha256(json.dumps(p,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()
m['packs'].append({'path':'res://data/rules/trhgd-character-v11.json','rules_ref':pin});mp.write_text(json.dumps(m,indent=2)+'\n')
print(pin)
