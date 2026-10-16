"""Conservative identity inventory: spell display-name identity vs class-specific records.
Names are reviewed alongside the exported per-identity rows; variants/references are never new spells.
"""
from pathlib import Path
import json,argparse
root=Path(__file__).resolve().parents[2]
def inventory(version):
 p=json.loads((root/f'data/rules/trhgd-character-v{version}.json').read_text(encoding='utf-8'))
 spells={};other={};channels=0
 for a in p['abilities']:
  if a.get('channel_spell'):channels+=1;continue
  if 'passive'in a['tags'] or a.get('timing',{}).get('kind')!='instant':continue
  if 'spell'in a['tags']:spells.setdefault(a['name'].casefold(),[]).append(a['id'])
  elif not a.get('psychic_power'):other.setdefault(a['name'].casefold(),[]).append(a['id'])
 return dict(pack=p['pack_id'],base_classes=sum(c.get('class_kind')=='base'for c in p['classes']),prestige_classes=sum(c.get('class_kind')=='prestige'for c in p['classes']),ancestry_families=len({a['people_id']for a in p['ancestries']}),heritages=len(p['ancestries']),feats=len(p['feats']),skills=len(p['skills']),unique_spells=len(spells),spell_references=sum(map(len,spells.values())),psychic_powers=len(p['psychic_powers']),other_named_abilities=len(other),other_ability_records=sum(map(len,other.values())),creatures=len(p['creatures']),body_forms=sum('body_form'in x for x in p['statuses']),career_choice_groups=sum(len(x.get('career_choices',[]))for x in p['classes']),channel_delivery_references=channels,spell_identities=spells,other_named_identities=other)
if __name__=='__main__':
 parser=argparse.ArgumentParser();parser.add_argument('--output');parser.add_argument('--versions',nargs='+',type=int,default=[13,14]);args=parser.parse_args()
 result={str(v):inventory(v)for v in args.versions}
 text=json.dumps(result,ensure_ascii=False,indent=2)+'\n'
 if args.output:Path(args.output).write_text(text,encoding='utf-8')
 else:print(text)
