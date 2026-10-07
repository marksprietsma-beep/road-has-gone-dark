"""Compose unretouched Godot screenshots into review sheets; originals remain intact."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

root = Path(__file__).parent
font = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 18)
groups = {
    'onboarding': [('Main menu','origin','main-menu'),('State selection','origin','state'),
                   ('Hometown selection','origin','hometown-choice'),('Party creation','origin','party-creation'),
                   ('Party ready','origin','party-ready')],
    'expedition': [('Hometown','expedition','hometown'),('Lead detail','expedition','lead'),
                   ('Local map after scouting','expedition','rumour-discovered'),('Site choices','expedition','site-options'),
                   ('Consequence','expedition','consequence'),('Return','expedition','returned-hometown')],
}
lines = ['# Actual Godot before/after review', '',
         'Baseline GAME-84 and GAME-83 were rendered with Godot 4.6.3 on Linux software GL. '
         'The sheets resize and arrange original captures only. Names/backgrounds in origin-created parties '
         'can differ because each actual New Game creates an independent save. Expedition comparisons use '
         'copies of the same prior campaign fixtures and the same action sequence.', '']
for group, rows in groups.items():
    sheet = Image.new('RGB', (1280, 40+len(rows)*392), '#080908')
    draw = ImageDraw.Draw(sheet)
    draw.text((12,10),'BEFORE · GAME-84',font=font,fill='#e9c66d')
    draw.text((652,10),'AFTER · GAME-83',font=font,fill='#e9c66d')
    for i,(title,folder,name) in enumerate(rows):
        y = 40+i*392
        draw.text((12,y+5),title,font=font,fill='#ded8c8')
        for column,stage in enumerate(['before','after']):
            image = Image.open(root/stage/folder/(name+'-1280x720.png')).convert('RGB')
            assert image.size in [(1280,720),(1280,719)]
            sheet.paste(image.resize((640,360),Image.Resampling.LANCZOS),(column*640,y+32))
    sheet.save(root/(group+'-comparison.png'))
    lines += [f'![{group} comparison]({group}-comparison.png)', '',
              '| Screen | 640×360 after | 1280×720 after | 2560×1440 after |',
              '| --- | --- | --- | --- |']
    for title,folder,name in rows:
        links = [f'[Original](after/{folder}/{name}-{resolution}.png)' for resolution in ['640x360','1280x720','2560x1440']]
        lines.append('| '+title+' | '+' | '.join(links)+' |')
    lines.append('')
lines += ['[All baseline captures](before/) · [All final captures](after/)', '',
          'Filenames identify physical window sizes. The responsive 1280×720 window has a 1280×719 rendered viewport due to integer logical-canvas rounding; the original texture is preserved without padding. Exact raster dimensions and hashes are recorded in review-proof.json.', '',
          'Windows native execution and laptop visual review are distinct; use the complete build for the latter.']
(root/'SCREENSHOTS.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
