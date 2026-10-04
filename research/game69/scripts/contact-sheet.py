"""Compose actual Playwright stage captures; no regenerated artwork."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
root = Path(__file__).resolve().parents[1] / 'evidence'
fontpath = '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
font = ImageFont.truetype(fontpath, 20)
small = ImageFont.truetype(fontpath, 15)
towns = [('batan', 'Batan — 77 buildings'), ('albanes', 'Albanes — 463 buildings'), ('thilranlena', 'Thilranlena — 537 buildings')]
modes = [('A', 'A · Complete original (developer)'), ('B', 'B · GAME-67 simplified (public)'), ('C', 'C · Original art + facilities (public)')]
def tile(slug, mode, width):
    im = Image.open(root / f'{slug}-{mode}-map.png').convert('RGB')
    im.thumbnail((width, round(width * 530 / 954)), Image.Resampling.LANCZOS)
    return im
sheet = Image.new('RGB', (1800, 1180), '#f5efe2')
draw = ImageDraw.Draw(sheet)
draw.text((20, 12), 'GAME-69 · Actual browser captures · Same town, fit camera, no selection', fill='#28221b', font=font)
for i, (_, title) in enumerate(modes):
    draw.text((20 + i * 600, 48), title, fill='#28221b', font=small)
for r, (slug, title) in enumerate(towns):
    y = 82 + r * 360
    draw.text((20, y), title, fill='#28221b', font=font)
    for c, (mode, _) in enumerate(modes):
        sheet.paste(tile(slug, mode, 580), (10 + c * 600, y + 29))
sheet.save(root / 'comparison-desktop.png')
phone = Image.new('RGB', (550, 3350), '#f5efe2')
draw = ImageDraw.Draw(phone)
draw.text((12, 10), 'GAME-69 · Actual desktop stage captures', fill='#28221b', font=font)
draw.text((12, 40), 'Phone-friendly layout; mobile captures are separate.', fill='#28221b', font=small)
y = 76
for slug, town in towns:
    for mode, title in modes:
        draw.text((12, y), town, fill='#28221b', font=font)
        draw.text((12, y + 28), title, fill='#28221b', font=small)
        phone.paste(tile(slug, mode, 526), (12, y + 52))
        y += 360
phone.crop((0, 0, 550, y + 10)).save(root / 'comparison-phone-layout.png')
print('Composed 2 contact sheets from 9 actual, unselected stage captures.')
