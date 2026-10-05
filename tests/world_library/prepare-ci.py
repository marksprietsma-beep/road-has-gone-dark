"""Verified platform tools and review archive. These are build dependencies only."""
import hashlib, os, pathlib, platform, shutil, subprocess, tarfile, urllib.request, zipfile

work = pathlib.Path(os.environ['RUNNER_TEMP'])
windows = platform.system() == 'Windows'
suffix = 'win64.exe' if windows else 'linux.x86_64'
archive = work / 'godot.zip'
urllib.request.urlretrieve('https://github.com/godotengine/godot-builds/releases/download/4.6.3-stable/Godot_v4.6.3-stable_' + suffix + '.zip', archive)
expected = 'e39986a178d585ce7ac198fb8de6ea436366dc0cc00e594810c2e3e104c04b90' if windows else 'd0bc2113065e481c9c2c2b2c37daa4e8be3fe9e27f0ab9ab0b6096e9a37907f3'
assert hashlib.sha256(archive.read_bytes()).hexdigest() == expected
with zipfile.ZipFile(archive) as z:
    z.extractall(work / 'godot')
engine = work / 'godot' / ('Godot_v4.6.3-stable_win64_console.exe' if windows else 'Godot_v4.6.3-stable_linux.x86_64')
engine.chmod(0o755)
license_path = work / 'NODE-LICENSE'
urllib.request.urlretrieve('https://raw.githubusercontent.com/nodejs/node/v24.19.0/LICENSE', license_path)
assert hashlib.sha256(license_path.read_bytes()).hexdigest() == '148eacf7863ef4329224a29398623077200a27194aa075569faf4a0a85566ca5'
helper = work / 'worldgen-helper'
subprocess.run([shutil.which('node'), 'tools/worldgen/package-helper.mjs', '--output', str(helper), '--runtime-license', str(license_path)], check=True)
name = 'game76-helper-' + ('windows' if windows else 'linux') + '-x64'
release = work / 'review-packages'
release.mkdir()
if windows:
    package = release / (name + '.zip')
    with zipfile.ZipFile(package, 'w', zipfile.ZIP_DEFLATED) as z:
        for path in helper.rglob('*'):
            if path.is_file(): z.write(path, pathlib.Path('worldgen-helper') / path.relative_to(helper))
else:
    package = release / (name + '.tar.gz')
    with tarfile.open(package, 'w:gz') as tar: tar.add(helper, arcname='worldgen-helper')
(release / (name + '.sha256')).write_text(hashlib.sha256(package.read_bytes()).hexdigest() + '  ' + package.name + '\n')
with open(os.environ['GITHUB_ENV'], 'a') as env:
    for key, value in [('GODOT_BIN', engine), ('GAME76_HELPER_ROOT', helper), ('GAME76_GENERATED_TEST_DIR', work / 'generated worlds with spaces')]:
        env.write(str(key) + '=' + str(value) + '\n')
