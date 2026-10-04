import unittest,json,hashlib,math,xml.etree.ElementTree as E,subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3];HERE=ROOT/'research/game69';MANIFEST=json.loads((HERE/'art/manifest.json').read_text());FRAMES=json.loads((HERE/'art/frames.json').read_text())
class OriginalArtTests(unittest.TestCase):
 def test_original_bytes_match_verified_GAME63_outputs(self):
  expected={'batan':'310247e63db0a60e143fd03e2131c65fc5d99f1eb63c725aaa0ec445ff0ab168','albanes':'e7bfbe4f2068a54d975df747ace546d063cfd50e491b82f8c6a5ae4c7135e188','thilranlena':'5f47e690b352c7ed7f82f1bb2c0656f847232ddd2353f04524df8717192b88f7'}
  for r in MANIFEST['settlements']:self.assertEqual(hashlib.sha256((HERE/f"art/{r['slug']}.original.svg").read_bytes()).hexdigest(),expected[r['slug']])
 def test_svg_transform_matches_native_coordinate_frame(self):
  for r in MANIFEST['settlements']:
   root=E.parse(HERE/f"art/{r['slug']}.original.svg").getroot();native=list(map(float,root.attrib['viewBox'].split()));f=r['frame'];t=f['nativeToWorld']
   self.assertEqual(native,r['nativeViewBox']);self.assertAlmostEqual(native[0]*t['scale']+t['translate'][0],f['x']);self.assertAlmostEqual(native[1]*t['scale']+t['translate'][1],f['y']);self.assertAlmostEqual(native[2]*t['scale'],f['width']);self.assertAlmostEqual(native[3]*t['scale'],f['height'])
 def test_measured_anchors_cover_expected_source_paint(self):
  for r,n in zip(MANIFEST['settlements'],[77,461,535]):
   self.assertEqual(r['measuredBuildingCount'],n);self.assertEqual(len(r['anchors']),n);self.assertLess(r['maxAnchorResidualLocal'],.0071)
   for anchor in r['anchors'].values():self.assertAlmostEqual(math.dist(anchor['artAnchor'],anchor['referenceAnchor']),anchor['residualLocal'])
 def test_real_guildhall_warehouse_and_village_landmarks_align(self):
  for r in MANIFEST['settlements']:
   for b in r['facilityBindings']:self.assertLess(b['facilityAnchorResidualLocal'],.005)
   bindings=r['facilityBindings']
   if r['slug']=='albanes':self.assertEqual(next(b for b in bindings if b['type']=='guildhall')['providerId'],'b93')
   if r['slug']=='thilranlena':self.assertEqual(next(b for b in bindings if b['type']=='warehouse')['providerId'],'b223')
 def test_public_preparation_preserves_every_geometry_and_transform(self):
  for r in MANIFEST['settlements']:
   original=list(E.parse(HERE/f"art/{r['slug']}.original.svg").getroot().iter());public=list(E.parse(HERE/f"art/{r['slug']}.public.svg").getroot().iter());self.assertEqual(len(original),len(public))
   edits=[]
   for a,b in zip(original,public):
    self.assertEqual(a.tag,b.tag)
    for key in ['d','points','transform','x','y','cx','cy','r','width','height','viewBox']:self.assertEqual(a.attrib.get(key),b.attrib.get(key),(r['slug'],key))
    expected={k:v for k,v in a.attrib.items()if not k.startswith('data-')}
    if expected!=b.attrib:edits.append(a.attrib.get('data-building-id'))
   self.assertEqual(sorted(edits),sorted([x['providerBuildingId']for x in r['redactions']]))
   self.assertEqual(len(edits),0 if r['slug']=='batan'else 2)
 def test_unknown_source_semantics_are_anonymized_without_moving_roofs(self):
  for r in MANIFEST['settlements']:
   original=list(E.parse(HERE/f"art/{r['slug']}.original.svg").getroot().iter());public=list(E.parse(HERE/f"art/{r['slug']}.public.svg").getroot().iter())
   m=json.loads((ROOT/f"research/game67/samples/{r['slug']}.developer.json").read_text());hidden=[e for e in m['establishments']if e['knowledge']=='unknown']
   for a,b in zip(original,public):
    if any(a.attrib.get('data-building-id')==e['provenance']['providerBuildingId']for e in hidden):
     if a.tag.endswith('use'):self.assertIn('sm-house-tiled',b.attrib['href']);self.assertNotIn('shop',b.attrib['href'])
     else:self.assertNotIn('class',b.attrib)
   self.assertTrue(all(not any(k.startswith('data-')for k in el.attrib)for el in public))
 def test_public_frames_exclude_privileged_binding_and_redaction_metadata(self):
  for f in FRAMES:
   self.assertNotIn('anchors',f);self.assertNotIn('redactions',f);self.assertNotIn('facilityBindings',f)
   self.assertEqual(set(f),{'slug','frame','nativeViewBox','background','maxAnchorResidualLocal','measuredBuildingCount','buildingCount'})
 def test_art_is_self_contained_and_has_no_executable_content(self):
  for p in (HERE/'art').glob('*.svg'):
   for el in E.parse(p).getroot().iter():
    self.assertNotIn(el.tag.split('}')[-1],['script','foreignObject'])
    self.assertTrue(all(not k.lower().startswith('on')for k in el.attrib))
    if el.tag.endswith('use'):self.assertTrue(el.attrib['href'].startswith('#'))
 def test_semantic_icons_are_pinned_same_family_with_correct_author_credits(self):
  records=json.loads((HERE/'assets/icon-manifest.json').read_text());self.assertEqual(len(records),13)
  for r in records:
   self.assertEqual(r['upstreamCommit'],'82d948812bfe3f269ef8f731dcdb07b08160edc4');self.assertEqual(r['licence'],'CC BY 3.0');self.assertEqual(hashlib.sha256((HERE/f"assets/{r['role']}.svg").read_bytes()).hexdigest(),r['preparedSha256'])
  self.assertEqual(next(r['source']for r in records if r['role']=='smithy'),'lorc/anvil.svg');self.assertEqual(next(r['source']for r in records if r['role']=='guildhall'),'delapouite/round-table.svg')
 def test_upstream_GAME67_and_production_are_unchanged(self):
  paths=['research/game67','scripts','scenes','tools','assets','vendor','tests','data','project.godot']
  result=subprocess.check_output(['git','diff','--name-only',MANIFEST['game67Baseline'],'--',*paths],cwd=ROOT,text=True)
  self.assertEqual(result,'')
if __name__=='__main__':unittest.main(verbosity=2)
