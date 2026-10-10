#!/usr/bin/env python3
"""Independent scalar-coordinate/source audit of the Godot evidence."""
import hashlib, json, math, os, pathlib, statistics
root = pathlib.Path(__file__).resolve().parents[2]
proof = json.loads((root / 'docs/implementation/game75/context-proof.json').read_text(encoding='utf-8'))
assert proof['failures'] == 0
preset_paths = {json.loads(p.read_text(encoding="utf-8"))["seed"]:p for p in [root / "tests/worldgen/fixtures/game-11-determinism.json",root / "tests/worldgen/fixtures/atlas-showcase.json"]}
report = []
for item in proof['worlds']:
    ref = item['world_ref']
    seed = ref['seed']
    path = preset_paths.get(seed, pathlib.Path(os.environ['GAME75_GENERATED_DIR']) / seed / 'world.json')
    raw = json.loads(path.read_text(encoding='utf-8'))
    assert hashlib.sha256(path.read_bytes()).hexdigest() == ref['sha256']
    assert raw['seed'] == seed and item['world']['world_id'] == ref['id']
    cells = raw['cells']
    features = {f['i']:f for f in raw['map']['geography'] if isinstance(f,dict)}
    public = [t for t in raw['settlements'] if isinstance(t,dict) and t.get('i',0)>0 and t.get('population',0)>0 and not t.get('hidden') and not t.get('removed')]
    biome_area, feature_area = {}, {}
    for i, height in enumerate(cells['heights']):
        if height<20: continue
        biome = cells['biome'][i]
        feature = cells['features'][i]
        biome_area[str(biome)] = biome_area.get(str(biome),0) + cells['area'][i]
        if features.get(feature,{}).get('land'):
            feature_area[str(feature)] = feature_area.get(str(feature),0) + cells['area'][i]
    facts = item['world']['facts']
    assert biome_area == facts['biome_areas'] and feature_area == facts['land_features']
    assert [t['i'] for t in public] == facts['town_ids'] and len(public) == facts['town_count']
    share = max(feature_area.values()) / sum(biome_area.values())
    assert math.isclose(share,facts['largest_land_share'],abs_tol=1e-10)
    expected_shape = 'One main landmass dominates.' if share>=.75 else ('More than one landmass.' if share>=.5 else 'Land spread across several landmasses.')
    assert item['world']['summary'].splitlines()[1] == expected_shape
    coastal = sum(any(cells['heights'][n]<20 and features.get(cells['features'][n],{}).get('type')=='ocean' for n in cells['neighbors'][t['cell']]) for t in public)
    assert coastal == facts['coastal_town_count']
    # Different implementation from Godot's pairwise Vector2 pass: each town's
    # own scalar nearest search, then Python's standard median.
    nearest = []
    for town in public:
        feature = cells['features'][town['cell']]
        if not features.get(feature,{}).get('land'): continue
        distances = [math.hypot(town['x']-other['x'],town['y']-other['y']) for other in public if other['i']!=town['i'] and cells['features'][other['cell']]==feature]
        if distances: nearest.append(min(distances))
    radius = 2*statistics.median(nearest) if nearest else -1
    home = item['sample_home']['facts']
    assert math.isclose(radius,home['nearby_radius_source_units'],abs_tol=.001)  # Vector2 float32 rounding
    selected = next(t for t in public if t['i']==home['burg_id'])
    expected_ids = [t['i'] for t in public if t['i']!=selected['i'] and cells['features'][t['cell']]==cells['features'][selected['cell']] and math.hypot(t['x']-selected['x'],t['y']-selected['y'])<=radius]
    assert expected_ids == home['nearby_ids']
    report.append({'seed':seed,'sha256':ref['sha256'],'largest_land_share':share,'coastal_towns':coastal,'independent_nearby_radius_source_units':radius})
assert len(report)==5
(root / 'docs/implementation/game75/independent-proof.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print('PASS: 5 independent source audits: exact identity, landmass/biome areas, public counts/coastline, scalar nearest-neighbour median and complete sample neighbourhoods')
