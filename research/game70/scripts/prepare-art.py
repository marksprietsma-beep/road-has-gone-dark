"""Rasterize exact GAME-69 public derivatives; no generator or geometry edits."""
import hashlib,json,os,subprocess
from pathlib import Path
root=Path(__file__).resolve().parents[3]
renderer=os.environ.get('RSVG_CONVERT','rsvg-convert')
records=[]
for slug in ['batan','albanes','thilranlena']:
    source=root/f'research/game69/art/{slug}.public.svg'
    target=root/f'research/game70/art/{slug}.png'
    subprocess.run([renderer,'--keep-aspect-ratio','--width','4096','--height','4096','--output',str(target),str(source)],check=True)
    from PIL import Image
    im=Image.open(target)
    records.append({'slug':slug,'source':str(source.relative_to(root)),'sourceSha256':hashlib.sha256(source.read_bytes()).hexdigest(),'outputSha256':hashlib.sha256(target.read_bytes()).hexdigest(),'pixels':list(im.size),'renderer':subprocess.check_output([renderer,'--version'],text=True).strip(),'frameSource':'research/game69/art/frames.json','preparation':'Exact public SVG; preserve aspect ratio, at most 4096px; no crop or coordinate edits'})
    print('PASS',slug,im.size,'exact GAME-69 public art rasterized for Godot')
(root/'research/game70/art/manifest.json').write_text(json.dumps(records,indent=2)+'\n')
