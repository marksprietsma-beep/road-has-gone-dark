"""Actual librsvg rendering + annotated comparisons; no invented game screenshots."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
import subprocess,json,hashlib,shutil,os,textwrap
root=Path(__file__).resolve().parents[3];os.chdir(root)
folder=root/'research/game73';out=folder/'evidence'
renderer=os.environ.get('RSVG_CONVERT') or shutil.which('rsvg-convert') or '/tmp/game70-system/usr/bin/rsvg-convert'
font=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',24)
bold=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',30)
small=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',20)
rendered=[]
for source in sorted(out.glob('*.svg')):
 dest=source.with_suffix('.png')
 subprocess.run([renderer,'--width','1000','--height','1000','--output',str(dest),str(source)],check=True)
 im=Image.open(dest);assert im.getbbox()
 if source.stem.endswith('-town') or source.stem.endswith('-rotation'):
  colors=im.convert('RGB').resize((150,150)).getcolors(22500)
  assert len(colors)>200 and max(n for n,c in colors)<20000, 'Missing preserved town artwork: '+source.name
 rendered.append({'svg':str(source.relative_to(root)),'png':str(dest.relative_to(root)),'sourceSha256':hashlib.sha256(source.read_bytes()).hexdigest(),'pngSha256':hashlib.sha256(dest.read_bytes()).hexdigest(),'pixels':list(im.size)})
cases=json.loads((folder/'examples/cases.json').read_text())['cases']
notes={
'batan':['SOURCE: grassland, inland, no walls; population 0.306.','ART: 77 buildings, farms and a wooded rural fringe.','ASSESSMENT: plausible character. Woodland is artistic, not an exact forest boundary.'],
'albanes':['SOURCE: capital, walls and citadel; rainforest biome.','ART: 463 buildings; fortifications and local cultivated fields.','ASSESSMENT: clearing farmland within a forested biome is believable; its mapped extent is uncalibrated.'],
'thilranlena':['SOURCE: port, NW ocean, trail 54; population 4.679.','ART: 537 buildings; synthetic NW waterfront, two piers.','ASSESSMENT: water differs by 0.87 degrees; west trail is tagged harbour in exported entrance data. Inspect that connection.'],
'neighbour-a':['Colira #569 / cell 3311. Riveivalfei #774 is a NEIGHBOUR.','Source road 12 connects their consecutive source points.','Detailed town maps for this pair are UNAVAILABLE.'],
'neighbour-b':['Riveivalfei #774 / cell 3171. Colira #569 is a NEIGHBOUR.','Same world, distinct ownership; overlapping windows.','Detailed town maps for this pair are UNAVAILABLE.']}
def lines(draw,x,y,values,width=55,chosen=font):
 for value in values:
  for line in textwrap.wrap(value,width):draw.text((x,y),line,font=chosen,fill='#302a20');y+=31
 return y
for c in cases:
 slug=c['slug'];ctx=json.loads((folder/f'examples/{slug}.context.json').read_text());height=3200 if c['townAvailable'] else 2370
 sheet=Image.new('RGB',(720,height),'#eee4cf');draw=ImageDraw.Draw(sheet)
 y=lines(draw,20,15,[f"GAME-73 / {c['label']}",f"{c['stem']} / burg {c['id']} / cell {c['cellId']}"],45,bold)
 draw.text((20,y+8),'SOURCE DIAGNOSTICS + REAL REGIONAL / ART RENDERS',font=small,fill='#675741');y+=42
 world=Image.open(out/f'{slug}-world.png').convert('RGB');sheet.paste(world.resize((180,180)),(15,y))
 lines(draw,210,y+20,[f"Seed: {ctx['identity']['worldSeed']}",f"Population: {ctx['scale']['population']['value']} (source units)",'Physical scale: UNCALIBRATED'],32,small)
 y+=185
 source=Image.open(out/f'{slug}-source.png').convert('RGB');sheet.paste(source.resize((680,680)),(20,y))
 y+=690;y=lines(draw,20,y,['Red: selected cell / burg. Purple: independent neighbour.','Dashed: viewing window and unpadded core. Fringe = 20% of longest cell extent on EACH side.'],52,small)
 draw.text((20,y+5),'ACCEPTED GAME-62 REGION + RESEARCH ANNOTATIONS',font=small,fill='#675741');y+=40
 region=Image.open(out/f'{slug}-region.png').convert('RGB');sheet.paste(region.resize((680,680)),(20,y));y+=690
 y=lines(draw,20,y,['Tint: hypothetical footprint, clipped to source ownership.','Illustration details are NOT geographical measurements.'],52,small)
 if c['townAvailable']:
  draw.text((20,y+5),'PRESERVED PUBLIC SETTLEMENT ART + BEARING DIAGRAM',font=small,fill='#675741');y+=40
  town=Image.open(out/f'{slug}-town.png').convert('RGB');sheet.paste(town.resize((680,680)),(20,y));y+=690
 y=lines(draw,20,y+10,notes[slug],54)
 sheet.crop((0,0,720,min(height,y+25))).save(out/f'{slug}-phone.png')
# Explicit relative-envelope graphic, using different normalised cell denominators.
scale=json.loads((folder/'examples/relative-scale.json').read_text())
scale_sheet=Image.new('RGB',(720,860),'#eee4cf');d=ImageDraw.Draw(scale_sheet)
lines(d,18,15,['Source-relative size guideline','Each box normalises its own parent cell.','Circles are proposed area fractions.'],45,bold)
for i,c in enumerate(scale['cases']):
 y=160+i*145;v=c['scale'];fraction=v['aestheticEnvelope']['value']['targetCellAreaFraction']
 d.rectangle((20,y,140,y+120),fill='#c5c59d',outline='#736947',width=2)
 radius=120*(fraction/3.141592653589793)**.5;d.ellipse((80-radius,y+60-radius,80+radius,y+60+radius),fill='#bd8f67')
 lines(d,165,y+6,[f"{c['label']} / {v['category']['value'].replace('capital_or_major_fortified','capital (fortified)').replace('_',' ')}",f"Population {v['population']['value']}; envelope {100*fraction:.2f}%",f"Cell polygon area {v['cellPolygonArea']['value']:.2f} source units²"],36,small)
lines(d,18,770,['No kilometre conversion. Port is a character overlay.','Detailed art unavailable for the ordinary town example.'],55,small)
scale_sheet.save(out/'relative-scale.png')
scale_chart=[{'burgId':c['identity']['burgId'],'cellSidePixels':120,'circleRadiusPixels':120*(c['scale']['aestheticEnvelope']['value']['targetCellAreaFraction']/3.141592653589793)**.5,'proposedAreaFraction':c['scale']['aestheticEnvelope']['value']['targetCellAreaFraction']}for c in scale['cases']]
# Full frame side-by-side evidence is separate from narrow case sheets.
for slug in ['albanes','batan','thilranlena']:
 sheet=Image.new('RGB',(1800,1020),'#eee4cf');d=ImageDraw.Draw(sheet)
 d.text((15,12),f'{slug.title()}: actual GAME-62 region / preserved town art. Different uncalibrated scales.',font=bold,fill='#302a20')
 for col,suffix in enumerate(['region','town']):sheet.paste(Image.open(out/f'{slug}-{suffix}.png').convert('RGB').resize((880,880)),(10+900*col,68))
 d.text((15,960),'Red arrows are source-bearing diagrams; tint is a hypothetical envelope. No world-to-town fit is claimed.',font=font,fill='#302a20');sheet.save(out/f'{slug}-comparison.png')
# Rotation feasibility, always explicitly rejected rather than passed off as a fix.
assessment=json.loads((folder/'examples/thilranlena.town-assessment.json').read_text());rotation=assessment['rotationExperiment']
sheet=Image.new('RGB',(1600,1015),'#eee4cf');d=ImageDraw.Draw(sheet)
d.text((15,15),'Thilranlena: keep original orientation / reject forced cell-centre rotation',font=bold,fill='#302a20')
for col,suffix in enumerate(['town','rotation']):sheet.paste(Image.open(out/f'thilranlena-{suffix}.png').convert('RGB').resize((780,780)),(10+800*col,75))
lines(d,18,875,['Original water error 0.87 deg; road-entry errors 0.3 / 3.1 deg.',f"Rotating {rotation['clockwiseDegrees']:.2f} deg toward the CELL CENTRE approximation worsens burg-water error to 14.51 deg and road errors to 15.08 / 12.28 deg."],108)
sheet.save(out/'rotation-comparison.png')
# Both independent neighbouring views, distinct owners, same source road/coast.
sheet=Image.new('RGB',(1600,1040),'#eee4cf');d=ImageDraw.Draw(sheet)
d.text((15,12),'Colira / Riveivalfei: actual independent neighbouring regions',font=bold,fill='#302a20')
for col,slug in enumerate(['neighbour-a','neighbour-b']):sheet.paste(Image.open(out/f'{slug}-region.png').convert('RGB').resize((780,780)),(10+800*col,70))
lines(d,18,872,['World game-11-determinism. Burgs 569 / 774, cells 3311 / 3171. Road 12.','Distinct ownership, shared source frame. Purple town is in the other cell.','No detailed town map is available for either. Illustration decoration differs.'],106)
sheet.save(out/'neighbour-comparison.png')
# Phone-width overview: one full-width regional frame per case, not tiny whole-page thumbnails.
contact=Image.new('RGB',(720,5*845+100),'#eee4cf');d=ImageDraw.Draw(contact);d.text((16,20),'GAME-73 — geographical coherence',font=bold,fill='#302a20')
for i,c in enumerate(cases):
 y=85+i*845;d.text((16,y),c['label']+' / burg '+str(c['id'])+' / cell '+str(c['cellId']),font=bold,fill='#302a20')
 contact.paste(Image.open(out/f"{c['slug']}-region.png").convert('RGB').resize((680,680)),(20,y+52))
 lines(d,20,y+740,['Source truth preserved; tint is a hypothetical envelope.','Full source + town comparison: '+c['slug']+'-phone.png'],54,small)
contact.save(out/'contact-sheet.png')
(out/'visual-manifest.json').write_text(json.dumps({'renderer':subprocess.check_output([renderer,'--version'],text=True).strip(),'artUnmodified':True,'scaleChart':scale_chart,'gameScreenshots':False,'method':'Actual source-derived SVG/accepted GAME-62/public town SVG rasterisation; contact sheets compose those real rasters','renders':rendered},indent=2)+'\n')
print(f'PASS {len(rendered)} actual librsvg rasters; five phone cases, three comparisons, neighbour comparison and rejected rotation proof.')
