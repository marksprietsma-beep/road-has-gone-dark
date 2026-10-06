"""Build and exercise one complete native distribution, then archive it for review."""
import hashlib, json, os, pathlib, platform, subprocess, tarfile, zipfile

root = pathlib.Path(__file__).resolve().parents[2]
os.chdir(root)
base = pathlib.Path(os.environ['GAME80_RELEASE_ROOT']).resolve()
base.mkdir(parents=True, exist_ok=True)
name = 'game80-' + ('windows' if os.name == 'nt' else 'linux') + '-x64'
distribution = base/name
subprocess.run(['node', 'tools/release/export-game.mjs', '--helper', os.environ['GAME76_HELPER_ROOT'],
                '--godot', os.environ.get('GODOT_BIN', 'godot'), '--qa', '--output', str(distribution)], check=True)
environment = os.environ.copy()
environment.pop('GAME76_HELPER_ROOT', None)
environment.update(PATH='', NODE_PATH='', NODE_OPTIONS='', GAME80_DISTRIBUTION_TEST_ROOT=str(base/'native-test'))
executable = distribution/('road-has-gone-dark-qa.exe' if os.name == 'nt' else 'road-has-gone-dark-qa')
log = root/'docs/implementation/game80/logs/native-distribution.txt'
with log.open('w', encoding='utf-8') as handle:
    result = subprocess.run([str(executable), '--headless', '--audio-driver', 'Dummy',
                             'res://tests/origin_profiles/verify-distribution.tscn'],
                            cwd=distribution, env=environment, stdout=handle, stderr=subprocess.STDOUT, timeout=300)
text = log.read_text(encoding='utf-8')
print(text, end='', flush=True)
assert result.returncode == 0 and 'ERROR:' not in text and '0 failures' in text
release = distribution/('road-has-gone-dark.exe' if os.name == 'nt' else 'road-has-gone-dark')
smoke = subprocess.run([str(release), '--headless', '--audio-driver', 'Dummy', '--quit-after', '10'],
                       cwd=distribution, env=environment, capture_output=True, text=True, timeout=60)
assert smoke.returncode == 0 and 'ERROR:' not in smoke.stdout + smoke.stderr
for path in distribution.glob('road-has-gone-dark-qa*'): path.unlink()
if os.name == 'nt':
    archive = base/(name+'.zip')
    with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as package:
        for path in distribution.rglob('*'):
            if path.is_file(): package.write(path, pathlib.Path(name)/path.relative_to(distribution))
else:
    archive = base/(name+'.tar.gz')
    with tarfile.open(archive, 'w:gz') as package: package.add(distribution, arcname=name)
digest = hashlib.file_digest(archive.open('rb'), 'sha256').hexdigest()
(base/(archive.name+'.sha256')).write_text(digest+'  '+archive.name+'\n', encoding='utf-8')
proof = {'platform':platform.system(), 'native_export_test':'debug export full lifecycle; release export launch passed', 'source_helper_override':False,
         'path_empty':True, 'archive':archive.name, 'archive_sha256':digest,
         'distribution':json.loads((distribution/'distribution.json').read_text())}
(root/'docs/implementation/game80/distribution-proof.json').write_text(json.dumps(proof, indent=2)+'\n')
print('Verified complete game + helper:', archive, flush=True)
