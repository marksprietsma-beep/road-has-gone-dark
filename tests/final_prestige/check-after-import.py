"""Strict post-import source gate: generated UID sidecars are metadata, not code."""
from pathlib import Path
import hashlib,json,os,subprocess,tempfile
from source_scope import ROOT,BASE,script_inventory,verify_production
# Independent negative/positive inventory witnesses, never Godot execution.
checks=0
with tempfile.TemporaryDirectory(prefix='game169-inventory-')as folder:
 root=Path(folder);(root/'scripts').mkdir();script=root/'scripts/example.gd';script.write_text('extends Node\n',encoding='utf-8');expected=['scripts/example.gd']
 assert script_inventory(root,expected)==[];checks+=1
 uid=root/'scripts/example.gd.uid';uid.write_text('uid://cn6gu47t4g74c\n',encoding='utf-8');assert script_inventory(root,expected)==['scripts/example.gd.uid'];checks+=1
 for path,contents in [(root/'scripts/unrelated.gd','extends Node\n'),(root/'scripts/unknown.gd.uid','uid://known\n'),(uid,'not a Godot UID\n')]:
  original=path.read_bytes()if path.exists()else None;path.write_text(contents,encoding='utf-8')
  try:
   rejected=False
   try:script_inventory(root,expected)
   except AssertionError:rejected=True
   assert rejected,'Unexpected source/unknown UID/invalid metadata must be rejected';checks+=1
  finally:
   if original is None:path.unlink()
   else:path.write_bytes(original)
 script.unlink();rejected=False
 try:script_inventory(root,expected)
 except AssertionError:rejected=True
 assert rejected,'Missing original source must be rejected';checks+=1
scope=verify_production();checks+=1
expected=subprocess.check_output(['git','ls-tree','-r','--name-only',BASE,'scripts'],cwd=ROOT,text=True).splitlines();extra=script_inventory(ROOT,expected)
base=Path(os.environ['FINAL_PRESTIGE_ROOT']);base.mkdir(parents=True,exist_ok=True)
receipt=dict(checks=checks,failures=0,source_commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),source_guard=scope,generated_uid_sidecars=[dict(path=p,sha256=hashlib.sha256((ROOT/p).read_bytes()).hexdigest())for p in extra],scope='All tracked script/UID bytes and tracked inventory remain guarded. Only valid untracked UID metadata for existing scripts is accepted after Godot import. Missing or additional gameplay code, unknown UID owners and invalid UID syntax are rejected.')
(base/'source-after-import.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8');print(json.dumps(receipt,indent=2))
