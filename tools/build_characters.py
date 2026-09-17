"""Original medieval characters, articulated mounts and glTF 2.0 animations.
No downloaded geometry. Authoring is deterministic and uses the Python stdlib.
"""
import json, math, struct, pathlib, zlib, hashlib
ROOT=pathlib.Path(__file__).resolve().parents[1]/'project/assets/characters'
def color(hex):
 return tuple(int(hex[i:i+2],16)/255 for i in (0,2,4))+(1,)
class Model:
 def __init__(self,kind):
  self.kind=kind; self.mounted=kind in ('knight','mounted_raider');self.enemy=kind in ('raider','enemy_archer','enemy_spearman','mounted_raider')
  self.archer=kind in ('archer','enemy_archer');self.spear=kind in ('spearman','enemy_spearman')
  self.verts=[];self.norm=[];self.joints=[];self.colors=[];self.uvs=[];self.surface_names=[]
  self.finishes={};self.surfaces={}
  self.bones=[('root',-1,(0,0,0)),('hips',0,(0,1.92 if self.mounted else .94,.10 if self.mounted else 0)),('chest',1,(0,.38,0)),('head',2,(0,.43,0)),('upper_arm_L',2,(-.37,.18,0)),('forearm_L',4,(0,-.30,0)),('hand_L',5,(0,-.24,0)),('upper_arm_R',2,(.37,.18,0)),('forearm_R',7,(0,-.30,0)),('hand_R',8,(0,-.24,0)),('thigh_L',1,(-.29 if self.mounted else -.16,-.06,0)),('shin_L',10,(0,-.39,0)),('foot_L',11,(0,-.37,0)),('thigh_R',1,(.29 if self.mounted else .16,-.06,0)),('shin_R',13,(0,-.39,0)),('foot_R',14,(0,-.37,0)),('neck',2,(0,.30,0)),('jaw',3,(0,-.14,-.06)),('thumb_L',6,(.06,0,-.02)),('thumb_R',9,(-.06,0,-.02)),('toe_L',12,(0,-.01,-.13)),('toe_R',15,(0,-.01,-.13)),('plume',3,(0,.25,.06)),('tabard',1,(0,-.14,-.19))]
  if self.mounted:
   self.bones += [('horse_body',0,(0,1.03,.12)),('horse_neck',24,(0,.12,-.61)),('horse_head',25,(0,.59,-.19)),('horse_tail',24,(0,.13,.72)),('front_leg_L',24,(-.29,-.06,-.47)),('front_knee_L',28,(0,-.46,0)),('front_leg_R',24,(.29,-.06,-.47)),('front_knee_R',30,(0,-.46,0)),('hind_leg_L',24,(-.30,-.04,.50)),('hind_knee_L',32,(0,-.46,.02)),('hind_leg_R',24,(.30,-.04,.50)),('hind_knee_R',34,(0,-.46,.02))]
  self.world=[]
  for _,p,t in self.bones:self.world.append(tuple(t[i]+(self.world[p][i] if p>=0 else 0) for i in range(3)))
 def tri(self,a,b,c,col,bone,uv=None):
  u=[b[i]-a[i] for i in range(3)];v=[c[i]-a[i] for i in range(3)];n=[u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0]];l=math.sqrt(sum(x*x for x in n)) or 1
  axes=[k for k in range(3) if k!=max(range(3),key=lambda k:abs(n[k]))]
  for j,pt in enumerate((a,b,c)):
   self.verts.append(pt);self.norm.append([x/l for x in n]);self.colors.append(col);self.joints.append((bone,0,0,0))
   self.uvs.append(uv[j] if uv else tuple(.5+(pt[k]-self.world[bone][k])*.5 for k in axes))
   finish=self.finishes.get(col,(.94,0.))
   self.surface_names.append(self.surfaces.get(col,'steel' if finish[1]>.5 else 'plain'))
 def soften(self,start,end):
  # Weld normals only inside one sculpted part. Weapon edges remain crisp.
  sums={}
  for i in range(start,end):
   key=tuple(round(v,6) for v in self.verts[i]);s=sums.setdefault(key,[0.,0.,0.])
   for k in range(3):s[k]+=self.norm[i][k]
  for i in range(start,end):
   s=sums[tuple(round(v,6) for v in self.verts[i])];ln=math.sqrt(sum(v*v for v in s)) or 1
   self.norm[i]=[v/ln for v in s]
 def loft(self,rings,col,bone=0,n=10,smooth=True):
  w=self.world[bone];rr=[]
  for y,rx,rz,x,z in rings:rr.append([(w[0]+x+rx*math.cos(i*math.tau/n),w[1]+y,w[2]+z+rz*math.sin(i*math.tau/n)) for i in range(n)])
  start=len(self.verts)
  for row,(a,b) in enumerate(zip(rr,rr[1:])):
   v=row/(len(rr)-1);vv=(row+1)/(len(rr)-1)
   for i in range(n):
    j=(i+1)%n;u=i/n;uu=(i+1)/n
    self.tri(a[i],b[i],b[j],col,bone,[(u,v),(u,vv),(uu,vv)])
    self.tri(a[i],b[j],a[j],col,bone,[(u,v),(uu,vv),(uu,v)])
  if smooth:self.soften(start,len(self.verts))
  for ring,flip in [(rr[0],True),(rr[-1],False)]:
   center=tuple(sum(p[i] for p in ring)/n for i in range(3))
   for i in range(n):
    a,b=ring[i],ring[(i+1)%n];self.tri(center,a,b,col,bone) if flip else self.tri(center,b,a,col,bone)
 def ell(self,c,r,col,bone=0,n=10):
  rings=8 if n>=14 else 6
  self.loft([(c[1]+r[1]*math.sin(a),r[0]*max(.025,math.cos(a)),r[2]*max(.025,math.cos(a)),c[0],c[2]) for a in [-math.pi/2+j*math.pi/rings for j in range(rings+1)]],col,bone,n)
 def bar(self,c,size,col,bone=0):
  x,y,z=c;rx,ry,rz=[a/2 for a in size];w=self.world[bone]
  v=[(w[0]+x+dx*rx,w[1]+y+dy*ry,w[2]+z+dz*rz) for dx,dy,dz in [(-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]]
  for f in [(0,3,2,1),(4,5,6,7),(0,4,7,3),(1,2,6,5),(0,1,5,4),(3,7,6,2)]:
   self.tri(v[f[0]],v[f[1]],v[f[2]],col,bone);self.tri(v[f[0]],v[f[2]],v[f[3]],col,bone)
 def tube(self,a,b,r,col,bone=0,n=7):
  d=[b[i]-a[i] for i in range(3)];ln=math.sqrt(sum(x*x for x in d));d=[x/ln for x in d];seed=[1,0,0] if abs(d[0])<.8 else [0,1,0]
  u=[d[1]*seed[2]-d[2]*seed[1],d[2]*seed[0]-d[0]*seed[2],d[0]*seed[1]-d[1]*seed[0]];ln=math.sqrt(sum(x*x for x in u));u=[x/ln for x in u];v=[d[1]*u[2]-d[2]*u[1],d[2]*u[0]-d[0]*u[2],d[0]*u[1]-d[1]*u[0]];w=self.world[bone]
  rr=[[(w[k]+p[k]+r*(u[k]*math.cos(j*math.tau/n)+v[k]*math.sin(j*math.tau/n))) for k in range(3)] for p in (a,b) for j in range(n)]
  start=len(self.verts)
  for j in range(n):
   q=(j+1)%n;u=j/n;uu=(j+1)/n
   self.tri(rr[j],rr[n+j],rr[n+q],col,bone,[(u,0),(u,1),(uu,1)])
   self.tri(rr[j],rr[n+q],rr[q],col,bone,[(u,0),(uu,1),(uu,0)])
  self.soften(start,len(self.verts))
 def plate(self,outline,z,thickness,col,bone=0):
  w=self.world[bone];N=len(outline);v=[(w[0]+x,w[1]+y,w[2]+zz) for zz in (z-thickness/2,z+thickness/2) for x,y in outline]
  center=(sum(p[0] for p in v[:N])/N,sum(p[1] for p in v[:N])/N,w[2]+z-thickness/2)
  back=(center[0],center[1],w[2]+z+thickness/2)
  for i in range(N):
   j=(i+1)%N;self.tri(center,v[j],v[i],col,bone);self.tri(back,v[N+i],v[N+j],col,bone);self.tri(v[i],v[j],v[N+j],col,bone);self.tri(v[i],v[N+j],v[N+i],col,bone)
 def drape(self,center,width,height,col,bone,side=False):
  # Sculpted cloth with broad folds and a shaped hem, skinned to its owner.
  w=self.world[bone];grid=[];start=len(self.verts)
  for j in range(7):
   row=[];t=j/6
   for i in range(9):
    u=i/8;fold=math.sin(u*math.tau*2.5)*.025*(.3+t)
    x=(u-.5)*width*(.82+.18*t);y=-t*height+(.028*math.cos(u*math.tau*2) if j==6 else 0);z=fold+.035*t*t
    if side:x,z=z,x
    row.append(tuple(w[k]+center[k]+(x,y,z)[k] for k in range(3)))
   grid.append(row)
  for j in range(6):
   for i in range(8):
    self.tri(grid[j][i],grid[j+1][i+1],grid[j+1][i],col,bone,[(i/8,j/6),((i+1)/8,(j+1)/6),(i/8,(j+1)/6)])
    self.tri(grid[j][i],grid[j][i+1],grid[j+1][i+1],col,bone,[(i/8,j/6),((i+1)/8,j/6),((i+1)/8,(j+1)/6)])
  self.soften(start,len(self.verts))
 def build(self):
  enemy=self.enemy;archer=self.archer;knight=self.mounted
  cloth=color('983e2e' if enemy else '1e6387');steel=color('697077' if enemy else '8d9eaa');edge=color('bdcbd0');dark=color('202b37');mail=color('7b8c97');leather=color('64432c');gold=color('c59b59');skin=color('bd8055' if enemy else ('d8a075' if archer else 'c98e66'));ivory=color('efdfb5')
  self.surfaces.update({cloth:'cloth',steel:'steel',edge:'polished',mail:'mail',leather:'leather',gold:'gold',skin:'skin',ivory:'bone'})
  wood=color('ad844d');self.surfaces[wood]='wood'
  # One draw surface with an ORM lookup atlas: no per-soldier material explosion.
  for col in [steel,edge,gold,mail]:self.finishes[col]=(.30 if col==edge else .52,.88 if col!=mail else .62)
  self.finishes[skin]=(.76,0.0);self.finishes[leather]=(.76,0.0)
  # A flared surcoat and broad mail shoulders; no uniform trousers or brimmed modern helmet.
  self.loft([(-.24,.30,.20,0,0),(.08,.26,.18,0,0),(.35,.34,.22,0,0),(.44,.27,.17,0,0)],mail if not archer else leather,1,12)
  self.loft([(-.30,.35,.24,0,0),(-.02,.27,.19,0,0)],cloth,1,12)
  for x in [-.125,.125]:
   self.drape((x,-.13,-.25),.235,.44,cloth,1)
   self.drape((x,-.50,-.256),.237,.044,ivory if not enemy else leather,1)
  self.drape((0,.35,-.23),.38,.53,cloth,1)
  self.plate([(-.07,.22),(-.07,.10),(0,.05),(.07,.10),(.07,.22),(.02,.22),(.02,.17),(-.02,.17),(-.02,.22)],-.255,.014,ivory,1)
  self.loft([(-.04,.28,.204,0,0),(.035,.28,.204,0,0)],leather,1,12);self.bar((0,0,-.215),(.13,.09,.055),gold,1)
  if knight:
   self.loft([(-.25,.25,.19,0,-.025),(.08,.35,.235,0,-.025),(.23,.27,.19,0,-.025)],steel,2,12)
   self.bar((0,-.02,-.26),(.045,.39,.045),gold,2)
  elif not archer:
   # A shaped gorget replaces rows of toy-like beads across the chest.
   self.loft([(.01,.31,.218,0,0),(.13,.32,.218,0,0),(.25,.19,.16,0,0)],steel,2,14)
   self.loft([(.11,.322,.221,0,0),(.145,.315,.215,0,0)],gold if not enemy else mail,2,14)
  self.loft([(.25,.14,.13,0,0),(.32,.14,.13,0,0)],mail,2)
  # Face and features remain readable under the helmet or hood opening.
  self.loft([(-.225,.095,.11,0,-.035),(-.16,.17,.16,0,-.03),(-.035,.195,.176,0,-.025),(.11,.192,.18,0,-.018),(.22,.125,.12,0,0)],skin,3,16)
  self.loft([(-.075,.047,.045,0,-.184),(-.038,.05,.050,0,-.204),(.075,.021,.022,0,-.19)],skin,3,8)
  for x in [-.092,.092]:
   self.ell((x,.04,-.185),(.047,.024,.018),color('925d41'),3,n=10)
   self.ell((x,.04,-.199),(.041,.014,.008),ivory,3,n=10);self.ell((x,.04,-.207),(.017,.014,.006),dark,3,n=8)
   self.tube((x-.044,.079,-.194),(x+.040,.069 if x<0 else .087,-.194),.013,leather,3,n=6)
   self.ell((x*2.2,-.03,0),(.044,.07,.045),skin,3)
  self.tube((-.039,-.128,-.182),(.039,-.122,-.185),.008,color('8d513b'),3,n=6)
  self.ell((0,-.178,-.137),(.079,.042,.034),skin,3,n=12)
  if archer:
   hood=color('506239' if enemy else '22635d')
   self.surfaces[hood]='cloth'
   self.loft([(-.18,.235,.19,0,.07),(.13,.251,.22,0,.065),(.29,.21,.18,0,.08),(.36,.10,.10,0,.13),(.39,.025,.025,0,.17)],hood,3,16)
   # Face sits in front of the hood; shaped rolled opening, pointed rear cowl.
   for side in [-1,1]:
    self.tube((side*.21,-.16,-.09),(side*.23,.10,-.12),.028,hood,3)
    self.tube((side*.23,.10,-.12),(side*.14,.23,-.12),.028,hood,3)
   for x in [-.12,-.055,.025,.095]:self.plate([(x-.045,.17),(x+.035,.19),(x+.018,.091)],-.187,.027,leather,3)
   self.loft([(.06,.32,.24,0,.07),(.28,.15,.13,0,.08)],hood,2,12)
   self.tube((-.26,.21,-.23),(.23,-.23,-.22),.043,leather,2)
   self.loft([(-.30,.115,.12,-.24,.25),(.27,.13,.13,-.24,.25)],leather,2)
   for j in range(5):
    x=-.31+j*.035;self.tube((x,.05,.25),(x,.60,.25),.012,gold,2)
    self.plate([(x-.025,.48),(x-.025,.58),(x+.025,.64),(x+.025,.51)],.25,.018,ivory,2)
  elif knight:
   self.loft([(-.21,.21,.19,0,0),(-.04,.26,.23,0,0),(.20,.25,.23,0,0),(.32,.18,.17,0,.015),(.36,.07,.07,0,.02)],steel,3,16)
   self.plate([(-.225,.14),(.225,.14),(.20,-.15),(0,-.24),(-.20,-.15)],-.235,.06,edge,3)
   for x in [-.115,.115]:self.bar((x,.06,-.275),(.185,.033,.012),dark,3)
   self.bar((0,-.035,-.28),(.037,.28,.027),gold,3)
   for x in [-.14,-.075,.075,.14]:
    for y in [-.035,-.093]:self.ell((x,y,-.274),(.017,.012,.009),dark,3,n=6)
   self.loft([(-.01,.065,.11,0,0),(.16,.10,.19,0,.06),(.36,.095,.24,0,.15),(.47,.027,.18,0,.31)],color('bd433e'),22,14)
   for k in range(5):self.tube((.055-k*.014,.16,.09),(.024-k*.012,.43,.36),.011,color('e26951'),22,n=5)
  else:
   # Medieval conical nasal helm; the tall ridge and nose guard are intentional.
   self.loft([(.065,.238,.215,0,.01),(.21,.218,.19,0,.01),(.33,.135,.12,0,.025),(.40,.035,.035,0,.025)],steel,3,16)
   self.loft([(.055,.244,.222,0,.01),(.105,.244,.222,0,.01)],gold if not enemy else mail,3,12)
   self.bar((0,-.005,-.23),(.05,.27,.045),edge,3)
   # Hanging mail aventail, shaped around the exposed face.
   for x in [-.209,.209]:
    self.drape((x,.06,.04),.19,.33,mail,3,side=True)
   if not self.spear and not enemy:
    # A short sculpted beard gives the swordsman a different portrait from the archer.
    beard=color('60412f');self.surfaces[beard]='hair'
    self.loft([(-.30,.042,.025,0,-.18),(-.21,.112,.068,0,-.16),(-.135,.127,.060,0,-.16)],beard,3,14)
    for side in [-1,1]:self.tube((side*.012,-.108,-.212),(side*.072,-.130,-.216),.020,beard,3,8)
   if self.spear:
    for side in [-1,1]:self.plate([(side*.12,-.10),(side*.22,.065),(side*.235,-.16),(side*.12,-.20)],-.115,.036,steel,3)
   if enemy:
    self.loft([(-.32,.05,.065,0,-.14),(-.17,.17,.12,0,-.15),(-.11,.19,.10,0,-.11)],color('633b24'),3,10)
    for x in [-.21,.21]:self.loft([(-.39,.04,.05,x,.02),(-.10,.054,.06,x,.02)],color('93622f'),3)
  for upper,fore,hand in [(4,5,6),(7,8,9)]:
   self.loft([(-.29,.085,.09,0,0),(-.16,.12,.115,0,0),(.04,.15,.14,0,0)],cloth if archer else mail,upper,12)
   if not archer:
    for i in range(3 if knight else 2):
     # Overlapping hammered plates have a crowned top and flared lower lip.
     y=.065-i*.072;side=.035 if upper==7 else -.035;r=.225 if knight else .187
     self.loft([(y-.10,r,.18,side,0),(y-.06,r*1.08,.195,side,0),(y+.025,r*.76,.155,side,.02),(y+.06,r*.35,.09,side,.02)],steel,upper,12)
     self.loft([(y-.101,r*1.012,.184,side,0),(y-.082,r*1.055,.190,side,0)],gold,upper,12)
    for x in [-.10,.10]:self.ell((x,.004,-.184),(.018,.018,.012),gold,upper,6)
   self.loft([(-.22,.074,.085,0,0),(.015,.10,.11,0,0)],leather if archer else steel,fore)
   self.ell((0,-.025,-.015),(.09,.10,.095),steel if knight else skin,hand)
   # Curled fingers and a separate thumb make the grip read as a real hand.
   for x in [-.056,-.020,.020,.056]:self.ell((x,-.078,-.065),(.019,.043,.033),steel if knight else skin,hand,6)
   self.ell((.083 if hand==6 else -.083,-.01,-.054),(.032,.056,.040),steel if knight else skin,hand,8)
   for y in [-.18,-.04]:self.loft([(y,.087,.10,0,0),(y+.03,.087,.10,0,0)],gold if not enemy else leather,fore,n=8)
  for thigh,shin,foot in [(10,11,12),(13,14,15)]:
   self.loft([(-.36,.10,.11,0,0),(.015,.135,.135,0,0)],mail if not archer else leather,thigh)
   self.loft([(-.33,.087,.10,0,0),(.005,.11,.115,0,0)],steel if knight else leather,shin)
   self.ell((0,0,-.045),(.13,.105,.095),steel if not archer else leather,shin)
   self.ell((0,-.015,-.10),(.115,.092,.22),steel if knight else leather,foot)
  if archer:
   # On the near hand for the game's camera: a thick 1.65 m recurved longbow.
   points=[(0,-.88,.38),(0,-.71,.21),(0,-.47,.07),(0,0,0),(0,.47,.07),(0,.71,.21),(0,.88,.38)]
   for a,b in zip(points,points[1:]):self.tube(a,b,.038,wood,9,n=8)
   self.tube(points[0],points[-1],.009,ivory,9,n=5)
   self.tube((0,-.12,0),(0,.12,0),.056,leather,9)
   self.tube((0,.035,.23),(0,.035,-1.02),.016,ivory,6,n=6)
   self.plate([(-.055,.035),(0,.105),(.055,.035),(0,-.035)],-1.01,.028,edge,6)
  elif self.spear:
   self.tube((0,-.83,0),(0,1.67,0),.035,wood,9)
   self.loft([(1.60,.055,.045,0,0),(1.78,.10,.035,0,0),(2.08,.002,.002,0,0)],edge,9,4,smooth=False)
   self.shield(.76,cloth,gold,ivory,6)
  elif knight:
   self.tube((0,-.10,.52),(0,.42,-2.44),.045,ivory,9)
   self.tube((0,.05,-.34),(0,.22,-1.30),.048,cloth,9)
   self.plate([(-.07,.38),(.07,.38),(0,.52)],-2.47,.12,edge,9)
   # Pennon behind the spear tip.
   self.plate([(0,.33),(.46,.26),(.30,.06),(0,.11)],-1.89,.02,cloth,9)
   self.shield(1.06,cloth,gold,ivory,6)
   self.horse(cloth,steel,gold,leather,dark)
  elif enemy:
   self.tube((0,-.30,0),(0,1.03,0),.043,leather,9)
   outline=[(-.05,.62),(.23,.61),(.44,.73),(.44,1.05),(.22,.94),(-.05,.94)]
   self.plate(outline,0,.105,steel,9)
   self.plate([(.35,.69),(.45,.74),(.45,1.06),(.35,1.00)],-.005,.11,edge,9)
   self.shield(.90,color('733a29'),mail,ivory,6,round=True)
  else:
   # Wide polished arming sword, flared quillons, dark grip and round pommel.
   self.loft([(.10,.077,.032,0,-.025),(.91,.066,.024,0,-.025),(1.18,.002,.002,0,-.025)],edge,9,4,smooth=False)
   self.tube((0,.12,-.058),(0,.86,-.050),.012,steel,9,n=5)
   self.bar((0,.09,-.025),(.40,.062,.09),gold,9)
   self.tube((0,-.22,-.025),(0,.07,-.025),.045,leather,9)
   self.ell((0,-.24,-.025),(.078,.062,.05),gold,9)
   self.shield(.96,cloth,gold,ivory,6)
  return self
 def shield(self,scale,cloth,rim,crest,bone,round=False):
  outline=[(-.32,.39),(.32,.39),(.35,.12),(.27,-.23),(0,-.52),(-.27,-.23),(-.35,.12)]
  if round:outline=[(.39*math.cos(i*math.tau/12),.39*math.sin(i*math.tau/12)) for i in range(12)]
  # Convex face and beveled rim catch light instead of reading as a flat sign.
  w=self.world[bone]
  for inset,z,col in [(1.,-.16,rim),(.90,-.205,cloth)]:
   front=[(w[0]+x*scale*inset,w[1]+y*scale*inset,w[2]+z) for x,y in outline]
   center=(w[0],w[1]-.015,w[2]+z-.052);start=len(self.verts)
   area=sum(outline[i][0]*outline[(i+1)%len(outline)][1]-outline[(i+1)%len(outline)][0]*outline[i][1] for i in range(len(outline)))
   for i in range(len(front)):
    a,b=front[i],front[(i+1)%len(front)]
    self.tri(center,a,b,col,bone) if area<0 else self.tri(center,b,a,col,bone)
   self.soften(start,len(self.verts))
  self.plate([(x*scale,y*scale) for x,y in outline],-.115,.045,color('533521'),bone)
  if round:
   self.ell((0,0,-.27),(.13,.13,.095),rim,bone)
   for x in [-.18,.18]:self.bar((x,0,-.249),(.032,.60,.02),rim,bone)
  else:
   self.plate([(-.23*scale,.15*scale),(0,.28*scale),(.23*scale,.15*scale),(.12*scale,.09*scale),(0,.17*scale),(-.12*scale,.09*scale)],-.274,.018,crest,bone)
   self.plate([(-.055*scale,.14*scale),(.055*scale,.14*scale),(0,-.27*scale)],-.275,.018,crest,bone)
  for x,y in outline:self.ell((x*.82*scale,y*.82*scale,-.252),(.024,.024,.014),rim,bone,n=6)
 def horse(self,cloth,steel,gold,leather,dark):
  coat=color('76503a');socks=color('b8a181')
  self.surfaces.update({coat:'fur',socks:'fur',dark:'hair'})
  self.ell((0,.06,0),(.43,.49,.85),coat,24,14)
  self.ell((0,.02,.49),(.46,.46,.46),coat,24,12)
  self.loft([(-.13,.27,.30,0,0),(.25,.23,.22,0,-.10),(.61,.16,.17,0,-.19)],coat,25,12)
  self.ell((0,0,-.06),(.19,.28,.35),coat,26,12);self.ell((0,-.15,-.30),(.17,.16,.23),color('452e25'),26)
  for x in [-.11,.11]:self.loft([(.12,.065,.06,x,.045),(.43,.015,.015,x,.02)],coat,26,n=8)
  for x in [-.17,.17]:
   self.ell((x,.045,-.12),(.026,.04,.05),gold,26,n=8);self.ell((x*1.08,.045,-.14),(.015,.025,.03),dark,26,n=8)
   self.tube((x,-.08,-.41),(x,.19,.07),.028,leather,26)
   self.tube((x,-.1,-.4),(x,.32,.51),.016,leather,26)
  self.loft([(-.10,.16,.055,0,-.37),(.23,.14,.10,0,-.11)],steel,26)
  self.tube((0,.25,.05),(0,-.16,.39),.074,dark,25)
  self.tube((0,.15,.05),(0,.57,-.09),.085,dark,25)
  self.tube((0,0,0),(.02,-.65,.29),.08,dark,27)
  # Caparison drapes down each flank; gilt shield-shaped heraldry.
  for side in [-1,1]:
   self.drape((side*.43,.35,.12),1.25,.75,cloth,24,side=True)
   self.drape((side*.447,-.32,.12),1.27,.058,gold,24,side=True)
   self.bar((side*.465,.03,.12),(.026,.39,.045),gold,24)
   self.bar((side*.468,.12,.12),(.026,.045,.31),gold,24)
   self.tube((side*.28,.52,-.05),(side*.44,-.11,-.05),.025,leather,24)
  self.ell((0,.45,.13),(.37,.13,.35),leather,24)
  self.ell((0,.15,-.61),(.43,.39,.20),steel,24)
  for up,knee in [(28,29),(30,31),(32,33),(34,35)]:
   self.loft([(-.43,.072,.078,0,0),(.05,.15,.16,0,0)],coat,up)
   self.ell((0,.0,0),(.115,.105,.105),steel, knee)
   self.loft([(-.41,.064,.075,0,0),(.03,.075,.08,0,0)],socks,knee)
   self.ell((0,-.43,-.027),(.112,.087,.16),dark,knee)
 def ready(self):
  # Euler XYZ rest rotations. Sword hand is away from the body, shield presented.
  pose={4:(.25,0,-.18),5:(.65,0,0),6:(-.90,0,0),7:(.32,0,.38),8:(-.32,0,0)}
  if self.archer:pose={4:(.75,0,-.15),5:(.35,0,0),6:(-1.1,0,0),7:(.45,0,.25),8:(.45,0,0),9:(-.90,0,0)}
  if self.spear:pose[7]=(.24,0,.29);pose[8]=(-.24,0,0)
  if self.mounted:pose={4:(.40,0,-.17),5:(.55,0,0),6:(-.95,0,0),7:(.4,0,.32),8:(.65,0,0),9:(-1.05,0,0),10:(-.40,0,-.20),13:(-.40,0,.20),11:(.56,0,0),14:(.56,0,0)}
  return pose
 @staticmethod
 def quaternion(euler):
  x,y,z=[a/2 for a in euler];cx,sx=math.cos(x),math.sin(x);cy,sy=math.cos(y),math.sin(y);cz,sz=math.cos(z),math.sin(z)
  return (sx*cy*cz-cx*sy*sz,cx*sy*cz+sx*cy*sz,cx*cy*sz-sx*sy*cz,cx*cy*cz+sx*sy*sz)
 def animation_specs(self):
  ready=self.ready();specs=[]
  def clip(name,duration,changes):
   tracks={b:[a,a,a,a,a] for b,a in ready.items()}
   tracks.update(changes)
   specs.append((name,duration,tracks))
  clip('idle',2.4,{2:[(0,0,0),(.018,-.03,0),(.035,0,0),(.018,.03,0),(0,0,0)]})
  for name,dur,amp in [('walk',.85,.45),('run',.60,.64)]:
   changes={10:[(-amp,0,0),(0,0,0),(amp,0,0),(0,0,0),(-amp,0,0)],13:[(amp,0,0),(0,0,0),(-amp,0,0),(0,0,0),(amp,0,0)],11:[(0,0,0),(.55,0,0),(0,0,0),(.10,0,0),(0,0,0)],14:[(0,0,0),(.10,0,0),(0,0,0),(.55,0,0),(0,0,0)]}
   if self.mounted:
    changes={}
    for b,sgn in [(28,1),(30,-1),(32,-1),(34,1)]:changes[b]=[(sgn*amp,0,0),(0,0,0),(-sgn*amp,0,0),(0,0,0),(sgn*amp,0,0)]
    for b in [29,31,33,35]:changes[b]=[(.05,0,0),(.45,0,0),(.05,0,0),(.30,0,0),(.05,0,0)]
   clip(name,dur,changes)
  if self.mounted:
   for name in ['attack_a','attack_b']:
    clip(name,.95,{7:[(.4,0,.32),(.22,0,.32),(.92,0,.15),(.72,0,.20),(.4,0,.32)],8:[(.65,0,0),(.85,0,0),(.20,0,0),(.4,0,0),(.65,0,0)],9:[(-1.05,0,0),(-1.07,0,0),(-1.12,0,0),(-1.12,0,0),(-1.05,0,0)]})
  elif self.spear:
   for name in ['attack_a','attack_b']:
    clip(name,.95,{7:[(.24,0,.29),(.38,0,.34),(1.25,0,.18),(.92,0,.22),(.24,0,.29)],8:[(-.24,0,0),(-.52,0,0),(-.10,0,0),(-.12,0,0),(-.24,0,0)],9:[(0,0,0),(-.70,0,0),(-2.70,0,0),(-2.1,0,0),(0,0,0)]})
  else:
   for name,twist in [('attack_a',.15),('attack_b',.65)]:
    clip(name,.95,{7:[(.32,0,.38),(2.1,-.25,.65),(1.25,twist,.30),(.95,.25,.20),(.32,0,.38)],8:[(-.32,0,0),(-1.2,0,0),(.12,0,0),(.10,0,0),(-.32,0,0)],9:[(0,0,0),(-.4,0,0),(-2.9,0,0),(-2.15,0,0),(0,0,0)],2:[(0,0,0),(0,-.26,0),(0,.24,0),(0,.08,0),(0,0,0)]})
  clip('shoot',1.25,{7:[(.45,0,.25),(1.25,0,.10),(1.35,0,.10),(1.28,0,.10),(.45,0,.25)],8:[(.45,0,0),(.10,0,0),(.10,0,0),(.10,0,0),(.45,0,0)],9:[(-.90,0,0),(-1.35,0,0),(-1.45,0,0),(-1.38,0,0),(-.90,0,0)],4:[(.75,0,-.15),(1.40,-.7,-.45),(1.45,-.9,-.45),(1.45,-.55,-.3),(.75,0,-.15)],5:[(.35,0,0),(1.1,0,0),(1.3,0,0),(.65,0,0),(.35,0,0)]})
  clip('hit',.25,{2:[(0,0,0),(.15,0,0),(.23,0,0),(.10,0,0),(0,0,0)]})
  clip('block',.35,{4:[(-.2,0,-.18),(-.8,0,-.18),(-1,0,-.18),(-.65,0,-.18),(-.2,0,-.18)]})
  clip('knockback',.4,{1:[(0,0,0),(.22,0,0),(.35,0,0),(.18,0,0),(0,0,0)]})
  clip('defeat',.8,{0:[(0,0,0),(.15,0,.15),(.48,0,.4),(.85,0,.80),(1.25,0,.85)]})
  clip('cheer',1.2,{7:[(-1.6,0,.2),(-2.2,0,.3),(-2.55,0,.15),(-2.2,0,.3),(-1.6,0,.2)]})
  return specs
 def save(self):
  buf=bytearray();views=[];acs=[]
  def acc(data,typ,component=5126):
   while len(buf)%4:buf.append(0)
   start=len(buf);fmt='f' if component==5126 else 'H';flat=[x for row in data for x in row];buf.extend(struct.pack('<'+fmt*len(flat),*flat));views.append({'buffer':0,'byteOffset':start,'byteLength':len(buf)-start});a={'bufferView':len(views)-1,'componentType':component,'count':len(data),'type':typ}
   if typ in ('VEC3','SCALAR'):a.update(min=[min(r[i] for r in data) for i in range(len(data[0]))],max=[max(r[i] for r in data) for i in range(len(data[0]))])
   acs.append(a);return len(acs)-1
  pos=acc(self.verts,'VEC3');norm=acc(self.norm,'VEC3');col=acc(self.colors,'VEC4');joints=acc(self.joints,'VEC4',5123);weights=acc([(1,0,0,0)]*len(self.verts),'VEC4')
  from build_character_surfaces import atlas_uv
  uv=acc([atlas_uv(point,family) for point,family in zip(self.uvs,self.surface_names)],'VEC2')
  nodes=[]
  for i,(name,p,t) in enumerate(self.bones):
   node={'name':name,'translation':t};children=[j for j,(_,pp,_) in enumerate(self.bones) if pp==i]
   if children:node['children']=children
   nodes.append(node)
  inv=[(1,0,0,0,0,1,0,0,0,0,1,0,-x,-y,-z,1) for x,y,z in self.world];ibm=acc(inv,'MAT4');nodes.append({'name':self.kind.title(),'mesh':0,'skin':0})
  animations=[]
  for name,duration,tracks in self.animation_specs():
   sam=[];chan=[]
   # Key every joint so attack tracks cannot leave limbs stuck after blending.
   for bone in range(len(self.bones)):
    eulers=tracks.get(bone,[(0,0,0)]*5)
    times=acc([(duration*i/4,) for i in range(5)],'SCALAR');out=acc([self.quaternion(e) for e in eulers],'VEC4')
    sam.append({'input':times,'output':out,'interpolation':'LINEAR'});chan.append({'sampler':len(sam)-1,'target':{'node':bone,'path':'rotation'}})
   animations.append({'name':name,'samplers':sam,'channels':chan})
  doc={'asset':{'version':'2.0','generator':'Castlehold original sculpted medieval mesh authoring v3'},'scene':0,'scenes':[{'nodes':[0,len(nodes)-1]}],'nodes':nodes,'skins':[{'inverseBindMatrices':ibm,'joints':list(range(len(self.bones))),'skeleton':0}],'meshes':[{'primitives':[{'attributes':{'POSITION':pos,'NORMAL':norm,'COLOR_0':col,'TEXCOORD_0':uv,'JOINTS_0':joints,'WEIGHTS_0':weights},'material':0}]}],'materials':[{'name':'Castlehold steel, cloth, skin and leather ORM','pbrMetallicRoughness':{'baseColorFactor':[1,1,1,1],'metallicFactor':1,'roughnessFactor':1,'metallicRoughnessTexture':{'index':0}},'doubleSided':True}],'images':[{'uri':'medieval_orm.png'}],'textures':[{'source':0,'sampler':0}],'samplers':[{'magFilter':9728,'minFilter':9728,'wrapS':33071,'wrapT':33071}],'buffers':[{'uri':self.kind+'.bin','byteLength':len(buf)}],'bufferViews':views,'accessors':acs,'animations':animations}
  doc['asset']['generator']='Castlehold original medieval mesh authoring v4 / Fieldcraft'
  doc['materials'][0]={'name':'Fieldcraft cloth, linked mail, forged steel and skin',
   'pbrMetallicRoughness':{'baseColorFactor':[1,1,1,1], 'baseColorTexture':{'index':0},
    'metallicFactor':1,'roughnessFactor':1,'metallicRoughnessTexture':{'index':2}},
   'normalTexture':{'index':1,'scale':.42},'doubleSided':True}
  doc['images']=[{'uri':'fieldcraft_'+name+'.png'} for name in ['albedo','normal','orm']]
  doc['textures']=[{'source':i,'sampler':0} for i in range(3)]
  doc['samplers']=[{'magFilter':9729,'minFilter':9987,'wrapS':33071,'wrapT':33071}]
  # Some import caches key on the glTF JSON, even when an external .bin changed.
  # Include its content fingerprint so animation-only edits trigger reimport.
  doc['asset']['extras']={'buffer_sha256':hashlib.sha256(buf).hexdigest()}
  ROOT.mkdir(parents=True,exist_ok=True);(ROOT/(self.kind+'.bin')).write_bytes(buf);(ROOT/(self.kind+'.gltf')).write_text(json.dumps(doc,separators=(',',':')))
  print(self.kind,len(self.verts)//3,'triangles',len(self.bones),'bones')
if __name__=='__main__':
 from build_character_surfaces import build as build_surfaces
 build_surfaces()
 ROOT.mkdir(parents=True,exist_ok=True)
 def chunk(kind,data):return struct.pack('>I',len(data))+kind+data+struct.pack('>I',zlib.crc32(kind+data)&0xffffffff)
 pixels=b''.join(b'\0'+b''.join(bytes((255,round([.30,.52,.76,.94][x//16]*255),round([0.,.12,.62,.88][y//16]*255))) for x in range(64)) for y in range(64))
 (ROOT/'medieval_orm.png').write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',64,64,8,2,0,0,0))+chunk(b'IDAT',zlib.compress(pixels))+chunk(b'IEND',b''))
 for kind in ['archer','swordsman','spearman','knight']:Model(kind).build().save()
 from build_horde import HordeModel, KINDS
 for kind in KINDS:HordeModel(kind).build().save()

 from build_ogre_elites import OgreEliteModel, KINDS as ELITES
 for kind in ELITES:OgreEliteModel(kind).build().save()

if __name__=="__main__":
 from build_bosses import BossModel, KINDS as BOSS_KINDS
 for kind in BOSS_KINDS:BossModel(kind).build().save()
