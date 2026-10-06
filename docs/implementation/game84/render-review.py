"""Compose actual Godot captures without retouching their content (build-only Pillow)."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
root=Path(__file__).parent
shots=[('Party ready → Enter hometown','party-ready-handoff.png'),('Hometown and local accounts','hometown-1280x720.png'),('Rumour: no name or exact marker','rumour-before-1280x720.png'),('Scouted: location recorded','rumour-discovered-1280x720.png'),('Contextual choices and costs','site-options-1280x720.png'),('Persisted consequence','consequence-1280x720.png'),('Main menu resumes the expedition','main-menu-resume-expedition.png'),('Returned home: completed account','returned-hometown-1280x720.png')]
canvas=Image.new('RGB',(1280,1600),'#101010');draw=ImageDraw.Draw(canvas)
try:font=ImageFont.truetype('DejaVuSans.ttf',18)
except OSError:font=ImageFont.load_default()
draw.text((12,8),'Actual Godot 4.6.3 / Linux software GL — 1280×720 captures resized for this sheet',font=font,fill='#edc45f')
for index,(caption,name) in enumerate(shots):
 x=(index%2)*640;y=40+(index//2)*390
 draw.text((x+10,y+4),caption,font=font,fill='#edc45f')
 picture=Image.open(root/'screenshots'/name).convert('RGB').resize((640,360),Image.Resampling.LANCZOS)
 canvas.paste(picture,(x,y+28))
canvas.save(root/'CONTACT-SHEET.png')
(root/'SCREENSHOTS.md').write_text('# Actual Godot screenshot sequence\n\nLinux Godot 4.6.3, Mesa software GL; native Windows execution is verified separately in CI and awaits Mark’s laptop visual acceptance. Images are genuine game renders. The contact sheet only resizes/composes them; original captures remain below.\n\n![Contact sheet](CONTACT-SHEET.png)\n\n'+''.join('## '+caption+'\n\n![Godot capture](screenshots/'+name+')\n\n'for caption,name in shots)+'## Other resolutions and fresh source world\n\n[640×360](screenshots/site-options-640x360.png) · [2560×1440](screenshots/site-options-2560x1440.png) · [Fresh generated world](screenshots/fresh-generated-world.png) · [Known location selection](screenshots/known-site-map.png) · [All originals](screenshots/)\n')
