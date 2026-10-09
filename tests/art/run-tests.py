#!/usr/bin/env python3
"""Original art integrity and actual Godot provider/persistence tests."""
import argparse,hashlib,json,os,pathlib,subprocess,shutil
root=pathlib.Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('--godot',default=os.environ.get('GODOT_BIN',shutil.which('godot')));p.add_argument('--output',required=True,type=pathlib.Path);args=p.parse_args();args.output.mkdir(parents=True,exist_ok=True)
manifest=json.loads((root/'data/art/sources.json').read_text())
for row in manifest['files']:
 assert hashlib.sha256((root/row['path']).read_bytes()).hexdigest()==row['sha256'],row['path']
 assert row['provider'] in ['lpc','kenney','0x72','navinius'] and row['source_url'].startswith('https://')
 if row['provider']=='lpc':assert row['attribution']
print('Verified original source hashes:',len(manifest['files']),flush=True)
env=dict(os.environ,GAME93_PROOF=str(args.output/'providers.json'),GAME93_PREF=str(args.output/'presentation.cfg'))
for name,script,phase in [('providers','providers.gd',''),('preference-write','preference.gd','write'),('preference-restart','preference.gd','read')]:
 result=subprocess.run([args.godot,'--headless','--audio-driver','Dummy','--path',str(root),'--script',str(root/'tests/art'/script)],env=dict(env,GAME93_PHASE=phase),capture_output=True,text=True,encoding='utf-8',timeout=180)
 (args.output/(name+'.log')).write_text(result.stdout+result.stderr,encoding='utf-8')
 assert result.returncode==0 and 'ERROR:' not in result.stdout+result.stderr,name
proof=json.loads((args.output/'providers.json').read_text());assert proof['failures']==0
print('Godot provider assertions:',proof['checks'],'; fresh-process preference verified',flush=True)
