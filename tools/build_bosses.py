"""Original skinned siege bosses inspired by Castlehold's approved concept board.
Authored geometry, articulated jaws/tails/banners and complete animation tracks.
No downloaded models. One material surface per complete boss and mount.
"""
import math
from build_characters import Model, color
from build_horde import HordeModel

KINDS=['boss_gatebreaker','boss_dreadscale','boss_ashcaller','boss_ironjaw']
SCALES={'boss_gatebreaker':1.95,'boss_dreadscale':1.17,'boss_ashcaller':1.80,'boss_ironjaw':1.28}

class BossModel(HordeModel):
 def __init__(self,kind):
  super().__init__('ogre');self.boss_kind=kind
  self.cyclops=kind=='boss_gatebreaker';self.mage=kind=='boss_ashcaller'
  self.reptile=kind in ('boss_dreadscale','boss_ironjaw');self.king=kind=='boss_ironjaw'
  if self.reptile:
   self.mounted=True;self.bones+=Model('mounted_raider').bones[24:]
   changes={1:(0,3.27 if self.king else 2.92,.18),10:(-.84,-.10,0),13:(.84,-.10,0),
    24:(0,2.05 if self.king else 1.68,0),25:(0,.80 if self.king else .12,-.82 if self.king else -1.17),
    26:(0,.66 if self.king else .06,-.53 if self.king else -.72),27:(0,.05,1.20 if self.king else 1.40),
    28:(-.53,.51,-.91) if self.king else (-.84,-.22,-.95),
    30:(.53,.51,-.91) if self.king else (.84,-.22,-.95),
    29:(0,-.36,-.08) if self.king else (0,-.65,0),31:(0,-.36,-.08) if self.king else (0,-.65,0),
    32:(-.72,-.40,.46) if self.king else (-.85,-.22,.95),
    34:(.72,-.40,.46) if self.king else (.85,-.22,.95),
    33:(0,-.80,-.06) if self.king else (0,-.65,.06),35:(0,-.80,-.06) if self.king else (0,-.65,.06)}
   self.bones=[(n,p,changes.get(i,t)) for i,(n,p,t) in enumerate(self.bones)]
   self.bones += [('tail_tip',27,(0,-.03,1.25)),('beast_jaw',26,(0,-.16,-.29)),
    ('banner_L',24,(-.55,.74,.52)),('banner_R',24,(.55,.74,.52))]
  self.rebuild_world()
  self.iron=color('454b49');self.edge=color('87928a');self.gold=color('b18b52')
  self.rust=color('853d2b');self.leather=color('493121');self.ivory=color('dfcda5')
  self.skin=color('7e8d60' if not self.mage else '7d8c76');self.light=color('acb283')
  self.dark=color('262c25');self.ember=color('f2a847')
  self.surfaces.update({self.iron:'iron',self.edge:'steel',self.gold:'gold',self.rust:'cloth',
   self.leather:'leather',self.ivory:'bone',self.skin:'skin',self.light:'skin'})
  for c in [self.iron,self.edge,self.gold]:self.finishes[c]=(.52,.62)
  for c in [self.skin,self.light,self.leather]:self.finishes[c]=(.76,0.)

 def rebuild_world(self):
  self.world=[]
  for _,p,t in self.bones:self.world.append(tuple(t[i]+(self.world[p][i] if p>=0 else 0) for i in range(3)))

 def remove_bone_geometry(self,bone):
  keep=[i for i,j in enumerate(self.joints) if j[0]!=bone]
  for field in ['verts','norm','colors','joints','uvs','surface_names']:
   values=getattr(self,field);setattr(self,field,[values[i] for i in keep])

 def build(self):
  super().build();self.remove_bone_geometry(3)
  swap={color('9a916c'):self.skin,color('b3aa7e'):self.light,color('913f2c'):self.rust}
  self.colors=[swap.get(c,c) for c in self.colors]
  self.face();self.armor()
  if self.mage:self.regalia()
  if self.reptile:self.mount()
  self.kind=self.boss_kind
  scale=SCALES[self.kind]
  self.verts=[tuple(v*scale for v in p) for p in self.verts]
  self.bones=[(n,p,tuple(v*scale for v in t)) for n,p,t in self.bones];self.rebuild_world()
  # Broad baked color variation follows the mesh and costs no runtime shader.
  # Keep the original ORM assignment for every varied vertex color.
  varied=[];finishes={}
  for p,c in zip(self.verts,self.colors):
   x,y,z=p;shade=.965+.035*math.sin(x*8.3+z*5.7)*math.sin(y*6.4-z*3.1)
   cc=tuple(max(0,min(1,v*shade)) for v in c[:3])+(1,)
   varied.append(cc);finishes[cc]=self.finishes.get(c,(.94,0.))
  self.colors=varied;self.finishes.update(finishes)
  return self

 def face(self):
  s=self.skin;l=self.light;d=self.dark;b=self.ivory;h=1.36
  self.loft([(-.32,.17,.17,0,-.06),(-.19,.32,.26,0,-.09),(.10,.31,.26,0,-.03),(.32,.25,.20,0,.02),(.41,.13,.12,0,.03)],s,3,20)
  self.ell((0,-.20,-.28),(.28,.105,.095),l,3,16)
  self.ell((0,-.115,-.32),(.20,.085,.027),d,3,14)
  self.tube((-.20,-.075,-.343),(.20,-.075,-.343),.019,s,3,10)
  for x in [-.13,-.065,0,.065,.13]:
   self.spike((x,-.065,-.34),(x,-.115,-.35),.025,b,3)
  self.ell((0,-.013,-.295),(.095,.077,.090),s,3,14)
  for sign in [-1,1]:
   self.plate([(sign*.26,.17),(sign*.59,.33),(sign*.42,-.06),(sign*.28,-.095)],.015,.08,s,3)
   self.plate([(sign*.35,.17),(sign*.51,.26),(sign*.39,.025)],-.033,.018,l,3)
   self.spike((sign*.205,-.25,-.31),(sign*.24,-.015,-.40),.055,b,3)
   self.ell((sign*.25,-.01,-.20),(.10,.105,.035),l,3,12)
  if self.cyclops:
   self.ell((0,.155,-.266),(.163,.127,.068),d,3,20)
   self.ell((0,.161,-.314),(.129,.094,.038),b,3,20)
   self.ell((0,.159,-.344),(.066,.076,.020),color('cc9436'),3,16)
   self.ell((0,.161,-.361),(.028,.056,.011),d,3,14)
   self.ell((-.021,.196,-.372),(.012,.016,.008),color('fff1c5'),3,8)
   self.tube((-.20,.23,-.265),(0,.252,-.31),.057,s,3,12)
   self.tube((0,.252,-.31),(.20,.24,-.265),.057,s,3,12)
  else:
   for sign in [-1,1]:
    self.ell((sign*.132,.13,-.266),(.079,.046,.033),d,3,12)
    self.ell((sign*.132,.128,-.294),(.046,.028,.013),color('dfb451'),3,12)
    self.ell((sign*.133,.129,-.305),(.019,.025,.008),d,3,8)
    self.tube((sign*.05,.174,-.28),(sign*.25,.229,-.21),.039,s,3,10)
  if self.reptile:
   self.loft([(.23,.35,.29,0,.035),(.31,.36,.29,0,.035),(.49,.18,.17,0,.065)],self.iron,3,16,smooth=False)
   self.loft([(.23,.36,.30,0,.035),(.28,.36,.30,0,.035)],self.gold,3,16,smooth=False)
   for x in [-.27,0,.27]:self.spike((x,.36,.04),(x*1.45,.68 if self.king else .58,.11),.083,self.gold,3)
   for sign in [-1,1]:self.plate([(sign*.24,.27),(sign*.35,.23),(sign*.34,-.17),(sign*.25,-.11)],-.17,.07,self.iron,3)

 def fang_mark(self,center,size,bone):
  x,y,z=center
  outline=[(-.31,.30),(-.07,.18),(0,.35),(.08,.18),(.31,.30),(.23,.01),(.13,-.11),(.08,-.43),(0,-.20),(-.07,-.43),(-.13,-.11),(-.23,.01)]
  self.plate([(x+a*size,y+b*size) for a,b in outline],z,.018,self.ivory,bone)

 def armor(self):
  for bone,sign in [(4,-1),(7,1)]:
   for i in range(3 if sign<0 else 2):
    self.loft([(-.09-i*.10,.33,.36,sign*.04,0),(.03-i*.10,.44,.40,sign*.045,0),(.14-i*.10,.28,.29,sign*.04,.015)],self.iron,bone,10,smooth=False)
    for z in [-.25,.02,.24]:self.ell((sign*.30,.04-i*.10,z),(.028,.032,.035),self.gold,bone,8)
   for x,z in [(-.19,0),(.16,.14)]:self.spike((x,.16,z),(x*1.6,.48,z*1.5),.072,self.edge,bone)
  for fore in [5,8]:
   self.loft([(-.31,.20,.19,0,0),(-.26,.225,.22,0,0),(-.06,.22,.21,0,0),(-.02,.18,.18,0,0)],self.iron,fore,12,smooth=False)
   for y in [-.29,-.04]:self.loft([(y,.229,.223,0,0),(y+.025,.229,.223,0,0)],self.gold,fore,12,smooth=False)
  for shin in [11,14]:
   self.plate([(-.16,.10),(.16,.10),(.21,-.09),(.13,-.40),(0,-.45),(-.13,-.40),(-.21,-.09)],-.17,.07,self.iron,shin)
   self.ell((0,.03,-.245),(.14,.135,.045),self.edge,shin,12)
   for x in [-.13,.13]:self.ell((x,-.22,-.224),(.029,.03,.02),self.gold,shin,8)
  self.plate([(-.53,.32),(-.46,.40),(.49,-.21),(.42,-.29)],-.39,.07,self.leather,2)
  for x in [-.33,-.08,.20]:self.ell((x,.08-x*.64,-.437),(.03,.03,.017),self.gold,2,8)
  for x in [-.29,0,.29]:
   self.drape((x,-.12,-.46),.31,.58,self.rust,1)
   self.plate([(x-.135,-.12),(x+.135,-.12),(x+.13,-.22),(x-.13,-.22)],-.49,.035,self.iron,1)
  self.fang_mark((0,-.32,-.506),.47,1)
  if self.king:
   self.loft([(-.26,.48,.34,0,-.10),(.16,.61,.36,0,-.08),(.32,.45,.29,0,-.04)],self.iron,2,14,smooth=False)
   self.fang_mark((0,.03,-.47),.55,2)

 def ogre_weapon(self,wood,iron,edge):
  if self.mage:
   points=[(0,-1.03,0),(-.05,-.25,.02),(.05,.54,0),(-.05,1.27,.035),(0,1.65,0)]
   for a,b in zip(points,points[1:]):self.tube(a,b,.085,self.leather,9,12)
   for y in [-.15,.10,.73,1.13]:self.loft([(y,.112,.112,0,0),(y+.064,.112,.112,0,0)],self.gold,9,12)
   self.loft([(1.36,.12,.12,0,0),(1.53,.31,.27,0,0),(1.77,.32,.28,0,0)],self.iron,9,12,smooth=False)
   for y in [1.52,1.72]:self.loft([(y,.327,.286,0,0),(y+.046,.327,.286,0,0)],self.gold,9,12,smooth=False)
   for a in [0,math.tau/3,math.tau*2/3]:
    x,z=.30*math.cos(a),.27*math.sin(a)
    self.tube((x,1.62,z),(x*1.4,2.02,z*1.4),.048,self.gold,9,8)
    self.spike((x*1.4,2.02,z*1.4),(x*.62,2.35,z*.62),.056,self.ivory,9)
   self.loft([(1.55,.045,.04,0,0),(1.91,.15,.14,0,0),(2.30,.01,.01,0,0)],self.ember,9,8,smooth=False)
  elif self.cyclops:
   self.tube((0,-.43,0),(0,1.72,0),.087,self.leather,9,12)
   for y in [-.28,-.08,.18,.44,1.03]:self.loft([(y,.105,.105,0,0),(y+.08,.105,.105,0,0)],self.gold,9,12)
   stone=color('727567');self.finishes[stone]=(.94,0.)
   self.loft([(1.35,.48,.33,0,0),(1.46,.64,.45,0,0),(2.13,.64,.45,0,0),(2.26,.48,.33,0,0)],stone,9,8,smooth=False)
   for y in [1.46,1.95]:self.loft([(y,.66,.47,0,0),(y+.14,.66,.47,0,0)],self.iron,9,8,smooth=False)
   self.plate([(-.07,1.38),(.07,1.38),(.07,2.22),(-.07,2.22)],-.463,.06,self.iron,9)
   for y in [1.54,2.01]:
    for x in [-.38,.38]:self.ell((x,y,-.414),(.055,.054,.026),self.gold,9,8)
   for sign in [-1,1]:self.spike((sign*.51,1.79,0),(sign*.84,1.79,0),.14,self.edge,9)
  elif self.king:
   self.tube((0,-.55,0),(0,2.43,0),.065,self.leather,9,10)
   self.loft([(1.72,.14,.065,0,0),(2.25,.26,.065,0,0),(2.90,.002,.002,0,0)],self.edge,9,4,smooth=False)
   self.plate([(-.22,1.89),(-.11,2.27),(-.03,2.10),(.05,1.78)],0,.10,self.iron,9)
   for y in [.10,.80,1.6]:self.loft([(y,.094,.094,0,0),(y+.10,.094,.094,0,0)],self.gold,9,10)
  else:
   self.tube((0,-.48,0),(0,1.45,0),.075,self.leather,9,12)
   self.plate([(-.10,.91),(.27,.71),(.66,.85),(.89,1.48),(.60,1.27),(.30,1.36),(-.10,1.28)],0,.18,self.iron,9)
   self.plate([(.55,.82),(.66,.85),(.89,1.48),(.73,1.35)],-.026,.20,self.edge,9)
   for y in [.01,.24,.75]:self.loft([(y,.091,.091,0,0),(y+.066,.091,.091,0,0)],self.gold,9,10)

 def regalia(self):
  robe=color('5e4155');gold=self.gold
  for sign in [-1,1]:
   self.drape((sign*.30,.27,-.44),.56,1.30,robe,1)
   self.drape((sign*.30,-.90,-.48),.55,.13,gold,1)
   self.drape((sign*.55,.12,.05),.66,1.16,robe,1,side=True)
   self.drape((sign*.31,.20,.40),.58,1.26,robe,1)
   self.loft([(-.67,.049,.043,sign*.19,-.26),(-.44,.078,.061,sign*.19,-.25),(-.27,.076,.074,sign*.19,-.21)],self.ivory,3,12)
   for y in [-.62,-.51,-.39]:self.loft([(y,.085,.075,sign*.19,-.25),(y+.03,.085,.075,sign*.19,-.25)],gold,3,10)
   points=[(sign*.24,.23,.015),(sign*.36,.49,.05),(sign*.55,.70,.08),(sign*.61,.95,.12)]
   for a,b in zip(points,points[1:]):self.tube(a,b,.067,self.leather,3,10)
   self.spike(points[-1],(sign*.53,1.14,.09),.070,self.ivory,3)
   for a,b in [((sign*.35,.48,.05),(sign*.72,.56,.0)),((sign*.49,.64,.07),(sign*.89,.88,.11))]:self.spike(a,b,.055,self.ivory,3)
   self.plate([(sign*.05,.39),(sign*.22,.33),(sign*.27,.49),(sign*.13,.64)],-.03,.043,gold,3)
  self.loft([(-.86,.033,.042,0,-.35),(-.59,.15,.12,0,-.29),(-.32,.22,.13,0,-.25),(-.23,.22,.09,0,-.29)],self.ivory,3,20)
  for x in [-.11,-.055,.03,.105]:
   self.tube((x,-.34,-.38),(x*.55,-.69,-.42),.014,color('a99577'),3,6)
  for x in [-.35,-.19,0,.19,.35]:
   self.ell((x,.12-abs(x)*.14,-.43),(.095,.088,.031),gold,2,10)
   self.spike((x,.04-abs(x)*.14,-.44),(x,-.15-abs(x)*.14,-.45),.048,self.ivory,2)
  self.fang_mark((0,-.51,-.53),.41,1)

 def mount(self):
  skin=color('9b543e' if self.king else '667847');belly=color('bb9770' if self.king else 'a59b68')
  scale=color('b7744f' if self.king else '8c995b');dark=self.dark
  for c in [skin,belly,scale]:self.finishes[c]=(.76,0.)
  self.ell((0,.02,.04),(.83 if self.king else 1.02,.81 if self.king else .64,1.29),skin,24,20)
  self.ell((0,-.20,-.43),(.65 if self.king else .77,.55,.76),belly,24,18)
  self.ell((0,.05,0),(.55,.60 if self.king else .49,.68),skin,25,18)
  self.ell((0,.02,-.12),(.60 if self.king else .68,.46,.71),skin,26,20)
  self.ell((0,.015,-.53),(.55 if self.king else .65,.32,.69 if self.king else .81),skin,26,20)
  # The lower jaw uses a separate joint and carries its own teeth.
  self.ell((0,-.10,-.30),(.50 if self.king else .58,.16,.72),belly,37,18)
  self.ell((0,.03,-.32),(.46 if self.king else .53,.034,.65),dark,37,16)
  for sign in [-1,1]:
   for z in [-.16,-.39,-.63,-.86]:
    x=sign*(.48 if self.king else .57)*(1-.21*max(0,-z-.30))
    self.spike((x,-.18,z),(x*.95,-.40,z-.02),.061,self.ivory,26)
    self.spike((x*.87,.035,z+.25),(x*.84,.19,z+.25),.054,self.ivory,37)
   self.ell((sign*.56,.25,-.31),(.038,.093,.12),dark,26,14)
   self.ell((sign*.592,.257,-.335),(.021,.059,.073),color('e5b64d'),26,12)
   self.ell((sign*.612,.259,-.345),(.012,.049,.026),dark,26,10)
   self.ell((sign*.38,.16,-1.01),(.045,.055,.08),dark,26,10)
   self.spike((sign*.39,.36,-.27),(sign*.60,.77,-.14),.13,self.ivory,26)
   if not self.king:self.spike((sign*.56,-.11,-.65),(sign*.91,.17,-.86),.15,self.ivory,26)
   self.tube((sign*.53,.35,.04),(sign*.49,-.19,-.76),.056,self.leather,26,10)
   self.tube((sign*.59,-.15,-.20),(sign*.68,.56,.68),.035,self.leather,25,8)
  self.loft([(.22,.49,.53,0,-.24),(.31,.63,.68,0,-.29),(.40,.50,.54,0,-.30)],self.iron,26,10,smooth=False)
  for x in [-.33,0,.33]:self.ell((x,.36,-.72),(.043,.027,.043),self.gold,26,8)
  if self.king:
   self.spike((0,.34,-.63),(0,.84,-.92),.17,self.ivory,26)
   for j in range(4):self.loft([(-.20+j*.20,.49,.25,0,-.40),(-.05+j*.20,.51,.28,0,-.40)],self.iron,25,10,smooth=False)
  for z in [-.80,-.37,.10,.57,.99]:
   self.loft([(.43,.61,.24,0,z),(.59,.67,.27,0,z),(.72,.46,.18,0,z)],self.iron,24,8,smooth=False)
   for x in [-.42,.42]:self.ell((x,.67,z-.10),(.040,.028,.039),self.gold,24,8)
   if z<-.5 or z>.5:self.spike((0,.69,z),(0,1.02,z+.12),.15,self.edge,24)
  # Sculpted large flank scales; selective detail rather than thousands of nodes.
  for sign in [-1,1]:
   for y in [-.18,.02,.22]:
    for j in range(6):
     z=-.76+j*.31;self.ell((sign*(.79 if self.king else .965),y,z),(.035,.12,.16),scale,24,8)
   self.tube((sign*.69,.60,.31),(sign*.90,-.47,.31),.070,self.leather,24,10)
   self.drape((sign*(.76 if self.king else .98),.55,.42),1.32,.62,self.rust,24,side=True)
  self.ell((0,.81,.17),(.55,.18,.66),self.leather,24,16)
  self.loft([(-.11,.23,.21,0,.32),(.11,.29,.30,0,.48)],skin,27,14)
  for b,r,points in [(27,.37,[(0,0,0),(0,-.10,.73),(0,-.03,1.28)]),(36,.23,[(0,0,0),(0,.08,.63),(.02,.26,1.10)])]:
   for a,c in zip(points,points[1:]):self.tube(a,c,r,skin,b,14);r*=.63
   for z in [.18,.57,.96]:self.spike((0,.10,z),(0,.36,z+.16),.095,self.iron,b)
  self.spike((.02,.26,1.10),(.03,.32,1.50),.09,skin,36)
  for upper,knee,sign,front in [(28,29,-1,True),(30,31,1,True),(32,33,-1,False),(34,35,1,False)]:
   arm=self.king and front
   length=.36 if arm else (.79 if self.king else .65)
   self.loft([(-length,.10 if arm else .24,.13 if arm else .26,0,-.03),(-length*.25,.18 if arm else .42,.20 if arm else .48,0,0),(.10,.16 if arm else .38,.18 if arm else .40,0,0)],skin,upper,16)
   low=.29 if arm else (.67 if self.king else .55)
   self.loft([(-low,.085 if arm else .21,.10 if arm else .23,0,-.08),(.09,.13 if arm else .28,.17 if arm else .31,0,0)],skin,knee,14)
   self.ell((0,-low,-.20),(.14 if arm else .36,.10 if arm else .18,.24 if arm else .43),skin,knee,14)
   for x in [-.08,.08] if arm else [-.23,0,.23]:
    self.spike((x,-low-.01,-.27 if arm else -.47),(x,-low-.06,-.45 if arm else -.80),.052 if arm else .085,self.ivory,knee)
   if not arm:
    self.loft([(-low+.07,.245,.26,0,-.06),(-low+.23,.25,.27,0,-.045)],self.iron,knee,12,smooth=False)
    for x in [-.16,.16]:self.ell((x,-low+.14,-.30),(.035,.036,.024),self.gold,knee,8)
  for b in ([38,39] if self.king else [38]):
   self.tube((0,0,0),(0,2.13,0),.043,self.leather,b,10)
   self.spike((0,2.08,0),(0,2.44,0),.088,self.iron,b)
   self.drape((.34,2.04,.0),.65,1.0,self.rust,b)
   self.fang_mark((.34,1.59,-.045),.54,b)

 def ready(self):
  p=super().ready()
  if self.cyclops:p.update({7:(.15,0,.38),8:(-.20,0,0),9:(.05,0,-.38),4:(.25,0,-.38),5:(.20,0,0),6:(-.20,0,0)})
  if self.mage:p.update({7:(.18,0,.48),8:(-.30,0,0),9:(.08,0,-.48),4:(.62,0,-.52),5:(.90,0,0),6:(-.90,0,0)})
  if self.reptile:
   p.update({10:(1.05,0,-.52),13:(1.05,0,.52),11:(-1.05,0,0),14:(-1.05,0,0),7:(.28,0,.34),8:(-.22,0,0),9:(.02,0,-.30),37:(.20,0,0)})
   if self.king:p.update({25:(.02,0,0),28:(-.42,0,-.30),30:(-.42,0,.30),29:(.95,0,0),31:(.95,0,0),9:(-.25,0,-.60)})
  return p

 def animation_specs(self):
  specs=[];ready=self.ready()
  for name,duration,tracks in super().animation_specs():
   tracks={**{b:[a]*5 for b,a in ready.items()},**tracks}
   if name in ('walk','run'):
    duration=1.30 if name=='walk' else 1.02
    if self.reptile:
     for b in [10,11,13,14]:tracks[b]=[ready[b]]*5
     for b in ([32,34] if self.king else [28,30,32,34]):
      a=.38 if b in [28,34] else -.38;tracks[b]=[(a,0,0),(0,0,0),(-a,0,0),(0,0,0),(a,0,0)]
     if self.king:
      for b in [28,30,29,31]:tracks[b]=[ready[b]]*5
     tracks[27]=[(0,-.12,0),(0,0,0),(0,.12,0),(0,0,0),(0,-.12,0)]
     tracks[36]=[(0,.14,0),(0,0,0),(0,-.14,0),(0,0,0),(0,.14,0)]
   if name in ('attack_a','attack_b'):
    duration=2.4 if self.cyclops else 2.2
    if self.cyclops:
     tracks.update({7:[ready[7],(1.9,-.1,-.2),(.10,.10,.20),(.10,0,.25),ready[7]],8:[ready[8],(-1.0,0,0),(.25,0,0),(.25,0,0),ready[8]],9:[ready[9],(-.4,0,.25),(-2.42,0,-.20),(-2.35,0,-.25),ready[9]],4:[ready[4],(1.8,0,.60),(1.1,0,.45),(.7,0,.62),ready[4]],5:[ready[5],(-.6,0,.2),(.05,0,.2),(-.2,0,.1),ready[5]]})
    if self.reptile:
     tracks[25]=[(.02,0,0),(.23,0,0),(-.18,0,0),(-.08,0,0),(.02,0,0)]
     tracks[37]=[(.20,0,0),(.60,0,0),(.01,0,0),(.07,0,0),(.20,0,0)]
     if self.king and name=='attack_b':tracks[32]=[(0,0,0),(-.68,0,0),(.18,0,0),(.10,0,0),(0,0,0)]
   if self.mage and name=='shoot':
    duration=2.0
    tracks.update({7:[ready[7],(.50,0,.40),(.90,0,.27),(.56,0,.35),ready[7]],8:[ready[8],(-.40,0,0),(-.25,0,0),(-.30,0,0),ready[8]],9:[ready[9],(0,0,-.40),(-.65,0,-.27),(-.25,0,-.35),ready[9]],4:[ready[4],(1.35,-.2,-.45),(1.50,.10,-.2),(1.0,0,-.4),ready[4]]})
   if name=='defeat':duration=1.35
   specs.append((name,duration,tracks))
  special={b:[a]*5 for b,a in ready.items()}
  if self.mage:
   special.update({7:[ready[7],(1.3,0,.38),(1.6,0,.27),(1.1,0,.4),ready[7]],9:[ready[9],(-1.0,0,-.38),(-1.5,0,-.27),(-.8,0,-.4),ready[9]],4:[ready[4],(1.7,0,-.55),(1.9,0,-.4),(1.4,0,-.5),ready[4]]})
  elif self.reptile:
   special[27]=[(0,0,0),(0,-.7,0),(0,1.0,0),(0,.3,0),(0,0,0)]
   special[36]=[(0,0,0),(0,-.3,0),(0,.9,0),(0,.25,0),(0,0,0)]
   special[25]=[(0,0,0),(.3,0,0),(.4,0,0),(.15,0,0),(0,0,0)]
   special[37]=[(.2,0,0),(.6,0,0),(.7,0,0),(.35,0,0),(.2,0,0)]
  else:special=dict(next(s[2] for s in specs if s[0]=='attack_a'))
  specs.append(('special',3.0 if self.mage else 2.4,special))
  return specs

if __name__=='__main__':
 for kind in KINDS:BossModel(kind).build().save()
