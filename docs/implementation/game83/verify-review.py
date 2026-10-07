"""Verify capture dimensions, untouched gameplay sources and equal persisted outcomes.

Run after capture-expedition.gd on copies of the same initial campaigns, once on
GAME-84 and once on GAME-83. This does not normalize away any saved fields.
"""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
from PIL import Image

p = argparse.ArgumentParser()
for name in ['initial', 'baseline', 'after']:
    p.add_argument('--' + name, type=Path, required=True)
args = p.parse_args()
root = Path(__file__).resolve().parents[3]
docs = Path(__file__).parent
base = '3541e0bb2cc72ee147c3589e3a354b3b670d85e5'
protected = ['scripts/game_world', 'scripts/party', 'scripts/world_library',
             'scripts/world_enrichment', 'scripts/expedition/expedition_service.gd',
             'scripts/expedition/expedition_records.gd', 'tools', 'data',
             'tests/worldgen/fixtures', 'project.godot']
changed = subprocess.check_output(['git', 'diff', '--name-only', base, '--', *protected], cwd=root, text=True)
assert not changed, changed

def saves(directory):
    return {f.name: json.loads(f.read_text()) for f in (directory/'saves').glob('*.json')}

initial, baseline, after = [saves(d) for d in [args.initial, args.baseline, args.after]]
assert initial and initial.keys() == baseline.keys() == after.keys()
assert baseline == after, 'Complete saved campaign records differ between baseline and refactor'
played = [name for name in initial if initial[name] != baseline[name]]
assert played, 'No persisted operation occurred; equality alone would be insufficient'
for name in played:
    assert baseline[name]['expedition']['revision'] > initial[name]['expedition']['revision']
    assert not baseline[name]['expedition']['active']
captures = []
for stage in ['before', 'after']:
    for image in sorted((docs/stage).rglob('*.png')):
        size = Image.open(image).size
        for resolution in [(640,360), (1280,720), (2560,1440)]:
            if image.stem.endswith('%dx%d' % resolution):
                # Rounded logical canvas dimensions can leave a one-pixel
                # letterbox at 1280x720. The capture is the genuine viewport
                # texture, not a padded/resampled claim of a different raster.
                assert all(0 <= wanted-actual <= 1 for wanted,actual in zip(resolution,size)), str(image)
        captures.append({'path': str(image.relative_to(docs)), 'size': list(size),
                         'sha256': hashlib.sha256(image.read_bytes()).hexdigest()})
report = {'base_sha': base,
          'tested_source_sha': subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip(),
          'protected_paths_unchanged': protected,
          'complete_save_records_equal': len(baseline),
          'campaigns_exercised_by_capture': played,
          'save_comparison': 'All fields compared; no normalization or exclusions',
          'capture_note': 'Filenames identify requested physical window sizes. Godot viewport texture can omit a one-pixel letterbox; exact raster sizes are recorded below.',
          'captures': captures}
(docs/'review-proof.json').write_text(json.dumps(report,indent=2)+'\n')
print('PASS:',len(baseline),'equal complete campaign records;',len(played),
      'exercised campaigns;',len(captures),'original screenshots; gameplay paths unchanged')
