"""Review-only assembly of actual Godot frames; no invented map/UI content."""
import json, pathlib
from PIL import Image, ImageDraw, ImageFont
root = pathlib.Path(__file__).resolve().parents[2]/'docs/implementation/game80'
proof = json.loads((root/'visual-proof.json').read_text())
assert proof['failures'] == 0
names = ['state-0-640x360', 'state-5-640x360', 'region-1-640x360',
         'region-3-640x360', 'hometown-0-640x360', 'hometown-20-640x360']
canvas = Image.new('RGB', (640, 54+len(names)*398), '#080807')
draw = ImageDraw.Draw(canvas)
font = ImageFont.load_default(size=14)
draw.text((12, 8), 'GAME-80 | actual Godot 4.6.3 frames', fill='#ddbd7b', font=font)
draw.text((12, 28), '640 x 360 logical layout; source IDs below are review annotations.', fill='#ddbd7b', font=font)
for index, name in enumerate(names):
    row = next(s for s in proof['screens'] if s['image'] == name+'.png')
    frame = Image.open(root/'screenshots'/row['image']).convert('RGB')
    assert frame.size == (640, 360)
    y = 54+index*398
    canvas.paste(frame, (0,y))
    seed = row['world'].split(':')[2]
    caption = f"{seed} | state {row['state']} | province {row['province']} | burg {row['burg']}"
    draw.text((12,y+366), caption, fill='#ddbd7b', font=font)
canvas.save(root/'contact-sheet.png')
print('Assembled six unchanged rendered frames:', root/'contact-sheet.png')
