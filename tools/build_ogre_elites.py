"""Original ogre elites: a giant warthog mount and an ember-staff shaman.
Uses Castlehold's skinned glTF authoring code; no third-party geometry.
"""
from build_characters import Model, color
from build_horde import HordeModel

KINDS = ['ogre_warthog', 'ogre_shaman']

class OgreEliteModel(HordeModel):
 def __init__(self, kind):
  assert kind in KINDS
  super().__init__('ogre')
  self.kind=kind;self.shaman=kind=='ogre_shaman'
  if not self.shaman:
   self.mounted=True
   self.bones+=Model('mounted_raider').bones[24:]
   changes={1:(0,2.10,.15),10:(-.49,-.10,0),13:(.49,-.10,0),
    24:(0,1.03,.12),25:(0,.25,-.72),26:(0,.07,-.37),27:(0,.15,.94),
    28:(-.46,-.12,-.62),30:(.46,-.12,-.62),32:(-.48,-.10,.62),34:(.48,-.10,.62),
    29:(0,-.40,0),31:(0,-.40,0),33:(0,-.40,.02),35:(0,-.40,.02)}
   self.bones=[(name,p,changes.get(i,t)) for i,(name,p,t) in enumerate(self.bones)]
   self.world=[]
   for _,p,t in self.bones:self.world.append(tuple(t[i]+(self.world[p][i] if p>=0 else 0) for i in range(3)))

 def build(self):
  kind=self.kind
  self.kind='ogre'
  super().build()
  self.kind=kind
  if self.shaman:
   replacements={color('9a916c'):color('788d77'),color('b3aa7e'):color('b3b899'),color('913f2c'):color('654363')}
   self.colors=[replacements.get(c,c) for c in self.colors]
   self.finishes[color('788d77')]=(.76,0.)
   self.finishes[color('b3b899')]=(.76,0.)
   self.shaman_regalia()
  else:
   self.warthog()
   self.rider_armor()
  return self

 def ogre_weapon(self, wood, iron, edge):
  gold=color('b28b50');ivory=color('e8d4a0');ember=color('ffad42')
  self.surfaces.update({gold:'gold',ivory:'bone'})
  self.finishes[gold]=(.52,.62)
  if self.shaman:
   # Twisted staff ends in a three-pronged brazier around an ember crystal.
   points=[(0,-.88,0),(-.04,-.30,.03),(.04,.28,0),(-.03,.92,.025),(0,1.42,0)]
   for a,b in zip(points,points[1:]):self.tube(a,b,.069,wood,9,10)
   for y in [-.18,.08,.90,1.16]:self.loft([(y,.092,.092,0,0),(y+.055,.092,.092,0,0)],gold,9,10)
   for sign in [-1,1]:
    self.tube((0,1.21,0),(sign*.26,1.45,0),.056,gold,9,8)
    self.spike((sign*.26,1.45,0),(sign*.20,1.88,0),.046,ivory,9)
   self.tube((0,1.23,0),(0,1.52,.25),.052,gold,9,8)
   self.spike((0,1.52,.25),(0,1.91,.16),.044,ivory,9)
   self.loft([(1.42,.035,.035,0,0),(1.61,.15,.12,0,0),(1.90,.01,.01,0,0)],ember,9,6,smooth=False)
  else:
   # Broad, asymmetric crescent axe is legible above the mount's tusks.
   self.tube((0,-.39,0),(0,1.12,0),.074,wood,9,10)
   self.plate([(-.09,.63),(.24,.60),(.62,.79),(.67,1.23),(.38,1.10),(-.09,1.02)],0,.16,iron,9)
   self.plate([(.48,.75),(.62,.79),(.67,1.23),(.55,1.18)],-.01,.175,edge,9)
   for y in [-.14,.06,.52]:self.loft([(y,.088,.088,0,0),(y+.045,.088,.088,0,0)],gold,9,8)

 def rider_armor(self):
  iron=color('4b5554');edge=color('9baba6');gold=color('b28b50');rust=color('913f2c')
  self.loft([(.19,.33,.28,0,.05),(.37,.28,.24,0,.06),(.49,.12,.12,0,.06)],iron,3,12)
  self.loft([(.16,.34,.29,0,.05),(.22,.34,.29,0,.05)],gold,3,12)
  for sign in [-1,1]:
   self.spike((sign*.25,.30,.06),(sign*.49,.56,.16),.067,edge,3)
   self.plate([(sign*.17,.16),(sign*.32,.14),(sign*.29,-.13),(sign*.17,-.10)],-.16,.065,iron,3)
  self.drape((0,.08,.41),.85,.72,rust,2)
  self.loft([(-.28,.47,.30,0,-.15),(.16,.60,.34,0,-.10),(.32,.47,.27,0,-.06)],iron,2,14)
  self.plate([(-.19,.16),(0,.01),(.19,.18),(.11,-.17),(0,-.26),(-.11,-.17)],-.49,.045,gold,2)

 def shaman_regalia(self):
  robe=color('654363');trim=color('c39651');ivory=color('e8d4a0');wood=color('513726')
  self.surfaces.update({robe:'cloth',trim:'gold',ivory:'bone',wood:'wood'})
  self.finishes[trim]=(.52,.62)
  # Split robe, sculpted beard, fang charms and a branching headdress.
  for sign in [-1,1]:
   self.drape((sign*.26,-.09,-.46),.49,.96,robe,1)
   self.drape((sign*.26,-.87,-.50),.46,.12,trim,1)
   antler=[(sign*.21,.16,0),(sign*.31,.44,.05),(sign*.50,.64,.10)]
   for a,b in zip(antler,antler[1:]):self.tube(a,b,.053,wood,3,8)
   self.spike((sign*.50,.64,.10),(sign*.65,.93,.14),.050,ivory,3)
   self.spike((sign*.34,.47,.06),(sign*.77,.65,.04),.043,ivory,3)
   self.ell((sign*.29,.05,-.08),(.085,.11,.055),trim,3,8)
  self.loft([(-.58,.035,.038,0,-.24),(-.31,.14,.12,0,-.25),(-.22,.14,.09,0,-.24)],ivory,3,12)
  for sign in [-1,1]:
   self.loft([(-.60,.045,.045,sign*.14,-.19),(-.30,.065,.063,sign*.17,-.18)],wood,3,8)
   self.loft([(-.54,.052,.052,sign*.14,-.19),(-.48,.052,.052,sign*.14,-.19)],trim,3,8)
  for x,y in [(-.31,.11),(-.20,.025),(-.08,-.015),(.08,-.015),(.20,.025),(.31,.11)]:
   self.ell((x,y,-.34),(.070,.075,.043),trim,2,8)
   self.spike((x,y-.04,-.34),(x,y-.21,-.37),.039,ivory,2)
  self.plate([(-.13,-.18),(0,-.01),(.13,-.18),(0,-.38)],-.51,.035,trim,1)
  self.plate([(-.058,-.18),(0,-.10),(.058,-.18),(0,-.29)],-.535,.022,color('ed8c35'),1)

 def warthog(self):
  hide=color('755849');ridge=color('443d36');muzzle=color('b37d68')
  ivory=color('e8d4a0');iron=color('4b5554');edge=color('9baba6');strap=color('483527');gold=color('b28b50')
  self.surfaces.update({hide:'skin',ridge:'fur',muzzle:'skin',ivory:'bone',strap:'leather',gold:'gold'})
  self.finishes[hide]=(.76,0.);self.finishes[muzzle]=(.76,0.)
  self.ell((0,.06,.04),(.69,.55,1.04),hide,24,16)
  self.ell((0,.20,-.59),(.71,.61,.58),hide,24,14)
  self.ell((0,.02,0),(.53,.48,.55),hide,25,14)
  self.ell((0,-.025,-.09),(.48,.40,.53),hide,26,14)
  self.ell((0,-.10,-.49),(.35,.25,.35),hide,26,12)
  self.ell((0,-.065,-.77),(.30,.215,.063),muzzle,26,12)
  for sign in [-1,1]:
   self.ell((sign*.12,-.05,-.824),(.062,.091,.022),ridge,26,10)
   self.ell((sign*.43,.12,-.24),(.039,.054,.070),color('d8a749'),26,8)
   self.ell((sign*.457,.12,-.27),(.017,.030,.026),ridge,26,8)
   self.plate([(sign*.29,.26),(sign*.62,.52),(sign*.65,.25),(sign*.38,.02)],.06,.10,hide,26)
   self.plate([(sign*.40,.23),(sign*.58,.41),(sign*.58,.24)],-.001,.022,muzzle,26)
   a=(sign*.31,-.19,-.45);b=(sign*.56,-.015,-.71);c=(sign*.53,.28,-.80)
   self.tube(a,b,.097,ivory,26,9);self.tube(b,c,.074,ivory,26,9)
   self.spike(c,(sign*.42,.51,-.81),.052,ivory,26)
   self.spike((sign*.39,.10,-.27),(sign*.61,.15,-.35),.070,hide,26)
   self.tube((sign*.34,.06,-.63),(sign*.45,.37,.02),.037,strap,26,8)
   self.tube((sign*.45,.37,.02),(sign*.44,.50,.68),.029,strap,25,8)
   self.drape((sign*.64,.40,.28),1.03,.51,color('913f2c'),24,side=True)
   self.tube((sign*.51,.49,.22),(sign*.64,-.35,.22),.043,strap,24,8)
   self.ell((sign*.59,.10,-.62),(.14,.40,.40),iron,24,12)
   for z in [-.84,-.53]:self.ell((sign*.71,.11,z),(.024,.055,.056),gold,24,8)
  self.plate([(-.30,.30),(.30,.30),(.29,.10),(0,-.08),(-.29,.10)],-.44,.075,iron,26)
  for x in [-.20,0,.20]:self.ell((x,.22,-.49),(.033,.033,.025),gold,26,8)
  for z in [-.68,-.40,-.08,.27,.61]:self.spike((0,.52,z),(0,.78,z+.18),.12,ridge,24)
  self.ell((0,.59,.27),(.52,.15,.45),strap,24,14)
  self.tube((0,0,0),(0,-.08,.45),.049,hide,27,8)
  self.tube((0,-.08,.45),(.10,.05,.49),.042,hide,27,8)
  self.ell((.10,.05,.49),(.085,.082,.077),ridge,27,8)
  for up,knee in [(28,29),(30,31),(32,33),(34,35)]:
   self.loft([(-.38,.125,.15,0,0),(.03,.24,.25,0,0)],hide,up,12)
   self.loft([(-.32,.11,.12,0,0),(.03,.155,.16,0,0)],hide,knee,10)
   for x in [-.075,.075]:self.ell((x,-.40,-.06),(.069,.12,.19),ridge,knee,10)

 def ready(self):
  pose=super().ready()
  if self.shaman:
   pose.update({7:(.18,0,.38),8:(-.30,0,0),9:(.08,0,-.38),4:(.39,0,-.40),5:(.80,0,0),6:(-.85,0,0)})
  else:
   pose.update({10:(-.65,0,-.30),13:(-.65,0,.30),11:(1.05,0,0),14:(1.05,0,0),4:(.43,0,-.31),5:(.65,0,0),6:(-.86,0,0)})
  return pose

 def animation_specs(self):
  result=[]
  for name,duration,tracks in super().animation_specs():
   if self.shaman and name=='shoot':
    duration=1.6
    tracks.update({7:[(.18,0,.38),(.45,-.1,.32),(.90,.08,.22),(.56,0,.28),(.18,0,.38)],
     8:[(-.30,0,0),(-.45,0,0),(-.25,0,0),(-.30,0,0),(-.30,0,0)],
     9:[(.08,0,-.38),(0,0,-.32),(-.65,0,-.22),(-.26,0,-.28),(.08,0,-.38)],
     4:[(.39,0,-.40),(1.4,-.25,-.40),(1.5,.05,-.20),(1.0,0,-.35),(.39,0,-.40)],
     5:[(.80,0,0),(1.0,0,0),(.25,0,0),(.70,0,0),(.80,0,0)],
     2:[(.13,0,0),(.02,-.15,0),(.18,.13,0),(.15,.06,0),(.13,0,0)]})
   if not self.shaman and name in ('walk','run'):
    duration=.97 if name=='walk' else .70
    tracks[25]=[(.06,0,0),(.13,0,0),(.06,0,0),(-.03,0,0),(.06,0,0)]
    tracks[26]=[(0,0,0),(-.06,0,0),(0,0,0),(.06,0,0),(0,0,0)]
   result.append((name,duration,tracks))
  return result

if __name__=='__main__':
 for kind in KINDS:OgreEliteModel(kind).build().save()
