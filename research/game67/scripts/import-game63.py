#!/usr/bin/env python3
"""Verify the original volumes and derive fixtures, without regenerating towns.
Requires py7zr==1.1.3. Run from repository root.
"""
import hashlib,json,subprocess,tempfile
from pathlib import Path
import py7zr
root=Path(__file__).resolve().parents[3]
dest=root/'research/game67'
sha=lambda b:hashlib.sha256(b).hexdigest()
manifest=json.loads((dest/'fixtures/provenance.json').read_text())
with tempfile.TemporaryDirectory(prefix='game63-original-') as tmp:
    tmp=Path(tmp);combined=tmp/'proof.7z';parts=[]
    for n in range(1,5):
        name=f'game63-proof.7z.{n:03}'
        b=(root/name).read_bytes()
        holding=subprocess.check_output(['git','show',f'a07775937272148858370bb2cb263182484c6a2f:handoffs/GAME-63/{name}'],cwd=root)
        if b!=holding:raise ValueError('Holding branch byte mismatch: '+name)
        parts.append(b)
    combined.write_bytes(b''.join(parts))
    if sha(combined.read_bytes())!=manifest['archiveSha256']:raise ValueError('Reconstructed archive checksum mismatch')
    with py7zr.SevenZipFile(combined) as archive:
        if archive.testzip() is not None:raise ValueError('Archive CRC failure')
    with py7zr.SevenZipFile(combined) as archive:archive.extractall(tmp/'original')
    src=tmp/'original'
    checks=(src/'evidence/SHA256SUMS.txt').read_text().splitlines()
    for line in checks:
        expected,rel=line.split('  ',1)
        if sha((src/rel).read_bytes())!=expected:raise ValueError('Internal checksum mismatch: '+rel)
    for stem,slug in [('village','batan'),('fortified-town','albanes'),('coastal-port','thilranlena')]:
        record=next(x for x in manifest['fixtures'] if x['slug']==slug)
        for rel,expected in record['originalFiles'].items():
            if sha((src/rel).read_bytes())!=expected:raise ValueError('Original source checksum mismatch: '+rel)
        g=json.loads((src/f'outputs/{stem}.geojson').read_text());r=json.loads((src/f'inputs/{stem}.request.json').read_text())
        backdrop={'fields':[],'water':[]}
        if stem!='village':
            scene=json.loads((src/f'outputs/{stem}.scene.json').read_text())
            backdrop={'fields':[[[p['x'],p['y']] for p in f['ring']] for f in scene['layers']['fields']], 'water':[[[p['x'],p['y']] for p in ring] for ring in scene['layers']['water']['rings']]}
        data={'request':{k:r[k] for k in ['role','fixtureSha256','upstreamCommit','worldSeed','burgId','identity']},'name':r['originalBurg']['name'],'geojson':g,'backdrop':backdrop}
        content=(json.dumps(data,separators=(',',':'))+'\n').encode()
        if sha(content)!=record['fixtureSha256']:raise ValueError('Derived fixture checksum mismatch: '+slug)
        (dest/f'fixtures/{slug}.json').write_bytes(content)
    print(f'PASS: 4 exact Git volumes, reconstructed 7z CRC, {len(checks)} internal checksums, 3 exact derived fixtures')
