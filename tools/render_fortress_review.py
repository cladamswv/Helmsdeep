"""Inspect exported actual game geometry on CPU. Not a gameplay screenshot.
Run Godot --headless --path project --script ../tools/export_fortress_review.gd -- --test first.
Optional authoring dependencies: numpy and Pillow; not game runtime dependencies.
"""
import json
from pathlib import Path
import numpy as np
from PIL import Image,ImageDraw,ImageFont
root=Path(__file__).resolve().parents[1]
triangles=json.loads((root/'docs/fortress-geometry-review.json').read_text())
W,H=1400,950
canvas=np.zeros((H,W,3),dtype=np.uint8)
for y in range(H):canvas[y]=[int(35+y/H*10),int(56+y/H*14),int(63+y/H*10)]
zbuffer=np.full((H,W),1e9)
eye=np.array([8.8,10.2,14.5]);target=np.array([-6.8,2.9,0]);forward=target-eye;forward/=np.linalg.norm(forward);right=np.cross(forward,[0,1,0]);right/=np.linalg.norm(right);up=np.cross(right,forward)
light=np.array([.6,.85,.35]);light/=np.linalg.norm(light)
textures={p.name:np.array(Image.open(p).convert('RGB'))/255 for p in (root/'project/assets/materials').glob('*_albedo.png')}
# A geometry-derived shadow map for inspection; not a substitute for Vulkan QA.
S=1400
shadow=np.full((S,S),-1e9)
sx=np.cross(light,[0,1,0]);sx/=np.linalg.norm(sx);sy=np.cross(sx,light)
all_v=np.array([tri[:3] for tri in triangles]).reshape(-1,3)
lo=np.array([(all_v@sx).min(),(all_v@sy).min()])-.3
hi=np.array([(all_v@sx).max(),(all_v@sy).max()])+.3
ss=(S-1)/(hi-lo)
for tri in triangles:
 v=np.array(tri[:3]);px=(v@sx-lo[0])*ss[0];py=(v@sy-lo[1])*ss[1];depth=v@light
 x0=max(0,int(px.min()));x1=min(S-1,int(px.max())+1);y0=max(0,int(py.min()));y1=min(S-1,int(py.max())+1)
 den=(py[1]-py[2])*(px[0]-px[2])+(px[2]-px[1])*(py[0]-py[2])
 if x1<x0 or y1<y0 or abs(den)<1e-6:continue
 X,Y=np.meshgrid(np.arange(x0,x1+1),np.arange(y0,y1+1))
 a=((py[1]-py[2])*(X-px[2])+(px[2]-px[1])*(Y-py[2]))/den;b=((py[2]-py[0])*(X-px[2])+(px[0]-px[2])*(Y-py[2]))/den;c=1-a-b
 d=a*depth[0]+b*depth[1]+c*depth[2];area=shadow[y0:y1+1,x0:x1+1];mask=(a>=0)&(b>=0)&(c>=0)&(d>area);area[mask]=d[mask]
for tri in triangles:
 v=np.array(tri[:3]);rel=v-eye;z=rel@forward
 if min(z)<.1:continue
 x=W/2+(rel@right)/z*1450;y=H*.54-(rel@up)/z*1450
 x0=max(0,int(x.min()));x1=min(W-1,int(x.max())+1);y0=max(90,int(y.min()));y1=min(H-55,int(y.max())+1)
 if x1<x0 or y1<y0:continue
 den=(y[1]-y[2])*(x[0]-x[2])+(x[2]-x[1])*(y[0]-y[2])
 if abs(den)<1e-6:continue
 X,Y=np.meshgrid(np.arange(x0,x1+1),np.arange(y0,y1+1))
 a=((y[1]-y[2])*(X-x[2])+(x[2]-x[1])*(Y-y[2]))/den;b=((y[2]-y[0])*(X-x[2])+(x[0]-x[2])*(Y-y[2]))/den;c=1-a-b
 dep=1/(a/z[0]+b/z[1]+c/z[2]);region=zbuffer[y0:y1+1,x0:x1+1];mask=(a>=0)&(b>=0)&(c>=0)&(dep<region)
 normal=np.cross(v[1]-v[0],v[2]-v[0]);normal/=max(1e-9,np.linalg.norm(normal))
 if not mask.any():continue
 w=np.stack([a/z[0],b/z[1],c/z[2]],axis=-1)*dep[...,None];pos=w@v
 ix=np.clip(((pos@sx-lo[0])*ss[0]).astype(int),0,S-1);iy=np.clip(((pos@sy-lo[1])*ss[1]).astype(int),0,S-1)
 visibility=np.where(pos@light>=shadow[iy,ix]-.045,1.,.22)
 lit=.44+.56*abs(float(normal@light))*visibility
 color=np.broadcast_to(np.array(tri[3]),pos.shape).copy()
 tex=textures.get(tri[4] if len(tri)>4 else '')
 if tex is not None:
  axis=int(np.argmax(np.abs(normal)));uv=pos[...,[2,1] if axis==0 else ([0,2] if axis==1 else [0,1])]
  scale=1.5 if tri[4].startswith('oak') else 2.1;coords=np.floor(np.mod(uv*scale,1.0)*256).astype(int)%256
  color*=tex[coords[...,1],coords[...,0]]
 color=np.clip(color*lit[...,None]*255,0,255).astype(np.uint8)
 region[mask]=dep[mask];canvas[y0:y1+1,x0:x1+1][mask]=color[mask]
im=Image.fromarray(canvas);d=ImageDraw.Draw(im)
try:
 f=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',28);sm=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',17)
except OSError:f=sm=ImageFont.load_default()
d.text((34,24),'CASTLEHOLD  /  THE SANDSTONE CITADEL',font=f,fill='#e3c58b')
d.text((34,65),'Actual geometry and surface maps | Approximate CPU lighting, not an Android screenshot',font=sm,fill='#b6ccca')
d.text((34,910),'Arched gatehouse  |  Stone battlements  |  Layered keep  |  Enclosed courtyard',font=sm,fill='#d2c19b')
im.save(root/'docs/fortress-review.png')
print(len(triangles),'triangles inspected')
