"""Static immutable-content and bounded source guard; does not execute a game."""
from pathlib import Path
import hashlib,importlib.util,json,re,subprocess
ROOT=Path(__file__).resolve().parents[2]
BASE='c796043aa2543bcab144e8d0353628c35c2ab610'
UI_SHA='dbc34bc5956ff1a1e112e33c63a667b73aae21b8daf7f2f85ae2faec621dc357'
def original(path):return subprocess.check_output(['git','show',BASE+':'+path],cwd=ROOT)
def verify():
    manifest=json.loads((ROOT/'data/rules/packs.json').read_text(encoding='utf-8'))
    released=json.loads(original('data/rules/packs.json'))
    assert manifest['packs'][:28]==released['packs'] and len(manifest['packs'])>=29
    archived_source='a583939cb111778d350df137d0691839da39ee30'
    released29=json.loads(subprocess.check_output(['git','show',archived_source+':data/rules/packs.json'],cwd=ROOT))
    assert manifest['packs'][:29]==released29['packs']
    newer=len(manifest['packs'])>29
    if newer:
        # Keep every original29 data/source assertion against its exact released
        # source. Current30 source is independently and strictly scope-guarded;
        # real pinned29 runtime tests still execute on the current engine.
        assert len(manifest['packs']) in [30,31,32,33]
        spec=importlib.util.spec_from_file_location('current_martial_source',ROOT/'tests/martial_careers/check-source.py')
        current=importlib.util.module_from_spec(spec);spec.loader.exec_module(current);current.verify()
    for row in released['packs']:
        path=row['path'].removeprefix('res://');assert (ROOT/path).read_bytes()==original(path),path
    a=json.loads(original('data/rules/trhgd-character-v28.json'))
    b=json.loads((ROOT/'data/rules/trhgd-character-v29.json').read_text(encoding='utf-8'))
    assert {k for k in a if a[k]!=b[k]}=={'pack_id','rules_version','provenance','classes','abilities','features'}
    tables={}
    for category in ['classes','abilities','features']:
        old={r['id']:r for r in a[category]};new={r['id']:r for r in b[category]};tables[category]=(old,new)
        assert set(old)<=set(new)
    old,new=tables['classes'];assert set(old)==set(new)and {k for k in old if old[k]!=new[k]}=={'mystic-theurge','abjurant-champion'}
    assert new['mystic-theurge']['max_level']==10 and new['abjurant-champion']['max_level']==5
    for identity in ['mystic-theurge','abjurant-champion']:
        allowed={'requirements','career_choices','provenance'}|({'description','max_level','features'}if identity=='mystic-theurge'else set())
        assert {k for k in old[identity]if old[identity][k]!=new[identity][k]}==allowed
        for group in new[identity]['career_choices']:
            for option in group['options']:
                if 'advance_casting'not in option:continue
                assert option['progression_class']==identity and option['advance_casting']==option['id']
                cls=new[option['id']];assert cls['spell_mode']
                tradition='divine'if group['id'].endswith('-divine')else'arcane'
                assert cls['casting_tradition']==tradition
    old,new=tables['abilities'];changed={k for k in old if old[k]!=new[k]}
    expected={f'mystic-theurge-power-{n}'for n in [1,3,5]}|{f'abjurant-retaliation-{n}'for n in [1,3,5]}
    assert changed==expected
    for identity in changed:
        assert {k for k in old[identity]if old[identity][k]!=new[identity][k]}=={'tags','description','provenance'}
        assert new[identity]['tags']==old[identity]['tags']+['supernatural']
    added={f'mystic-theurge-power-{n}'for n in [7,9]}
    assert set(new)-set(old)==added
    for identity in added:
        assert new[identity]['cost']==dict(main=1,move=0,reaction=0,resources={'mystic-theurge-uses':1})
        assert new[identity]['targeting']==dict(kind='ally',range=0,radius=2)
        assert new[identity]['tags']==['supernatural']
    old,new=tables['features'];assert all(new[k]==old[k]for k in old)
    assert set(new)-set(old)=={i+'-feature'for i in added}
    for file in (ROOT/'scripts').rglob('*.gd'):
        path=file.relative_to(ROOT).as_posix()
        if path=='scripts/ui/first_adventure.gd':
            # Reviewed common cost/ownership/channel access and legal melee
            # targets; no change to command authority, budgets, logs or RNG.
            actual=subprocess.check_output(['git','show',archived_source+':'+path],cwd=ROOT) if newer else file.read_bytes()
            assert hashlib.sha256(actual).hexdigest()==UI_SHA
            continue
        before=original(path).decode('utf-8')
        expected=re.sub(r'"trhgd-character-v28"(\s*)\]',r'"trhgd-character-v28","trhgd-character-v29"\1]',before)
        expected=expected.replace('["trhgd-character-v28","28.0.0",3]]','["trhgd-character-v28","28.0.0",3],["trhgd-character-v29","29.0.0",3]]')
        expected=expected.replace('const NEW_PACK := "trhgd-character-v28"','const NEW_PACK := "trhgd-character-v29"')
        expected=expected.replace('pack_id=="trhgd-character-v28":context.casting_modifiers','pack_id in ["trhgd-character-v28","trhgd-character-v29"]:context.casting_modifiers')
        actual=subprocess.check_output(['git','show',archived_source+':'+path],cwd=ROOT).decode('utf-8') if newer else file.read_text(encoding='utf-8')
        assert actual==expected,path
    pin=next(row['rules_ref']for row in manifest['packs']if row['rules_ref']['pack_id']=='trhgd-character-v29')
    assert pin['pack_id']==b['pack_id']=='trhgd-character-v29'
    assert hashlib.sha256(json.dumps(b,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()==pin['content_hash']
    return dict(baseline=BASE,historical_pack_bytes_and_pins=28,rules_ref=pin,roster_unchanged=True,new_class_support_actions=2,typed_existing_actions=6,source_changes='Existing version enablement and reviewed shared action-availability presentation; original combat/RNG/save authorities unchanged',source_audit_scope='Exact released29 source plus separately verified current30 source; pinned29 runtime tests still execute on the current engine' if newer else 'Current29 source')
if __name__=='__main__':print(json.dumps(verify(),indent=2))
