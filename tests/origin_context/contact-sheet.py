#!/usr/bin/env python3
"""Optional QA composite of genuine captures; no game-art alterations."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
root = Path(__file__).resolve().parents[2] / 'docs/implementation/game75/screenshots'
rows = [('01-world-i','World I: woodland'),('02-world-ii','World II: grassland'),
        ('region-forest','Province: inland woodland'),('region-coastal_port','Province: coast and recorded ports'),
        ('home-forest','Maura: inland road and cluster'),('home-coastal_port','Klovskitaue: coastal port'),
        ('home-walled','Lauerila: recorded walls and trail'),('home-sparse','Turnan: no close towns on this landmass')]
canvas = Image.new('RGB',(1280,4*394),'black')
draw = ImageDraw.Draw(canvas)
try: font = ImageFont.truetype('DejaVuSans.ttf',22)
except OSError: font = ImageFont.load_default()
for i,(name,label) in enumerate(rows):
    x,y = (i%2)*640,(i//2)*394
    draw.text((x+12,y+4),label,fill='#e9c261',font=font)
    with Image.open(root / (name+'.png')) as screenshot:
        canvas.paste(screenshot.resize((640,360),Image.Resampling.LANCZOS),(x,y+34))
canvas.save(root / 'contact-sheet.png')
