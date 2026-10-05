"""Faithful evaluation extraction. Generator code remains byte-identical;
only the engine's Faction data declarations are isolated from its graphics ECS."""
from pathlib import Path
import subprocess,shutil,json,hashlib,sys
src=Path(sys.argv[1]);out=Path(sys.argv[2]);pin='3e308230f7ca387a23e774c346baa7db5c4f78e6'
assert subprocess.check_output(['git','-C',str(src),'rev-parse','HEAD'],text=True).strip()==pin
files=[]
def copy(p):
 t=out/p.relative_to(src);t.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,t);files.append({'path':str(p.relative_to(src)),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'modified':False})
copy(src/'LICENSE')
for p in (src/'pkg/procgen').glob('*.go'):
 if not p.name.endswith('_test.go'):copy(p)
for name in ['entity','item','quest','narrative','faction','magic','dialog']:
 for p in (src/'pkg/procgen'/name).glob('*.go'):
  if not p.name.endswith('_test.go'):copy(p)
p=src/'pkg/engine/faction_component.go';s=p.read_text();s='package engine\n\n'+s[s.index('type Faction struct'):s.index('// ReputationChange')];t=out/'pkg/engine/faction_data.go';t.parent.mkdir(parents=True,exist_ok=True);t.write_text(s);files.append({'path':str(p.relative_to(src)),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'modified':'extract Faction, FactionType and methods; no generator changes'})
(out/'go.mod').write_text('module github.com/opd-ai/venture\n\ngo 1.24.5\n\nrequire github.com/sirupsen/logrus v1.9.3\n')
(out/'extraction.json').write_text(json.dumps({'pin':pin,'files':files},indent=2))
