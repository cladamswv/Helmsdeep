"""Original 512² character albedo/normal atlas. No photographs or external assets.

Broad linked mail, cloth weave, forged metal, hide and wood are authored at
offline build time. Padded tiles share one material surface per whole unit.
"""
from pathlib import Path
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1] / 'project/assets/characters'
FAMILIES = ['skin', 'cloth', 'leather', 'mail', 'steel', 'iron', 'wood', 'bone',
            'hair', 'fur', 'scale', 'stone', 'plain', 'polished', 'gold', 'plain']
FINISHES = {family:(.90,0.) for family in FAMILIES}
FINISHES.update(skin=(.76,0.), leather=(.76,0.), mail=(.70,.62),
                steel=(.52,.88), iron=(.60,.62), polished=(.36,.88), gold=(.48,.88))
TILE = 128
PAD = 10

def atlas_uv(uv, family):
    slot = FAMILIES.index(family)
    return tuple(((slot % 4 if k == 0 else slot // 4)*TILE + PAD +
                  max(0., min(1., uv[k]))*(TILE-2*PAD-1) + .5)/512 for k in range(2))

def build():
    rng = np.random.default_rng(41026)
    albedo = np.ones((512,512,3)); normals = np.zeros_like(albedo); orm=np.ones_like(albedo)
    normals[:] = [.5,.5,1]
    n = TILE-2*PAD
    y,x = np.mgrid[:n,:n]/n
    # A low-frequency field; fine details go into mipmapped normal maps.
    mottling = (np.sin(x*18+y*5)*np.sin(y*21-x*3)+np.cos(x*37+y*28)*.35)*.5
    for i, family in enumerate(FAMILIES):
        height = np.zeros((n,n)); tone = np.ones((n,n)); tint = np.ones(3)
        if family == 'skin':
            height = mottling*.04
            tone = .92 + mottling*.045 + .05*np.sin(y*np.pi)
            tint = np.array([1,.987,.966])
        elif family == 'cloth':
            thread = np.sin(x*np.pi*38)*np.sin(y*np.pi*38)
            height = thread*.06 + mottling*.025
            tone = .87 + .035*thread + .07*np.sin(x*np.pi*4)**2
        elif family == 'leather':
            height = mottling*.08 + rng.random((n,n))*.018
            seams = np.exp(-((x-.07)/.012)**2)+np.exp(-((x-.93)/.012)**2)
            tone = .86 + mottling*.075 + seams*.09
        elif family == 'mail':
            # Interlocking oval links, staggered between rows. Black holes stay
            # large enough to read without a noisy geometry ring per link.
            row = np.floor(y*12); u = (x*24 + (row%2)*.5)%1-.5
            v = (y*12)%1-.5; radius = np.sqrt((u/.42)**2+(v/.49)**2)
            ring = np.exp(-((radius-.78)/.16)**2)
            height = ring*.8
            tone = .43 + ring*(.38+.16*np.clip(-v*2,0,1))
            tint = np.array([.95,.98,1.])
        elif family in ('steel','iron','polished','gold'):
            forge = .5+.5*np.sin(x*35+y*7)*np.sin(y*31-x*4)
            hairline = np.maximum(0,np.sin(y*152+x*8)-.985)
            height = forge*.025 - hairline*.6
            tone = .91 + forge*.055 - hairline*.8
            if family == 'iron': tone = tone*.91 + mottling*.04
        elif family == 'wood':
            grain = np.sin(x*55+np.sin(y*11)*1.2)
            height = grain*.16+mottling*.06
            tone = .81 + grain*.055 + mottling*.06
            tint = np.array([1,.97,.92])
        elif family == 'bone':
            height = np.sin(x*31+y*3)*.025
            tone = .86 + .12*y + mottling*.025
        elif family in ('hair','fur'):
            height = np.sin(x*45+np.sin(y*9)*2)*.12
            tone = .83+height*.4+mottling*.07
        elif family == 'scale':
            row=np.floor(y*7);u=(x*6+(row%2)*.5)%1-.5;v=(y*7)%1
            ridge=np.clip(1-(u/.5)**2,0,1)*np.sin(v*np.pi)
            height=ridge*.6;tone=.68+ridge*.26
        elif family == 'stone':
            height=mottling*.18;tone=.86+mottling*.08
        rgb = np.clip(tone[...,None]*tint,0,1)
        dx=(np.roll(height,-1,1)-np.roll(height,1,1))*1.5
        dy=(np.roll(height,-1,0)-np.roll(height,1,0))*1.5
        nn=np.stack([-dx,-dy,np.ones_like(dx)],-1)
        nn/=np.linalg.norm(nn,axis=-1)[...,None]
        yy,xx=(i//4)*TILE,(i%4)*TILE
        albedo[yy:yy+TILE,xx:xx+TILE]=np.pad(rgb,((PAD,PAD),(PAD,PAD),(0,0)),mode='edge')
        normals[yy:yy+TILE,xx:xx+TILE]=np.pad(nn*.5+.5,((PAD,PAD),(PAD,PAD),(0,0)),mode='edge')
        rough,metal=FINISHES[family]
        orm[yy:yy+TILE,xx:xx+TILE]=[1,rough,metal]
    ROOT.mkdir(parents=True,exist_ok=True)
    Image.fromarray(np.uint8(albedo*255)).save(ROOT/'fieldcraft_albedo.png')
    Image.fromarray(np.uint8(normals*255)).save(ROOT/'fieldcraft_normal.png')
    Image.fromarray(np.uint8(orm*255)).save(ROOT/'fieldcraft_orm.png')
    print('Baked original 512² character albedo and normal atlases.')

def preview_albedo(model, indices, weights, texture):
    """Same authored UVs in the CPU review; normal lighting is approximate."""
    uv = np.array([atlas_uv(model.uvs[j],model.surface_names[j]) for j in indices])
    p = np.clip((weights@uv*512).astype(int),0,511)
    return (weights@np.array([model.colors[j][:3] for j in indices]))*texture[p[...,1],p[...,0]]

if __name__ == '__main__': build()
