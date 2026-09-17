"""Render actual authored, posed geometry on CPU; not a game screenshot."""
from build_bosses import BossModel as Model
import numpy as np
from PIL import Image,ImageDraw,ImageFont
from pathlib import Path
from build_character_surfaces import preview_albedo, FINISHES
texture=np.asarray(Image.open(Path(__file__).resolve().parents[1]/"project/assets/characters/fieldcraft_albedo.png").convert("RGB"))/255.0
import argparse
args=argparse.ArgumentParser()
args.add_argument('--contact',action='store_true');args.add_argument('--output',default='docs/siege-bosses-review.png')
options=args.parse_args()
W,H=2048,2048
canvas=np.zeros((H,W,3),dtype=np.uint8)
for y in range(H):canvas[y]=np.array([33,45,55])+(y/H)*np.array([15,16,14])
zbuf=np.full((H,W),1e9);light=np.array([-1,1.5,-2]);light/=np.linalg.norm(light)
for index,kind in enumerate(['boss_gatebreaker','boss_dreadscale','boss_ashcaller','boss_ironjaw']):
 col=index%2;row=index//2
 m=Model(kind).build();local=np.array(m.verts);norms=np.array(m.norm);colors=np.array(m.colors)[:,:3];transforms=[]
 pose=m.ready()
 if options.contact:
  clip=next(c for c in m.animation_specs() if c[0]==('shoot' if kind=='boss_ashcaller' else 'attack_a'))
  pose={b:values[2] for b,values in clip[2].items()}
 for b,(_,p,t) in enumerate(m.bones):
  x,y,z,w=m.quaternion(pose.get(b,(0,0,0)));mat=np.eye(4)
  mat[:3,:3]=[[1-2*y*y-2*z*z,2*x*y-2*z*w,2*x*z+2*y*w],[2*x*y+2*z*w,1-2*x*x-2*z*z,2*y*z-2*x*w],[2*x*z-2*y*w,2*y*z+2*x*w,1-2*x*x-2*y*y]];mat[:3,3]=t
  transforms.append((transforms[p]@mat) if p>=0 else mat)
 verts=local.copy()
 for b in range(len(m.bones)):
  mask=np.array(m.joints)[:,0]==b;v=local[mask]-np.array(m.world[b]);verts[mask]=v@transforms[b][:3,:3].T+transforms[b][:3,3];norms[mask]=norms[mask]@transforms[b][:3,:3].T
 eye=np.array([8.3,6.7,-14.3]);target=np.array([0,3.1,0]);forward=target-eye;forward/=np.linalg.norm(forward);right=np.cross(forward,[0,1,0]);right/=np.linalg.norm(right);up=np.cross(right,forward)
 rel=verts-eye;z=rel@forward;xx=rel@right;yy=rel@up
 scale=1470;px=(col+.5)*1024+xx/z*scale;py=row*925+575-yy/z*scale

 for i in range(0,len(verts),3):
  x=px[i:i+3];y=py[i:i+3];zz=z[i:i+3]
  x0=max(col*1024,int(np.floor(x.min())));x1=min((col+1)*1024-1,int(np.ceil(x.max())));y0=max(row*925+150,int(np.floor(y.min())));y1=min(row*925+963,int(np.ceil(y.max())))
  if x1<x0 or y1<y0:continue
  den=(y[1]-y[2])*(x[0]-x[2])+(x[2]-x[1])*(y[0]-y[2])
  if abs(den)<1e-6:continue
  X,Y=np.meshgrid(np.arange(x0,x1+1),np.arange(y0,y1+1));a=((y[1]-y[2])*(X-x[2])+(x[2]-x[1])*(Y-y[2]))/den;b=((y[2]-y[0])*(X-x[2])+(x[0]-x[2])*(Y-y[2]))/den;c=1-a-b
  dep=1/(a/zz[0]+b/zz[1]+c/zz[2]);region=zbuf[y0:y1+1,x0:x1+1];mask=(a>=0)&(b>=0)&(c>=0)&(dep<region)
  if not mask.any():continue
  weights=np.stack([a/zz[0],b/zz[1],c/zz[2]],axis=-1)*dep[...,None]
  n=weights@norms[i:i+3];n/=np.maximum(1e-8,np.linalg.norm(n,axis=-1))[...,None]
  face=np.cross(verts[i+1]-verts[i],verts[i+2]-verts[i])
  if face@(eye-verts[i])<0:n=-n
  rough,metal=FINISHES[m.surface_names[i]]
  diffuse=.31+.18*np.clip(n[...,1],0,1)+.59*np.clip(n@light,0,1)
  halfvec=light-forward;halfvec/=np.linalg.norm(halfvec)
  spec=np.clip(n@halfvec,0,1)**(10+48*(1-rough))*(.14+.7*metal)
  rim=(1-np.clip(n@(-forward),0,1))**3*.12
  rgb=np.clip((preview_albedo(m,range(i,i+3),weights,texture)*diffuse[...,None]+spec[...,None]*np.array([1,.93,.79])+rim[...,None]*np.array([.44,.66,.78]))*255,0,255).astype(np.uint8)
  region[mask]=dep[mask];canvas[y0:y1+1,x0:x1+1][mask]=rgb[mask]
img=Image.fromarray(canvas);d=ImageDraw.Draw(img)
f=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',27);sm=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',20)
d.text((38,26),'CASTLEHOLD  /  SIEGE BOSSES',font=f,fill='#efcc89')
d.text((38,77),'Actual rigged game meshes • CPU material preview • Device lighting still needs review',font=sm,fill='#c0ccd1')
for i,(name,desc) in enumerate([
 ('25 / THE GATEBREAKER','Cyclops siege ogre • stone maul • crushing shockwave'),
 ('50 / DREADSCALE RIDER','Ogre warlord • armored siege lizard • tail sweep'),
 ('75 / THE ASHCALLER','Ogre high shaman • ember brazier • firestorm'),
 ('100 / THE IRONJAW KING','Ogre king • horned tyrant dinosaur • reinforcement roar')]):
 x=(i%2)*1024+38;y=(i//2)*925+983
 d.text((x,y),name,font=f,fill='#efcc89');d.text((x,y+45),desc,font=sm,fill='#c0ccd1')
img.save(Path(__file__).resolve().parents[1]/options.output)
