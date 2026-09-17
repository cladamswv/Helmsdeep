"""Assemble reproducible CPU inspections of the actual shipped assets.
Run the fortress and character review exporters first; no concept art is used.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parents[1]
W=1600
rows=[('fortress-review.png',(0,125,1400,897)),
      ('medieval-troops-review.png',(0,165,1920,987)),
      ('tusk-and-ember-review.png',(0,255,1920,1160))]
parts=[]
for name,box in rows:
    part=Image.open(ROOT/'docs'/name).convert('RGB').crop(box)
    parts.append(part.resize((W,round(part.height*W/part.width)),Image.Resampling.LANCZOS))
canvas=Image.new('RGB',(W,150+sum(p.height for p in parts)+60),'#202e38')
d=ImageDraw.Draw(canvas)
font='/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
title=ImageFont.truetype(font,42);small=ImageFont.truetype(font,23)
d.text((38,29),'CASTLEHOLD  /  STONE & STEEL',font=title,fill='#e8c588')
d.text((38,91),'Actual game meshes and textures • CPU preview; Android lighting needs device review',font=small,fill='#bcccd0')
y=150
for part in parts:
    canvas.paste(part,(0,y));d.line((0,y,W,y),fill='#a08760',width=2);y+=part.height
d.text((38,y+17),'Finer brown masonry  •  Textured medieval armor  •  Sculpted ogres and mounts',font=small,fill='#d7c4a0')
out=ROOT/'docs/stone-and-steel-review.png';canvas.save(out)
print(out)
