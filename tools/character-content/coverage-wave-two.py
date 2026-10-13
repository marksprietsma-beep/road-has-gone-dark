"""Preserve every source occurrence; record bounded original Wave Two adaptations."""
from pathlib import Path
import json,argparse
root=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('--validated',action='store_true');a=p.parse_args()
path=root/'docs/implementation/game104/COVERAGE.json';coverage=json.loads(path.read_text());pack=json.loads((root/'data/rules/trhgd-character-v12.json').read_text())
additions={'base_class-wilder':('classes','wilder'),'base_class-crusader':('classes','crusader'),'base_class-swordsage':('classes','swordsage'),'base_class-binder':('classes','binder'),'prestige-warshaper':('classes','warshaper'),'prestige-bonded-summoner':('classes','bonded-summoner'),'ancestry-centaur':('ancestries','heritage-centaur'),'ancestry-minotaur':('ancestries','heritage-minotaur'),'ancestry-changeling':('ancestries','heritage-changeling'),'ancestry-shifter':('ancestries','heritage-shifter')}
evidence=['tests/character_entities/mechanics_driver.gd','tests/character_entities/journey_driver.gd','docs/implementation/game112-wave-two/DELIVERY.md']
for row in coverage['entries']:
 if row['id']not in additions:continue
 category,id=additions[row['id']];definition=next(x for x in pack[category]if x['id']==id)
 row.update(status='playable'if a.validated else'implemented',playable=a.validated,evidence=evidence if a.validated else[],blocking_subsystems=['Native Windows/Linux validation pending']if not a.validated else['Human review of bounded original adaptation; further source-concept expansion'],next_action='Verify actual native gameplay, save/replay and original adaptation scope.'if not a.validated else'Extend the documented bounded adaptation without claiming a complete sourcebook conversion.')
 row['intended_implementation']={'kind':'distinct_class'if category=='classes'else'distinct_ancestry','production_id':id}
 row['implementation']={'pack_id':'trhgd-character-v12','level_cap':definition.get('max_level',0),'original_adaptation':True,'complete_sourcebook_conversion':False,'mechanics_test':'tests/character_entities/mechanics_driver.gd','tactical_test':'tests/character_entities/journey_driver.gd','art_status':'neutral_humanoid_fallback'if category=='ancestries'else'neutral_humanoid_lpc'}
 # Only the first canonical occurrence qualifies. Repeated setting/source variants remain independent.
 variant=row['source_variants'][0]
 variant.update(status=row['status'],playable=a.validated,production_id=id,evidence=evidence if a.validated else[],bounded_original_adaptation=True,complete_sourcebook_conversion=False)
coverage['wave_two']={'candidate_pack':'trhgd-character-v12','baseline_pack':'trhgd-character-v11','status':'native_validated'if a.validated else'implementation_under_validation','before':{'base_classes':19,'prestige_classes':8,'ancestry_families':17,'heritages':26,'feats':40,'skills':14,'career_choices':47},'after':{'base_classes':sum(x.get('class_kind')=='base'for x in pack['classes']),'prestige_classes':sum(x.get('class_kind')=='prestige'for x in pack['classes']),'ancestry_families':len({x['people_id']for x in pack['ancestries']}),'heritages':len(pack['ancestries']),'feats':len(pack['feats']),'skills':len(pack['skills']),'career_choices':sum(len(x.get('career_choices',[]))for x in pack['classes'])},'new_source_rows':list(additions),'all_occurrences_preserved':True,'complete_programme':False}
path.write_text(json.dumps(coverage,ensure_ascii=False,indent=2)+'\n')
print(json.dumps(coverage['wave_two']))
