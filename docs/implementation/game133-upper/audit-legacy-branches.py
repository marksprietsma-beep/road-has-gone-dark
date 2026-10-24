"""Static source projection, not game execution or a substitute rules engine."""
from pathlib import Path
import hashlib
import json
import subprocess

ROOT = Path(__file__).resolve().parents[3]
BASE = '3e62d5cfc4959269f607ee7f64008842882f1c48'


def verify():
    paths = subprocess.check_output(['git','ls-tree','-r','--name-only',BASE,'--','scripts'],cwd=ROOT,text=True).splitlines()
    changed = {}
    for path in paths:
        old = subprocess.check_output(['git','show',BASE+':'+path],cwd=ROOT)
        current = (ROOT/path).read_bytes()
        if old==current:
            continue
        text = current.decode()
        # These list additions only enable the new27 pin; membership of1–26 is identical.
        text = text.replace(',"trhgd-character-v27"','')
        text = text.replace(',["trhgd-character-v27","27.0.0",3]','')
        if path.endswith('/rules_records.gd'):
            text = text.replace('const NEW_PACK := "trhgd-character-v27"','const NEW_PACK := "trhgd-character-v26"')
        if path.endswith('/tactical_auras.gd'):
            text = text.replace(' if registry.rules_ref().pack_id=="trhgd-character-v27" and _intercept_weapon(b,a,t):return\n','')
            start = text.index('\nfunc _intercept_weapon(')
            end = text.index('\nfunc _martial_event(',start)
            text = text[:start]+text[end:]
        if path.endswith('/rules_character.gd'):
            text = text.replace('  if registry.rules_ref().pack_id=="trhgd-character-v27" and not context.abilities.has("revert-form"):context.abilities.append("revert-form")\n','')
        if path.endswith('/first_adventure.gd'):
            block = '''   if engine.registry.rules_ref().pack_id=="trhgd-character-v27":
    var shells: int=actor.record.runtime.statuses.filter(func(s: Dictionary):return engine.registry.definition("statuses",s.id).tags.has("weapon_decoy")).size()
    if shells>0:detail.text+="\\nRefraction: %d/3 weapon attempts · true sight/spells bypass"%shells
'''
            assert block in text
            text = text.replace(block,'')
        assert text.encode()==old, 'Unexpected change to a historical execution branch: '+path
        changed[path] = dict(original_sha256=hashlib.sha256(old).hexdigest(),current_sha256=hashlib.sha256(current).hexdigest(),projected_legacy_sha256=hashlib.sha256(text.encode()).hexdigest())
    return dict(baseline=BASE,source_commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),
        historical_pins='v1–v26',historical_execution_branches_project_exactly=True,changed_scripts=changed,
        exclusions='Only27 membership/registration, the new-campaign default,27-only interception/reversion/status feedback. Factory default intentionally changes for new unpinned campaigns; this is not a claim that all runtime inputs are identical.',
        scope='Static byte projection for unchanged pinned branches. Fresh Windows historical/native/oracle checks are independent evidence, not replaced by this audit.')


if __name__=='__main__':
    print(json.dumps(verify(),indent=2))
