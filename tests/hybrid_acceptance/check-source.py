"""Static byte/data guard only; no game execution on the non-Windows host."""
from pathlib import Path
import hashlib,json,subprocess
root=Path(__file__).resolve().parents[2];base='c48d6df3e08fe17d8893294aab029e02a7be20e9'
def verify():
 manifest=json.loads((root/'data/rules/packs.json').read_text());old=json.loads(subprocess.check_output(['git','show',base+':data/rules/packs.json'],cwd=root));assert manifest['packs'][:27]==old['packs'] and len(manifest['packs'])==28
 for row in old['packs']:
  file=row['path'].removeprefix('res://');assert (root/file).read_bytes()==subprocess.check_output(['git','show',base+':'+file],cwd=root)
 before=json.loads((root/'data/rules/trhgd-character-v27.json').read_text());after=json.loads((root/'data/rules/trhgd-character-v28.json').read_text());assert set(before)==set(after)
 assert {k for k in before if before[k]!=after[k]}=={'pack_id','rules_version','provenance','abilities'}
 a={r['id']:r for r in before['abilities']};b={r['id']:r for r in after['abilities']};assert set(a)==set(b)
 changed={k for k in a if a[k]!=b[k]};expected={'high-arcana-'+kind+'-'+str(level)for kind in ['force','ward']for level in [1,3,5]};assert changed==expected
 for key in changed:
  original=a[key];candidate=b[key];assert {k for k in original if original[k]!=candidate[k]}==({'tags','description','provenance','effects'}if '-force-'in key else {'tags','description','provenance'})
  assert candidate['tags']==original['tags']+['supernatural']
  if '-force-'in key:
   expected_effects=json.loads(json.dumps(original['effects']));expected_effects[0]['dc']['args'][1]={'op':'casting_modifier','id':'archmage'};assert candidate['effects']==expected_effects
 pin=manifest['packs'][-1]['rules_ref'];assert pin['content_hash']==hashlib.sha256(json.dumps(after,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()
 frozen=['scripts/combat/tactical_combat.gd','scripts/rules/rules_rng.gd','scripts/game_world/game_playthrough_store.gd']
 for file in frozen:
  assert (root/file).is_file()
  assert subprocess.check_output(['git','diff',base,'--',file],cwd=root)==b''
 return {'baseline':base,'historical_pack_bytes_and_pins':27,'rules_ref':pin,'changed_existing_abilities':sorted(changed),'new_roster_spell_feat_creature_equipment_definitions':0,'frozen_authorities_unchanged':frozen}
if __name__=='__main__':print(json.dumps(verify(),indent=2))
