"""Execute the Godot rules kernel, frozen deterministic oracle, real migration and restart."""
import hashlib,json,os,pathlib,subprocess,tempfile,time
root=pathlib.Path(__file__).resolve().parents[2]
os.chdir(root)
env=os.environ.copy()
engine=env.get('GODOT_BIN','godot')
evidence=pathlib.Path(env.get('GAME32_EVIDENCE',root/'docs/implementation/game32')).resolve()
evidence.mkdir(parents=True,exist_ok=True)
env['GAME32_EVIDENCE']=str(evidence)
with tempfile.TemporaryDirectory(prefix='game32-rules-') as work:
    env['GAME32_TEST_ROOT']=work
    measures={}
    def run(name,args,extra=None):
        start=time.perf_counter()
        result=subprocess.run([engine,*args],env=dict(env,**(extra or {})),cwd=root,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,encoding='utf-8',timeout=600)
        (evidence/(name+'.log')).write_text(result.stdout,encoding='utf-8')
        print(result.stdout,flush=True)
        if result.returncode or 'ERROR:' in result.stdout: raise SystemExit(name+' failed')
        measures[name]=round(time.perf_counter()-start,6)
    frozen={str(p):hashlib.sha256(p.read_bytes()).hexdigest() for p in (root/'data/world_enrichment').rglob('*.json')}
    run('import',['--headless','--editor','--audio-driver','Dummy','--path','.', '--quit'])
    args=['--headless','--audio-driver','Dummy','--path','.','--script']
    run('kernel',args+['res://tests/rules/kernel.gd'])
    result=json.loads((evidence/'kernel-results.json').read_text())
    golden=json.loads((root/'tests/rules/golden.json').read_text())
    assert result['golden']==golden['golden'],'Cross-platform deterministic values/codes/RNG/snapshot hashes changed'
    assert result['rules_ref']==golden['rules_ref'],'Pinned content changed without reviewed golden update'
    run('migration-create',args+['res://tests/rules/migration.gd'],{'GAME32_PHASE':'create'})
    run('migration-reload',args+['res://tests/rules/migration.gd'],{'GAME32_PHASE':'reload'})
    assert frozen=={str(p):hashlib.sha256(p.read_bytes()).hexdigest() for p in (root/'data/world_enrichment').rglob('*.json')}
    (evidence/'run-timings.json').write_text(json.dumps({'platform':os.name,'seconds':measures},indent=2)+'\n')
print('PASS GAME-32 content, progression, stress, deterministic oracle, existing active-expedition migration and restart',flush=True)
