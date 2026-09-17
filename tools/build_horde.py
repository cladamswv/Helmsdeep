"""Original Ironroot Horde: orcs, a warg rider and a siege ogre.
Uses the project's glTF authoring primitives, never downloaded geometry.
Existing enemy asset IDs are retained so older checkpoints still load.
"""
from build_characters import Model, color

KINDS = ['raider', 'enemy_archer', 'enemy_spearman', 'mounted_raider', 'orc_guard', 'ogre']

class HordeModel(Model):
 def __init__(self, kind):
  super().__init__(kind)
  self.enemy=True; self.ogre=kind=='ogre'; self.guard=kind=='orc_guard'
  # Different anatomy, not a recolored human uniform.
  changes={1:(0,1.0,0),2:(0,.37,.045),3:(0,.43,-.09),4:(-.43,.20,0),7:(.43,.20,0)}
  if self.mounted:changes[1]=(0,1.94,.10)
  if self.ogre:
   changes={1:(0,1.35,.02),2:(0,.55,.11),3:(0,.51,-.19),
    4:(-.67,.29,0),7:(.67,.29,0),5:(0,-.48,0),8:(0,-.48,0),
    6:(0,-.40,0),9:(0,-.40,0),10:(-.30,-.09,0),13:(.30,-.09,0),
    11:(0,-.56,0),14:(0,-.56,0),12:(0,-.51,0),15:(0,-.51,0)}
  self.bones=[(name,p,changes.get(i,t)) for i,(name,p,t) in enumerate(self.bones)]
  self.world=[]
  for _,p,t in self.bones:self.world.append(tuple(t[i]+(self.world[p][i] if p>=0 else 0) for i in range(3)))

 def spike(self,a,b,r,col,bone):
  # Tapered, bent bone/iron teeth with a deliberate silhouette.
  direction=[b[i]-a[i] for i in range(3)]
  middle=tuple(a[i]+direction[i]*.55 for i in range(3))
  self.tube(a,middle,r,col,bone,n=6)
  import math
  d=direction;length=math.sqrt(sum(v*v for v in d));d=[v/length for v in d]
  u=[d[1],-d[0],0] if abs(d[2])<.9 else [1,0,0]
  length=math.sqrt(sum(v*v for v in u));u=[v/length for v in u]
  v=[d[1]*u[2]-d[2]*u[1],d[2]*u[0]-d[0]*u[2],d[0]*u[1]-d[1]*u[0]]
  w=self.world[bone];tip=tuple(w[k]+b[k] for k in range(3))
  ring=[tuple(w[k]+middle[k]+r*(u[k]*math.cos(j*math.tau/6)+v[k]*math.sin(j*math.tau/6)) for k in range(3)) for j in range(6)]
  for j in range(6):self.tri(ring[j],ring[(j+1)%6],tip,col,bone)

 def build(self):
  ogre=self.ogre; arch=self.archer
  skin=color({'raider':'698b50','enemy_archer':'7c9b61','enemy_spearman':'668354','mounted_raider':'779155','orc_guard':'597958','ogre':'9a916c'}[self.kind])
  light=color('b3aa7e' if ogre else '92a970'); dark=color('232c2b'); iron=color('4b5554')
  edge=color('9baba6'); rust=color('913f2c'); leather=color('513726'); bone=color('e5d5a5'); wood=color('65472c'); bronze=color('a27743')
  self.surfaces.update({skin:'skin',light:'skin',dark:'hair',iron:'iron',edge:'steel',
   rust:'cloth',leather:'leather',bone:'bone',wood:'wood',bronze:'gold'})
  for c in [iron,edge,bronze]:self.finishes[c]=(.52,.62)
  for c in [skin,light,leather]:self.finishes[c]=(.76,0.)
  if ogre:
   self.loft([(-.32,.41,.31,0,0),(.0,.57,.44,0,-.035),(.39,.62,.45,0,0),(.65,.53,.35,0,.04)],skin,1,16)
   self.loft([(-.15,.46,.32,0,0),(.09,.64,.38,0,.03),(.34,.67,.33,0,.035),(.46,.34,.24,0,0)],skin,2,18)
   # Sculpted pectorals, collarbones and belly rather than a smooth single oval.
   for side in [-1,1]:
    self.ell((side*.28,.16,-.277),(.30,.215,.115),skin,2,14)
    self.tube((side*.09,.32,-.235),(side*.39,.32,-.245),.035,light,2,8)
  else:
   self.loft([(-.27,.29,.21,0,0),(.06,.28,.21,0,0),(.39,.41,.255,0,.04)],leather,1,14)
   self.loft([(-.04,.35,.235,0,.02),(.24,.41,.26,0,.03),(.38,.22,.16,0,.04)],skin,2,14)
   self.drape((0,.15,-.265),.39,.35,rust,2)
  width=.94 if ogre else .60
  for x in [-width*.24,width*.24]:
   self.drape((x,-.20,-(.40 if ogre else .24)),width*.51,.46 if ogre else .37,rust,1)
  self.loft([(-.13,width*.60,.46 if ogre else .26,0,0),(-.025,width*.60,.46 if ogre else .26,0,0)],leather,1,14)
  self.plate([(-.12,.04),(.10,.08),(.14,-.10),(0,-.17),(-.13,-.08)],-(.49 if ogre else .29),.045,iron,1)
  self.tube((-.37 if ogre else -.28,.38,-.28),(.34 if ogre else .27,-.07,-.29),.059,leather,2)
  self.plate([(-.07,.04),(.07,.04),(.09,-.08),(0,-.14),(-.09,-.08)],-.335,.025,bronze,2)
  # Broad jaw, forward muzzle, heavy brow, pointed ears and paired tusks.
  h=1.30 if ogre else 1.0
  self.loft([(-.26*h,.15*h,.16*h,0,-.04),(-.17*h,.25*h,.21*h,0,-.06),(.04*h,.23*h,.205*h,0,-.02),(.23*h,.20*h,.16*h,0,0),(.30*h,.12*h,.11*h,0,.015)],skin,3,16)
  self.ell((0,-.12*h,-.207*h),(.225*h,.115*h,.10*h),light,3,12)
  self.ell((0,.025*h,-.215*h),(.083*h,.080*h,.078*h),skin,3,10)
  self.tube((-.13*h,-.12*h,-.302*h),(.13*h,-.12*h,-.302*h),.016*h,dark,3,6)
  for s in [-1,1]:
   self.plate([(s*.18*h,.11*h),(s*.47*h,.24*h),(s*.32*h,-.035*h),(s*.20*h,-.06*h)],.005,.075,skin,3)
   self.plate([(s*.25*h,.11*h),(s*.41*h,.19*h),(s*.30*h,.03*h)],-.04,.016,light,3)
   self.ell((s*.112*h,.087*h,-.207*h),(.065*h,.038*h,.031*h),dark,3,10)
   self.ell((s*.112*h,.088*h,-.235*h),(.038*h,.021*h,.012*h),color('dfbb59'),3,8)
   self.ell((s*.113*h,.088*h,-.247*h),(.014*h,.020*h,.008*h),dark,3,6)
   self.tube((s*.04*h,.14*h,-.22*h),(s*.20*h,.19*h,-.17*h),.031*h,skin,3)
   self.spike((s*.14*h,-.20*h,-.27*h),(s*.19*h,.025*h,-.32*h),.043*h,bone,3)
   # Sculpted cheekbones, nostrils and raised lids give the face expression.
   self.ell((s*.192*h,-.009*h,-.158*h),(.069*h,.083*h,.046*h),skin,3,12)
   self.ell((s*.049*h,.002*h,-.274*h),(.028*h,.018*h,.014*h),dark,3,8)
   self.ell((s*.124*h,.084*h,-.257*h),(.008*h,.008*h,.004*h),bone,3,6)
   for y in [-.015,.045]:
    self.tube((s*.23*h,y*h,-.177*h),(s*.18*h,(y-.02)*h,-.222*h),.009*h,light,3,6)
  for x in [-.08,0,.08]:
   self.plate([(x-.023,-.112*h),(x+.023,-.112*h),(x+.018,-.157*h),(x-.018,-.157*h)],-.319*h,.015,bone,3)
  if ogre:
   self.ell((0,-.29,-.18),(.15,.09,.11),skin,3,12)
   for x in [-.10,0,.10]:self.spike((x,.32,.05),(x,.43,.15),.065,dark,3)
   # Broad ivory war paint; readable at phone scale and entirely blood-free.
   paint=color('d0c393');self.surfaces[paint]='cloth'
   for s in [-1,1]:
    self.plate([(s*.17,.01),(s*.23,-.006),(s*.22,-.19),(s*.16,-.16)],-.304,.008,paint,3)
    self.tube((s*.042,.292,-.142),(s*.09,.26,-.195),.012,light,3,8)
  elif self.guard or self.spear:
   self.loft([(.19,.245,.21,0,.04),(.29,.21,.18,0,.04),(.38,.10,.10,0,.06)],iron,3,12)
   self.spike((-.19,.27,.05),(-.36,.53,.08),.057,edge,3)
   self.spike((.19,.27,.05),(.35,.51,.08),.057,edge,3)
  else:
   for z,y in [(-.08,.26),(.02,.28),(.12,.22),(.20,.12)]:self.spike((0,y,z),(0,y+.16,z+.09),.065,dark,3)
   self.tube((-.20,.19,-.085),(.20,.19,-.085),.028,leather,3)
  # Bare muscular arms, one oversized salvaged pauldron, bound forearms.
  for upper,fore,hand,s in [(4,5,6,-1),(7,8,9,1)]:
   r=.205 if ogre else (.10 if arch else .145);length=.47 if ogre else .30
   self.loft([(-length,r*.74,r*.82,0,0),(-length*.3,r*1.22,r*1.20,0,0),(.04,r,r,0,0)],skin,upper,12)
   self.loft([(-(.36 if ogre else .23),r*.72,r*.73,0,0),(.02,r*.90,r*.91,0,0)],skin,fore,12)
   for y in [-.17,-.10,-.035]:self.loft([(y,r*.95,r*.95,0,0),(y+.035,r*.95,r*.95,0,0)],leather,fore,10)
   self.ell((0,-.025,-.035),(.15 if ogre else .102,.145 if ogre else .11,.13 if ogre else .10),skin,hand,10)
   for x in [-.075,0,.075] if ogre else [-.05,0,.05]:self.ell((x,-.09,-.095),(.035,.068,.042),light,hand,8)
   if s<0 and not arch:
    self.ell((-.04,.07,.015),(.36 if ogre else .29,.18,.31 if ogre else .23),iron,upper,14)
    for x in [-.19,0,.16]:self.spike((x,.15,.03),(x*1.4,.43 if ogre else .35,.08),.058 if ogre else .044,edge,upper)
   elif not arch:self.loft([(-.13,r*1.11,r*1.13,0,0),(-.04,r*1.13,r*1.15,0,0)],iron,upper,12)
   if ogre:
    self.ell((s*.025,-.16,-.105),(.16,.215,.13),skin,upper,14)
    self.loft([(-.33,.175,.16,0,0),(-.28,.19,.19,0,0),(-.055,.18,.18,0,0)],iron,fore,12)
    for y in [-.30,-.08]:self.loft([(y,.19,.195,0,0),(y+.032,.19,.195,0,0)],bronze,fore,12)
    for x in [-.105,.105]:self.ell((x,-.18,-.173),(.029,.032,.024),bronze,fore,8)
  for thigh,shin,foot in [(10,11,12),(13,14,15)]:
   self.loft([(-(.53 if ogre else .36),.15 if ogre else .10,.16 if ogre else .11,0,0),(.015,.24 if ogre else .145,.22 if ogre else .135,0,0)],skin if ogre else leather,thigh,12)
   self.loft([(-(.45 if ogre else .33),.12 if ogre else .08,.13 if ogre else .09,0,0),(.01,.19 if ogre else .13,.18 if ogre else .12,0,0)],skin if ogre else leather,shin,12)
   if not ogre:self.plate([(-.10,.0),(.10,.0),(.075,-.30),(-.075,-.30)],-.125,.045,iron,shin)
   self.ell((0,0,-.10),(.19 if ogre else .12,.125 if ogre else .09,.28 if ogre else .22),skin if ogre else leather,foot,12)
   if ogre:
    for x in [-.13,-.045,.045,.13]:self.ell((x,-.025,-.30),(.055,.064,.09),light,foot,8)
  if arch:
   self.loft([(-.27,.11,.11,-.25,.28),(.27,.14,.13,-.25,.28)],leather,2,10)
   for j in range(4):
    x=-.32+j*.047;self.tube((x,.12,.29),(x,.62,.29),.014,wood,2)
    self.plate([(x-.03,.47),(x+.025,.54),(x+.03,.65),(x-.025,.57)],.29,.018,bone,2)
   points=[(0,-.92,.36),(0,-.66,.17),(0,-.36,.04),(0,0,0),(0,.37,.04),(0,.69,.20),(0,.93,.38)]
   for a,b in zip(points,points[1:]):self.tube(a,b,.039,wood,9,8)
   self.tube(points[0],points[-1],.009,bone,9,5);self.tube((0,.03,.2),(0,.03,-1.03),.016,bone,6,6)
  elif self.spear:
   self.tube((0,-.86,0),(0,1.63,0),.039,wood,9,8)
   self.loft([(1.49,.07,.055,0,0),(1.73,.13,.035,0,0),(2.1,.005,.005,0,0)],edge,9,4,smooth=False)
   self.spike((0,1.57,0),(.25,1.82,0),.047,iron,9)
   self.shield(.72,rust,iron,bone,6,round=True)
  elif ogre:
   self.ogre_weapon(wood,iron,edge)
  elif self.mounted:
   self.tube((0,-.32,.18),(0,.98,-.07),.048,wood,9,8)
   self.plate([(-.08,.70),(.24,.60),(.49,.85),(.35,1.13),(.10,1.0),(-.08,1.0)],0,.12,iron,9)
   self.shield(.86,rust,iron,bone,6,round=True)
   self.warg(leather,iron,bone,dark)
  else:
   self.tube((0,-.29,0),(0,1.07,0),.048,wood,9,8)
   self.plate([(-.06,.65),(.21,.57),(.47,.74),(.53,1.18),(.28,1.04),(-.06,.95)],0,.115,iron,9)
   self.plate([(.41,.74),(.51,.80),(.53,1.18),(.41,1.10)],-.004,.12,edge,9)
   if self.guard:self.guard_shield(wood,iron,bone,6)
   else:self.shield(.96,wood,iron,bone,6,round=True)
  if ogre:
   for x in [-.31,0,.31]:
    self.plate([(x-.14,-.16),(x+.14,-.16),(x+.14,-.34),(x,-.55),(x-.14,-.34)],-.46,.036,leather,1)
    self.ell((x,-.235,-.49),(.037,.037,.019),bronze,1,8)
   self.plate([(-.17,-.01),(.17,-.01),(.18,-.14),(0,-.25),(-.18,-.14)],-.497,.07,iron,1)
  return self

 def ogre_weapon(self,wood,iron,edge):
  self.tube((0,-.32,0),(0,1.05,0),.091,wood,9,10)
  self.loft([(.47,.13,.13,0,0),(.78,.23,.20,.015,0),(1.16,.30,.245,.02,0),(1.40,.23,.22,.015,0)],wood,9,12)
  for y,r in [(.73,.23),(1.12,.30),(1.33,.26)]:self.loft([(y,r,.25,0,0),(y+.085,r,.25,0,0)],iron,9,12)
  for x in [-.17,.17]:
   for y in [.86,1.20]:self.spike((x,y,-.15),(x*1.45,y+.04,-.40),.065,edge,9)

 def guard_shield(self,wood,iron,bone,joint):
  outline=[(-.45,.62),(-.30,.78),(.25,.74),(.47,.51),(.40,-.56),(0,-.76),(-.41,-.56)]
  self.plate(outline,-.18,.13,iron,joint)
  self.plate([(x*.87,y*.91) for x,y in outline],-.265,.05,wood,joint)
  for x in [-.22,0,.22]:self.bar((x,-.005,-.304),(.025,1.04,.025),iron,joint)
  for y in [-.40,.41]:
   self.bar((0,y,-.325),(.76,.075,.065),iron,joint)
   for x in [-.31,.31]:self.ell((x,y,-.375),(.048,.042,.026),bone,joint,8)
  self.plate([(-.21,.24),(0,.06),(.21,.26),(.09,-.22),(0,-.35),(-.11,-.20)],-.365,.028,bone,joint)

 def warg(self,leather,iron,bone,dark):
  fur=color('4d5954');mane=color('303c3a');muzzle=color('798071')
  self.surfaces.update({fur:'fur',mane:'fur',muzzle:'skin'})
  self.ell((0,.02,0),(.43,.40,.80),fur,24,14)
  self.ell((0,.15,-.48),(.46,.49,.44),mane,24,14)
  self.loft([(-.20,.31,.32,0,.02),(.15,.29,.31,0,-.1),(.46,.21,.21,0,-.2)],fur,25,12)
  self.ell((0,-.07,-.11),(.25,.27,.34),fur,26,12)
  self.ell((0,-.17,-.43),(.195,.15,.29),muzzle,26,12)
  self.ell((0,-.115,-.67),(.12,.078,.067),dark,26,10)
  self.tube((-.145,-.21,-.43),(.145,-.21,-.43),.032,dark,26)
  for s in [-1,1]:
   self.spike((s*.14,.12,.03),(s*.22,.49,.09),.10,mane,26)
   self.ell((s*.223,.06,-.20),(.04,.031,.06),color('d4ab50'),26,8)
   self.spike((s*.16,-.21,-.36),(s*.15,-.39,-.42),.039,bone,26)
   self.tube((s*.23,-.05,-.25),(s*.25,.20,.18),.026,leather,26)
   self.tube((s*.22,.05,-.12),(s*.27,.30,.52),.016,leather,25)
  for z in [-.38,-.10,.19,.40]:self.spike((0,.32,z),(0,.56,z+.23),.145,mane,24)
  self.tube((0,0,0),(0,-.12,.59),.13,mane,27,9)
  self.spike((0,-.09,.46),(0,-.3,.80),.11,fur,27)
  self.ell((0,.42,.10),(.34,.14,.35),leather,24,12)
  for s in [-1,1]:self.drape((s*.39,.29,.12),.78,.38,color('873b29'),24,side=True)
  for up,knee in [(28,29),(30,31),(32,33),(34,35)]:
   self.loft([(-.43,.08,.09,0,0),(.04,.17,.16,0,0)],fur,up,12)
   self.loft([(-.36,.07,.08,0,0),(.04,.10,.11,0,0)],fur,knee,10)
   self.ell((0,-.41,-.08),(.14,.11,.22),mane,knee,10)
   for x in [-.085,0,.085]:self.spike((x,-.42,-.19),(x,-.43,-.31),.025,bone,knee)

 def ready(self):
  p=super().ready()
  if self.ogre:p.update({2:(.13,0,0),3:(-.13,0,0),7:(.24,0,.31),8:(-.25,0,0),4:(.25,0,-.35),5:(.20,0,0),6:(-.20,0,0)})
  return p

 def animation_specs(self):
  specs=super().animation_specs()
  if not self.ogre:return specs
  result=[]
  for name,duration,tracks in specs:
   if name in ('walk','run'):duration=1.1 if name=='walk' else .91
   if name in ('attack_a','attack_b'):
    duration=1.7
    tracks[7]=[(.24,0,.31),(2.0,-.18,.52),(1.16,.12,.21),(.67,0,.28),(.24,0,.31)]
    tracks[8]=[(-.25,0,0),(-1.07,0,0),(.10,0,0),(.08,0,0),(-.25,0,0)]
    tracks[9]=[(0,0,0),(-.40,0,0),(-2.9,0,0),(-1.90,0,0),(0,0,0)]
   result.append((name,duration,tracks))
  return result

if __name__=='__main__':
 for kind in KINDS:HordeModel(kind).build().save()
