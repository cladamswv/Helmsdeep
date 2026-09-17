"""Render actual authored, posed geometry on CPU; not a game screenshot."""
from build_horde import HordeModel as Model
import numpy as np
from PIL import Image,ImageDraw,ImageFont
from pathlib import Path
from build_character_surfaces import preview_albedo, FINISHES
texture=np.asarray(Image.open(Path(__file__).resolve().parents[1]/"project/assets/characters/fieldcraft_albedo.png").convert("RGB"))/255.0
W,H=1920,1380
canvas=np.zeros((H,W,3),dtype=np.uint8)
for y in range(H):canvas[y]=np.array([33,45,55])+(y/H)*np.array([15,16,14])
zbuf=np.full((H,W),1e9);light=np.array([-1,1.5,-2]);light/=np.linalg.norm(light)
for index,kind in enumerate(['raider','enemy_archer','enemy_spearman','orc_guard','mounted_raider','ogre']):
 col=index%3;row=index//3
 m=Model(kind).build();local=np.array(m.verts);norms=np.array(m.norm);colors=np.array(m.colors)[:,:3];transforms=[]
 for b,(_,p,t) in enumerate(m.bones):
  x,y,z,w=m.quaternion(m.ready().get(b,(0,0,0)));mat=np.eye(4)
  mat[:3,:3]=[[1-2*y*y-2*z*z,2*x*y-2*z*w,2*x*z+2*y*w],[2*x*y+2*z*w,1-2*x*x-2*z*z,2*y*z-2*x*w],[2*x*z-2*y*w,2*y*z+2*x*w,1-2*x*x-2*y*y]];mat[:3,3]=t
  transforms.append((transforms[p]@mat) if p>=0 else mat)
 verts=local.copy()
 for b in range(len(m.bones)):
  mask=np.array(m.joints)[:,0]==b;v=local[mask]-np.array(m.world[b]);verts[mask]=v@transforms[b][:3,:3].T+transforms[b][:3,3];norms[mask]=norms[mask]@transforms[b][:3,:3].T
 eye=np.array([2.8,2.6,-6.2] if kind not in ['mounted_raider','ogre'] else [4.2,3.3,-7.4]);target=np.array([0,1.55 if kind!='ogre' else 1.7,0]);forward=target-eye;forward/=np.linalg.norm(forward);right=np.cross(forward,[0,1,0]);right/=np.linalg.norm(right);up=np.cross(right,forward)
 rel=verts-eye;z=rel@forward;xx=rel@right;yy=rel@up
 scale=1150 if kind=='ogre' else (1100 if kind!='mounted_raider' else 1030);px=(col+.5)*640+xx/z*scale;py=(385 if kind=='ogre' else 405)+row*630-yy/z*scale
 for i in range(0,len(verts),3):
  x=px[i:i+3];y=py[i:i+3];zz=z[i:i+3]
  x0=max(col*640,int(np.floor(x.min())));x1=min((col+1)*640-1,int(np.ceil(x.max())));y0=max(130+row*630,int(np.floor(y.min())));y1=min(620+row*630,int(np.ceil(y.max())))
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
f=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',32);sm=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',20)
d.text((38,26),'CASTLEHOLD  /  THE IRONROOT HORDE',font=f,fill='#efcc89');d.text((38,77),'Actual articulated models • CPU material preview; lighting is approximate, not an Android screenshot',font=sm,fill='#c0ccd1')
for i,(name,desc) in enumerate([
 ('ORC MARAUDER','Tusks · cleaver axe · rough shield'),
 ('ORC HUNTER','Pointed ears · war bow · quiver'),
 ('ORC IMPALER','Hooked spear · horned iron helm'),
 ('IRONSHIELD ORC','Tower shield · arrow resistance'),
 ('WARG RIDER','Fanged mount · flank attacks'),
 ('SIEGE OGRE','Heavy club · gate smashes · area hits')]):
 x=(i%3)*640+32;y=651+(i//3)*630
 d.text((x,y),name,font=f,fill='#efcc89');d.text((x,y+47),desc,font=sm,fill='#c0ccd1')
img.save(Path(__file__).resolve().parents[1]/'docs/orc-horde-review.png')
