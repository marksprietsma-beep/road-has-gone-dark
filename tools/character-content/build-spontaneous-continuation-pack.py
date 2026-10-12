"""Preserve pushed v5 and add room for the Sorcerer's new tier at class eight."""
import hashlib
import json
from pathlib import Path

root = Path(__file__).resolve().parents[2]
pack = json.loads((root/'data/rules/trhgd-character-v5.json').read_text())
pack.update(pack_id='trhgd-character-v6', rules_version='6.0.0')
next(row for row in pack['classes'] if row['id'] == 'sorcerer')['known_spell_limits'] = [0, 2, 2, 3, 3, 4, 4, 5, 6]
path = root/'data/rules/trhgd-character-v6.json'
path.write_text(json.dumps(pack, ensure_ascii=False, indent=2)+'\n')
manifest_path = root/'data/rules/packs.json'
manifest = json.loads(manifest_path.read_text())
manifest['packs'] = [row for row in manifest['packs'] if row['rules_ref']['pack_id'] != pack['pack_id']]
pin = {key: pack[key] for key in ['pack_id', 'schema_version', 'rules_version', 'engine_schema']}
pin['content_hash'] = hashlib.sha256(json.dumps(pack, ensure_ascii=False, sort_keys=True, separators=(',', ':')).encode()).hexdigest()
manifest['packs'].append(dict(path='res://data/rules/trhgd-character-v6.json', rules_ref=pin))
manifest_path.write_text(json.dumps(manifest, indent=2)+'\n')
