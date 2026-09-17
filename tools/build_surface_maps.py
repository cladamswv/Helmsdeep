"""Bake deterministic, original surface noise for the game's 3D materials.
Offline authoring only: numpy/Pillow. No photographs or downloaded textures.
"""
from pathlib import Path
import numpy as np
from PIL import Image

OUT=Path(__file__).resolve().parents[1]/'project/assets/materials'
OUT.mkdir(parents=True,exist_ok=True)
N=256
rng=np.random.default_rng(671)
y,x=np.mgrid[:N,:N]/N

def noise(cells):
    a=rng.random((cells,cells));u=x*cells;v=y*cells
    i=u.astype(int);j=v.astype(int);u=u-i;v=v-j
    u=u*u*(3-2*u);v=v*v*(3-2*v)
    return (a[j%cells,i%cells]*(1-u)+a[j%cells,(i+1)%cells]*u)*(1-v)+(a[(j+1)%cells,i%cells]*(1-u)+a[(j+1)%cells,(i+1)%cells]*u)*v

def save(name,height,albedo,strength):
    Image.fromarray(np.uint8(np.clip(albedo,0,1)*255),'RGB').save(OUT/(name+'_albedo.png'))
    dx=(np.roll(height,-1,axis=1)-np.roll(height,1,axis=1))*strength
    dy=(np.roll(height,-1,axis=0)-np.roll(height,1,axis=0))*strength
    normal=np.stack([-dx,-dy,np.ones_like(dx)],axis=-1)
    normal/=np.linalg.norm(normal,axis=-1)[...,None]
    Image.fromarray(np.uint8(np.clip(normal*.5+.5,0,1)*255),'RGB').save(OUT/(name+'_normal.png'))

fine=noise(64);pits=np.maximum(0,fine-.64)*2.4
stone=.46*noise(5)+.29*noise(17)+.17*noise(43)+.08*fine-pits*.18
tone=.78+.22*stone-pits*.08
save('sandstone',stone,np.stack([tone,tone*.987,tone*.959],axis=-1),2.4)
grain=np.sin(x*np.pi*40+noise(8)*3.5+np.sin(y*np.pi*2)*1.4)*.5+.5
wood=.46*grain+.26*noise(16)+.18*noise(32)+.10*noise(3)
tone=.67+.31*wood
save('oak',wood,np.stack([tone,tone*.95,tone*.86],axis=-1),1.2)
slate=.48*noise(8)+.36*noise(32)+.16*noise(64)
tone=.77+.21*slate
save('slate',slate,np.stack([tone*.93,tone*.97,tone],axis=-1),1.8)
print('Baked six seamless 256² albedo/normal maps.')

# Analytic alpha fields for short-lived dust and soft contact shadows.
radius=np.sqrt(((x-.5)*2)**2+((y-.5)*2)**2)
alpha=np.clip(1-radius,0,1)**2
shadow=np.zeros((N,N,4),dtype=np.uint8);shadow[:,:,:3]=[25,28,21];shadow[:,:,3]=np.uint8(alpha*155)
Image.fromarray(shadow,'RGBA').save(OUT/'contact_shadow.png')
dust=np.full((N,N,4),255,dtype=np.uint8);dust[:,:,3]=np.uint8(alpha*(.76+noise(9)*.24)*200)
Image.fromarray(dust,'RGBA').save(OUT/'dust_soft.png')
