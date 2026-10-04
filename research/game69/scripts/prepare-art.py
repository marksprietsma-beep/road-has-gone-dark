#!/usr/bin/env python3
"""Use verified original GAME-63 illustration bytes; never run the generator.
Optional argument is the already-extracted GAME-63 directory. Otherwise reconstruct
and CRC-test original volumes using py7zr==1.1.3 in a temporary directory.
"""
import hashlib,json,math,re,sys,tempfile,xml.etree.ElementTree as E
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3];OUT=ROOT/'research/game69';SVG='http://www.w3.org/2000/svg'
E.register_namespace('',SVG);E.register_namespace('xlink','http://www.w3.org/1999/xlink')
sha=lambda b:hashlib.sha256(b).hexdigest()
expected=['38fe70bf0657583027b200546e562d3c705cac2edb3c0a48a47a0200eb53a79e','aeb028d1b4419059cdc9c0e598c38ea772badb9d9149ca69611bac8f2b3b50ad','03cca98de4402f7d2ae2a50b4852d3e2d56fcc3e84ff7d9046ad21a23002b74f','db5c2ebdd1be3da2750eddc1955c5138e92f6bd1f314d3f59360a9d2aaf001c6']
parts=[(ROOT/f'game63-proof.7z.{i:03}').read_bytes()for i in range(1,5)]
assert [sha(b)for b in parts]==expected,'Original volume checksum mismatch'
archive_bytes=b''.join(parts)
assert sha(archive_bytes)=='ba6a216632020d3b3134ca818176f484b1f2d4ca4ca5cde8441d9fda8fbf16cf'

def prepare(src):
    checks=(src/'evidence/SHA256SUMS.txt').read_text().splitlines()
    for line in checks:
        expected,rel=line.split('  ',1);assert sha((src/rel).read_bytes())==expected,rel
    records=[]
    for stem,slug in [('village','batan'),('fortified-town','albanes'),('coastal-port','thilranlena')]:
        original=(src/f'outputs/{stem}.svg').read_bytes();root=E.fromstring(original)
        model=json.loads((ROOT/f'research/game67/samples/{slug}.developer.json').read_text())
        fixture=json.loads((ROOT/f'research/game67/fixtures/{slug}.json').read_text())
        raw_geo=json.loads((src/f'outputs/{stem}.geojson').read_text())
        assert raw_geo==fixture['geojson'],'Original geometry differs from GAME-67'
        (OUT/f'art/{slug}.original.svg').write_bytes(original)
        native=[float(v)for v in root.attrib['viewBox'].split()]
        if slug=='batan':
            scale=float(root.attrib['data-px-per-metre']);ox=float(root.attrib['data-origin-x']);oy=float(root.attrib['data-origin-y'])
            frame={'x':(native[0]-ox)/scale,'y':(native[1]-oy)/scale,'width':native[2]/scale,'height':native[3]/scale,'nativeToWorld':{'scale':1/scale,'translate':[-ox/scale,-oy/scale]}}
        else:
            frame={'x':native[0],'y':native[1],'width':native[2],'height':native[3],'nativeToWorld':{'scale':1,'translate':[0,0]}}
        source_buildings={b['providerId']:b for b in model['buildings']};anchors={}
        scene_refs={}
        if slug!='batan':
            scene=json.loads((src/f'outputs/{stem}.scene.json').read_text())
            scene_refs={sym['buildingId']:[sym['at']['x'],sym['at']['y']]for sym in scene['layers']['symbols']if sym.get('buildingId')}
        def collect(el,shadow=False,definition=False):
            shadow=shadow or el.attrib.get('id')=='shadows' or el.attrib.get('data-shadow')=='1'
            definition=definition or el.tag.endswith('defs')
            pid=el.attrib.get('data-building-id')or(el.attrib.get('data-id')if el.attrib.get('data-kind')=='building' else None)
            if pid and pid in source_buildings and not shadow and not definition:
                match=re.match(r'translate\(([-\d.]+)[ ,]+([-\d.]+)\)',el.attrib.get('transform',''))
                if match:anchor=[float(x)for x in match.groups()]
                elif el.tag.endswith('path'):
                    xy=[float(x)for x in re.findall(r'-?\d+(?:\.\d+)?',el.attrib.get('d',''))]
                    pts=list(zip(xy[::2],xy[1::2]));anchor=[sum(p[a]for p in pts)/len(pts)for a in [0,1]]
                else:anchor=None
                if anchor:
                    t=frame['nativeToWorld'];world=[anchor[a]*t['scale']+t['translate'][a]for a in [0,1]]
                    poly=source_buildings[pid]['polygon'][0][:-1];centre=[sum(p[a]for p in poly)/len(poly)for a in [0,1]]
                    reference=scene_refs.get(pid,centre)
                    anchors[pid]={'artAnchor':world,'referenceAnchor':reference,'referenceKind':'original Scene symbol centre'if pid in scene_refs else 'original polygon vertex mean','polygonVertexMean':centre,'residualLocal':math.dist(world,reference)}
            for child in el:collect(child,shadow,definition)
        collect(root)
        missing=[b['providerId']for b in model['buildings']if b['providerId']not in anchors]
        key_bindings=[{'type':e['type'],'providerId':e['provenance']['providerBuildingId'],'measurement':anchors.get(e['provenance']['providerBuildingId']),'facilityAnchorResidualLocal':math.dist(anchors[e['provenance']['providerBuildingId']]['artAnchor'],e['sourcePosition'])if e['provenance']['providerBuildingId']in anchors else None}for e in model['establishments']if e['type']in ['chapel','inn','manor','guildhall','warehouse']]
        # Developer image retains all original paint, but metadata identifiers
        # are unnecessary to render. Public image neutralizes only hidden roofs.
        hidden={e['provenance']['providerBuildingId']for e in model['establishments']if e['knowledge']=='unknown' and e['buildingId']}
        redactions=[]
        for audience in ['public']:
            tree=E.fromstring(original)
            def sanitize(el,shadow=False):
                shadow=shadow or el.attrib.get('id')=='shadows'
                pid=el.attrib.get('data-building-id')
                if audience=='public' and pid in hidden:
                    if el.tag.endswith('use'):
                        # Reuse an ORIGINAL generic tiled-roof glyph, with the
                        # EXACT original translation, rotation and scaling.
                        href=el.attrib.get('href','')
                        generic='#glyph-sm-house-tiled-sil'if href.endswith('-sil')else '#glyph-sm-house-tiled-tone-1'
                        assert any(x.attrib.get('id')==generic[1:]for x in tree.iter()),generic
                        el.set('href',generic)
                    elif el.tag.endswith('path'):
                        # The original round market roof stays the exact path;
                        # only its semantic class/style becomes anonymous.
                        el.attrib.pop('class',None);el.set('fill','#756542'if shadow else '#c2a167')
                    else:raise ValueError('Unrecognized hidden-roof artwork')
                    redactions.append({'providerBuildingId':pid,'tag':el.tag.split('}')[-1],'transform':el.attrib.get('transform'),'method':'original generic glyph / unchanged roof path'})
                for key in list(el.attrib):
                    if key.startswith('data-'):del el.attrib[key]
                for child in el:sanitize(child,shadow)
            sanitize(tree)
            for x in tree.iter():
                assert not x.tag.endswith('script')
                if x.tag.endswith('use'):assert x.attrib.get('href','').startswith('#'),'External source dependency'
            content=E.tostring(tree,encoding='utf-8')
            if audience=='public':
                for pid in hidden:assert f'data-building-id="{pid}"'.encode()not in content
            (OUT/f'art/{slug}.{audience}.svg').write_bytes(content)
        records.append({'slug':slug,'originalSha256':sha(original),'publicSha256':sha((OUT/f'art/{slug}.public.svg').read_bytes()),'developerSha256':sha(original),'nativeViewBox':native,'background':next((x.attrib.get('fill')for x in root if x.tag.endswith('rect')and x.attrib.get('fill')), '#fff2c4'),'frame':frame,'buildingCount':len(model['buildings']),'measuredBuildingCount':len(anchors),'unidentifiedPaintBuildings':missing,'maxAnchorResidualLocal':max(a['residualLocal']for a in anchors.values()),'facilityBindings':key_bindings,'redactions':redactions,'anchors':anchors})
    manifest={'schemaVersion':1,'source':'Original GAME-63 outputs; never regenerated','providerRevision':'d5cf3590cf59e1d382110d25a6910f12507299e2','game67Baseline':'740f1910787cafae172fdf5d74777bbb032b92a0','volumeHashes':expected,'archiveSha256':sha(archive_bytes),'internalChecksumsPassed':len(checks),'settlements':records}
    (OUT/'art/manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    frames=[{k:r[k]for k in ['slug','frame','nativeViewBox','background','maxAnchorResidualLocal','measuredBuildingCount','buildingCount']}for r in records]
    (OUT/'art/frames.json').write_text(json.dumps(frames,indent=2)+'\n')
    for r in records:print(r['slug'],r['measuredBuildingCount'],'measured of',r['buildingCount'],'max local residual',r['maxAnchorResidualLocal'],'public paint edits',len(r['redactions']))

if len(sys.argv)>1:prepare(Path(sys.argv[1]))
else:
    import py7zr
    with tempfile.TemporaryDirectory(prefix='game69-original-')as tmp:
        tmp=Path(tmp);archive=tmp/'source.7z';archive.write_bytes(archive_bytes)
        with py7zr.SevenZipFile(archive)as f:assert f.testzip()is None,'7z CRC failure'
        with py7zr.SevenZipFile(archive)as f:f.extractall(tmp/'extracted')
        prepare(tmp/'extracted')
