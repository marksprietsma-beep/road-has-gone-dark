"""Compose labelled comparisons from real captures; never fabricate map pixels."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
out=Path(__file__).resolve().parents[1]/'evidence'
font=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',22)
small=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',18)
# Same physical image crop, at 1:1 pixels, across each before/after pair.
rows=[('game-11-determinism-selected','Albanes: selected capital, ordinary output'),('atlas-showcase-selected','Batan: selected settlement, ordinary output'),('game-11-determinism-selected-2x','Albanes: 2x output; native-pixel detail')]
sheet=Image.new('RGB',(1512,3*535+55),'#ede5d3'); d=ImageDraw.Draw(sheet)
d.text((15,12),'World labels — original GAME-70 / GAME-71 fix',fill='#262422',font=font)
for row,(name,caption) in enumerate(rows):
 y=55+535*row; d.text((15,y),caption,fill='#262422',font=small)
 for col,prefix in enumerate(['before','after']):
  img=Image.open(out/f'{prefix}-{name}.png').convert('RGB')
  # Capital stays at camera centre; detail is same native pixels in both versions.
  scale=2 if name.endswith('-2x') else 1
  cx=int((12+1108/2)*scale);cy=int((81+845/2)*scale)
  crop=img.crop((cx-370,cy-235,cx+370,cy+235))
  x=12+col*750;d.text((x,y+26),prefix.upper(),fill='#262422',font=small);sheet.paste(crop,(x,y+53))
sheet.save(out/'world-comparison.png')
sheet=Image.new('RGB',(1968,1035),'#ede5d3');d=ImageDraw.Draw(sheet)
d.text((14,12),'Albanes — exact same camera and zoom; selection changes only',fill='#262422',font=font)
for col,selected in enumerate(['none','guildhall','tavern','mill']):
 x=12+col*489;d.text((x,48),selected.title(),fill='#262422',font=font)
 for row,prefix in enumerate(['before','after']):
  y=83+row*475;d.text((x,y),prefix.upper(),fill='#262422',font=small)
  img=Image.open(out/f'{prefix}-albanes-{selected}.png').convert('RGB')
  sheet.paste(img.crop((320,310,800,750)),(x,y+25))
sheet.save(out/'town-selection-comparison.png')
print('Composed two comparisons from unaltered capture crops, at native pixel size.')
