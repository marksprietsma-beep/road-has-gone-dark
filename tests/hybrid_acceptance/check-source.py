"""Static byte/data guard only; no game execution on the non-Windows host."""
from pathlib import Path
import hashlib,json,subprocess
root=Path(__file__).resolve().parents[2];base='c48d6df3e08fe17d8893294aab029e02a7be20e9'
def verify():
 manifest=json.loads((root/'data/rules/packs.json').read_text(encoding='utf-8'));old=json.loads(subprocess.check_output(['git','show',base+':data/rules/packs.json'],cwd=root));assert manifest['packs'][:27]==old['packs'] and len(manifest['packs'])>=28
 released=json.loads(subprocess.check_output(['git','show','c796043:data/rules/packs.json'],cwd=root))
 assert manifest['packs'][:28]==released['packs']
 assert (root/'data/rules/trhgd-character-v28.json').read_bytes()==subprocess.check_output(['git','show','c796043:data/rules/trhgd-character-v28.json'],cwd=root)
 assert len({r['rules_ref']['pack_id']for r in manifest['packs']})==len(manifest['packs'])
 for appended in manifest['packs'][28:]:
  data=json.loads((root/appended['path'].removeprefix('res://')).read_text(encoding='utf-8'))
  assert data['pack_id']==appended['rules_ref']['pack_id']
  assert hashlib.sha256(json.dumps(data,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()==appended['rules_ref']['content_hash']
 for row in old['packs']:
  file=row['path'].removeprefix('res://');assert (root/file).read_bytes()==subprocess.check_output(['git','show',base+':'+file],cwd=root)
 before=json.loads((root/'data/rules/trhgd-character-v27.json').read_text(encoding='utf-8'));after=json.loads((root/'data/rules/trhgd-character-v28.json').read_text(encoding='utf-8'));assert set(before)==set(after)
 assert {k for k in before if before[k]!=after[k]}=={'pack_id','rules_version','provenance','abilities','classes'}
 old_classes={row['id']:row for row in before['classes']};new_classes={row['id']:row for row in after['classes']};assert set(old_classes)==set(new_classes)
 assert {key for key in old_classes if old_classes[key]!=new_classes[key]}=={'archmage'}
 restored=json.loads(json.dumps(new_classes['archmage']))
 for original_group,candidate_group in zip(old_classes['archmage']['career_choices'],restored['career_choices'],strict=True):
  for original_option,candidate_option in zip(original_group['options'],candidate_group['options'],strict=True):
   if original_group['id'].startswith('high-arcana-'):candidate_option['description']=original_option['description']
 assert restored==old_classes['archmage'], 'Only explanatory career-option descriptions may change'
 a={r['id']:r for r in before['abilities']};b={r['id']:r for r in after['abilities']};assert set(a)==set(b)
 changed={k for k in a if a[k]!=b[k]};expected={'high-arcana-'+kind+'-'+str(level)for kind in ['force','ward']for level in [1,3,5]};assert changed==expected
 for key in changed:
  original=a[key];candidate=b[key];allowed={'tags','description','provenance'}
  if '-force-'in key:allowed.add('effects')
  if key in ['high-arcana-ward-3','high-arcana-ward-5']:allowed.update(['effects','name'])
  assert {k for k in original if original[k]!=candidate[k]}==allowed
  assert candidate['tags']==original['tags']+['supernatural']
  expected_effects=json.loads(json.dumps(original['effects']))
  if '-force-'in key:expected_effects[0]['dc']['args'][1]={'op':'casting_modifier','id':'archmage'}
  elif key in ['high-arcana-ward-3','high-arcana-ward-5']:
   statuses=['weakened','arcane-tether']+(['slowed','unsteady-concentration','stillness-lattice']if key.endswith('-5')else[])
   expected_effects=[{'op':'remove_status','id':sid}for sid in statuses]+expected_effects
  assert candidate['effects']==expected_effects
 pin=next(r['rules_ref']for r in manifest['packs']if r['rules_ref']['pack_id']=='trhgd-character-v28');actual=hashlib.sha256(json.dumps(after,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode('utf-8')).hexdigest();assert pin['content_hash']==actual, {'expected':pin['content_hash'],'actual':actual,'decoder':'utf-8'}
 frozen=['scripts/combat/tactical_combat.gd','scripts/rules/rules_rng.gd','scripts/game_world/game_playthrough_store.gd']
 for file in frozen:
  assert (root/file).is_file()
  assert subprocess.check_output(['git','diff',base,'--',file],cwd=root)==b''
 return {'baseline':base,'historical_pack_bytes_and_pins':27,'rules_ref':pin,'changed_existing_abilities':sorted(changed),'new_roster_spell_feat_creature_equipment_definitions':0,'frozen_authorities_unchanged':frozen}
if __name__=='__main__':print(json.dumps(verify(),indent=2))
