#!/usr/bin/env python3
"""Reproducible native evaluation setup; clones/builds stay outside project.
Node24, verified Go1.24.5 and optional .NET8 prerequisites documented in README.
No production dependency install; no external prose copied into TRHGD packs."""
import argparse,pathlib,subprocess,sys,shutil,os,json
sys.stdout.reconfigure(encoding='utf-8');repo=pathlib.Path(__file__).resolve().parents[3];os.chdir(repo)
p=argparse.ArgumentParser();p.add_argument('--root',default='/tmp/game78-sources');p.add_argument('--built',default='/tmp/game78-native');p.add_argument('--go',default='/tmp/game78-toolchains/go/bin/go');p.add_argument('--dotnet',default='/tmp/game78-toolchains/dotnet/dotnet');p.add_argument('--secondary',action='store_true');a=p.parse_args();root=pathlib.Path(a.root).resolve();root.mkdir(parents=True,exist_ok=True)
pins={'lexiconlang':('ianlintner/lexiconlang','da0a823e275d9642731bdaed1f3006d2c9bfae74'),'Rantjs':('robbestad/Rantjs','c62d5b21b9da9be561c15afdccd5f352cdb91e64'),'fantasy-content-generator':('thomascgray/fantasy-content-generator','323aca8d0e946420cae59a315fbb2a9ba7958ec8'),'venture':('opd-ai/venture','3e308230f7ca387a23e774c346baa7db5c4f78e6'),'npc-generator':('FyefoxxM/npc-generator','b2a16ceb7f12a4467fe91444d488ff9199c64434'),'corpora':('dariusk/corpora','2e7adec11a0561696c236ae1fca82e88be173d42'),'Loremaker':('kesac/Loremaker','fe18b6e95bfffe9adfb149c3388d1a61e6860753'),'Questify':('TheWalruzz/godot-questify','a102ab1bd4f0ee4280d5370d9aab2b49f8843325'),'Eigengrau':('ryceg/Eigengrau-s-Essential-Establishment-Generator','c8f5e0d563779a996df860c6b4bbed42a9974621')}
logs=repo/'research/game78/evidence/builds';logs.mkdir(exist_ok=True,parents=True)
def run(name,cmd,cwd=None):
 r=subprocess.run([str(x) for x in cmd],cwd=cwd,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,encoding='utf-8',timeout=600);(logs/(name+'.txt')).write_text(r.stdout,encoding='utf-8');print(name,r.returncode,flush=True)
 if r.returncode:raise RuntimeError(name+' failed; see '+str(logs/(name+'.txt')))
 return r.stdout
for name,(remote,commit) in pins.items():
 folder=root/name
 if not folder.exists():run('clone-'+name,['git','clone','--filter=blob:none','https://github.com/'+remote+'.git',folder])
 dirty=subprocess.check_output(['git','-C',str(folder),'status','--porcelain'],text=True)
 if dirty:raise RuntimeError('Preserve existing dirty vendor checkout: '+str(folder))
 run('pin-'+name,['git','-C',folder,'checkout','--detach',commit])
 assert subprocess.check_output(['git','-C',str(folder),'rev-parse','HEAD'],text=True).strip()==commit
build=pathlib.Path('/tmp/game78-build');build.mkdir(exist_ok=True)
for name in ['package.json','package-lock.json']:shutil.copy2(repo/'research/game78/tools/build-tools'/name,build/name)
run('native-build-tools',['npm','ci','--prefix',build,'--ignore-scripts','--no-audit','--no-fund'])
run('js-compile',['node','research/game78/tools/build-native.mjs',root,a.built])
run('js-native',['node','research/game78/tools/native-js.mjs',a.built,'research/game78/evidence/native'])
run('rant-native',['node','research/game78/tools/rant-capabilities.mjs'])
minimal=pathlib.Path('/tmp/game78-venture-replay');run('venture-extract',['python3','research/game78/tools/extract-venture.py',root/'venture',minimal]);h=minimal/'cmd/evaluate';h.mkdir(parents=True,exist_ok=True);shutil.copy2(repo/'research/game78/tools/venture/main.go',h/'main.go')
for name in ['go.mod','go.sum']:shutil.copy2(repo/'research/game78/tools/venture'/name,minimal/name)
for module in ['entity','item','quest','narrative','faction','magic','dialog']:
 for f in (root/'venture/pkg/procgen'/module).glob('*_test.go'):shutil.copy2(f,minimal/'pkg/procgen'/module/f.name)
run('venture-build',[a.go,'build','-buildvcs=false','-mod=readonly','-o','/tmp/game78-venture-replay.bin','./cmd/evaluate'],minimal)
result=run('venture-native',['/tmp/game78-venture-replay.bin'],minimal);(repo/'research/game78/evidence/native/venture.json').write_text(result,encoding='utf-8')
run('venture-tests',[a.go,'test','-count=1','./pkg/procgen/entity','./pkg/procgen/item','./pkg/procgen/quest','./pkg/procgen/narrative','./pkg/procgen/faction','./pkg/procgen/magic','./pkg/procgen/dialog'],minimal)
# Secondary NPC native module import occurs in the source root, never vendored.
code="import sys,json;sys.path.insert(0,sys.argv[1]);from npcgen import NPCGenerator;g=NPCGenerator();rows=[]\nfor i in range(200):\n a=g.generate(seed=78000+i,include_secret=True,include_hook=True).to_dict();assert a==g.generate(seed=78000+i,include_secret=True,include_hook=True).to_dict();rows.append({'index':i,'output':a})\njson.dump(rows,open(sys.argv[2],'w'),indent=2)"
run('python-npc-native',['python3','-c',code,root/'npc-generator',repo/'research/game78/evidence/native/python-npcs.json'])
if a.secondary:
 data=root/'Loremaker/Loremaker/Loremaker/Data';target=data/'colors.json'
 if not target.exists():shutil.copy2(data/'Colors.json',target)
 run('loremaker-build',[a.dotnet,'build',root/'Loremaker/Loremaker/Loremaker/Loremaker.csproj','-c','Release'])
 harness=pathlib.Path('/tmp/game78-loremaker-replay');harness.mkdir(exist_ok=True);shutil.copy2(repo/'research/game78/tools/loremaker-harness.cs',harness/'Program.cs')
 import html
 (harness/'harness.csproj').write_text('<Project Sdk="Microsoft.NET.Sdk"><PropertyGroup><OutputType>Exe</OutputType><TargetFramework>net8.0</TargetFramework></PropertyGroup><ItemGroup><ProjectReference Include="'+html.escape(str(root/'Loremaker/Loremaker/Loremaker/Loremaker.csproj'))+'" /></ItemGroup></Project>')
 run('loremaker-harness-build',[a.dotnet,'build',harness/'harness.csproj','-c','Release'])
 result=run('loremaker-native',[a.dotnet,harness/'bin/Release/net8.0/harness.dll']);(repo/'research/game78/evidence/native/loremaker-context.json').write_text(result,encoding='utf-8')
 run('questify-import',['godot','--headless','--path',root/'Questify','--editor','--import','--quit']);run('questify-launch',['godot','--headless','--path',root/'Questify','--quit-after','30'])
print('PASS: native provider setup and execution; no production dependency change')
