"""Released34 diagnostic phase: production and accepted readiness remain exact."""
from pathlib import Path
import subprocess,json
ROOT=Path(__file__).resolve().parents[2];BASE='7c70fb27bfd3572505421c996102bd11e9b6da1a'
def original(path):return subprocess.check_output(['git','show',BASE+':'+path],cwd=ROOT)
def verify():
 assert subprocess.check_output(['git','diff',BASE,'--','scripts','data','scenes','assets','tools','vendor','project.godot','export_presets.cfg'],cwd=ROOT)==b'','No production edits before released34 reproduction'
 path='docs/implementation/game129/READINESS.json';assert (ROOT/path).read_bytes()==original(path)
 rows=json.loads((ROOT/path).read_text(encoding='utf-8'))['classes'];assert len(rows)==50 and sum(x['status']=='COMPLETE'for x in rows)==47
 return dict(baseline=BASE,production_unchanged=True,readiness_unchanged=True,immutable_packs=34)
if __name__=='__main__':print(json.dumps(verify()))
