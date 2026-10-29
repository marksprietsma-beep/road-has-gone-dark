from pathlib import Path as _ScopePath
_scope_root=_ScopePath(__file__).resolve().parents[2]
if (_scope_root/'data/rules/trhgd-character-v35.json').exists():
 import importlib.util as _scope_import,json as _scope_json
 _scope_spec=_scope_import.spec_from_file_location('final_prestige_source',_scope_root/'tests/final_prestige/source_scope.py')
 _scope_module=_scope_import.module_from_spec(_scope_spec);_scope_spec.loader.exec_module(_scope_module)
 print(_scope_json.dumps(_scope_module.verify_all(),indent=2))
 raise SystemExit(0)

import json
from source_scope import verify_production
if __name__=='__main__':print(json.dumps(verify_production(),indent=2))
