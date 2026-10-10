#!/usr/bin/env python3
"""Compose an annotated review sheet from actual capture-origin.gd screenshots.

Requires Pillow for QA only. Never changes or synthesises game artwork.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / 'docs/implementation/game79/screenshots'
PANELS = [
    ('hometown-0-640x360.png', 'World I / Obnaste: stored public memory'),
    ('hometown-1-640x360.png', 'World I / Jungsund: another memory, aligned map and facts'),
    ('hometown-20-640x360.png', 'Fresh generated world / Nynead: same production pipeline'),
    ('confirmation-640x360.png', 'Gonlon: fuller stored history before confirmation'),
    ('origin-established.png', 'Gonlon: validated save, Party Creation Next'),
]
font = ImageFont.load_default(size=16)
sheet = Image.new('RGB', (640, len(PANELS) * 394), '#17150f')
draw = ImageDraw.Draw(sheet)
for index, (filename, caption) in enumerate(PANELS):
    image = Image.open(OUTPUT / filename).convert('RGB')
    # Only the high-resolution handoff is reduced; all logical frames stay exact.
    if image.size != (640, 360):
        image = image.resize((640, 360), Image.Resampling.LANCZOS)
    y = index * 394
    draw.text((12, y + 8), caption, fill='#ead39b', font=font)
    sheet.paste(image, (0, y + 34))
sheet.save(OUTPUT / 'contact-sheet.png')
print(OUTPUT / 'contact-sheet.png')
