"""Compose real Godot viewport PNGs; no mock-up or artwork generation."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
folder=Path(__file__).resolve().parents[1]/'evidence'
font=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',20)
small=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',15)
steps=[('world','1 · Original atlas / selected source burg'),('region','2 · Real GAME-62 parent cell'),('town','3 · Matching original-art town'),('facility','4 · Inspect exact source building'),('return-region','5 · Back / regional camera restored'),('return-world','6 · Back / world identity restored')]
image=Image.new('RGB',(1800,2700),'#eee4ce');draw=ImageDraw.Draw(image)
draw.text((20,15),'GAME-70 · Actual Godot navigation proof · 1440×960 source captures',font=font,fill='#30281d')
for col,(slug,title) in enumerate([('albanes','Albanes · game-11 · burg 7 · cell 917'),('batan','Batan · atlas · burg 760 · cell 4354'),('thilranlena','Thilranlena · atlas · burg 68 · cell 1689')]):
    draw.text((15+col*600,55),title,font=small,fill='#30281d')
    for row,(step,label) in enumerate(steps):
        y=90+row*430
        draw.text((15+col*600,y),label,font=small,fill='#30281d')
        screenshot=Image.open(folder/f'{slug}-{step}.png').convert('RGB')
        screenshot.thumbnail((580,390),Image.Resampling.LANCZOS)
        image.paste(screenshot,(10+col*600,y+28))
image.save(folder/'journeys-contact-sheet.png')
print('PASS contact sheet composed from 18 actual Godot captures')
