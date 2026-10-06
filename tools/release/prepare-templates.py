#!/usr/bin/env python3
"""Build-only official Godot export templates; verified before extraction."""
import hashlib, os, pathlib, urllib.request, zipfile
cache = pathlib.Path(os.environ.get('GAME80_TEMPLATE_CACHE', '.local/export-templates-4.6.3.tpz')).resolve()
if os.name == 'nt':
    dest = pathlib.Path(os.environ['APPDATA'])/'Godot/export_templates/4.6.3.stable'
else:
    data = pathlib.Path(os.environ.get('XDG_DATA_HOME', pathlib.Path.home()/'.local/share'))
    dest = data/'godot/export_templates/4.6.3.stable'
required = ['linux_release.x86_64','linux_debug.x86_64','windows_release_x86_64.exe','windows_debug_x86_64.exe']
expected = '3fbe2c0e2dec9d537ab9ec97bcf8da91dcf23357fc51f67092dd068d839290a8'
cache.parent.mkdir(parents=True, exist_ok=True)
if not cache.exists():
    partial = cache.with_suffix('.partial')
    urllib.request.urlretrieve('https://github.com/godotengine/godot-builds/releases/download/4.6.3-stable/Godot_v4.6.3-stable_export_templates.tpz', partial)
    if hashlib.file_digest(partial.open('rb'), 'sha256').hexdigest() != expected: raise RuntimeError('Official Godot template checksum mismatch')
    partial.rename(cache)
if hashlib.file_digest(cache.open('rb'), 'sha256').hexdigest() != expected: raise RuntimeError('Cached template integrity failure')
dest.mkdir(parents=True, exist_ok=True)
with zipfile.ZipFile(cache) as archive:
    for name in required:
        (dest/name).write_bytes(archive.read('templates/'+name))
        if not name.endswith('.exe'): (dest/name).chmod(0o755)
print('Verified Godot 4.6.3 native templates:', dest, flush=True)
