class_name VFXPool
extends Node3D
## Fixed storage: sparks, stone chips and soft dust share meshes. Effect time
## follows the paused scene tree, with no node allocation during combat.
var cosmetic_rng:=RandomNumberGenerator.new()
var slots: Array[Dictionary] = []
func _ready():
	var spark:=QuadMesh.new();spark.size=Vector2(.055,.26)
	var dust:=QuadMesh.new();dust.size=Vector2.ONE
	var chip:=PrismMesh.new();chip.size=Vector3(.12,.13,.10)
	for i in 96:
		var kind:="spark" if i<56 else ("chip" if i<76 else "dust")
		var node:=MeshInstance3D.new();var mat:=StandardMaterial3D.new()
		node.mesh={"spark":spark,"chip":chip,"dust":dust}[kind]
		mat.albedo_color=Color("fff0bb") if kind=="spark" else Color("a58c67")
		mat.roughness=.95;mat.cull_mode=BaseMaterial3D.CULL_DISABLED
		if kind!="chip":
			mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.billboard_mode=BaseMaterial3D.BILLBOARD_ENABLED
			mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		if kind=="spark":mat.albedo_color=Color("f2c888")
		if kind=="dust":mat.albedo_texture=load("res://assets/materials/dust_soft.png")
		node.material_override=mat;node.visible=false;node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(node)
		slots.append({"node":node,"mat":mat,"kind":kind,"life":0.0,"duration":1.0,"velocity":Vector3.ZERO,"base":1.0})
func burst(pos: Vector3, heavy: bool=false, element: String="physical"):
	var wanted:Dictionary={"spark":5 if heavy else 2,"chip":9 if heavy else 0,"dust":4 if heavy else 1}
	if element=="fire":wanted={"spark":5,"chip":0,"dust":3}
	for s in slots:
		if s.life>0 or wanted[s.kind]<=0:continue
		wanted[s.kind]-=1
		s.duration=(.95 if heavy else .42) if s.kind=="dust" else (.65 if s.kind=="chip" else .22)
		s.life=s.duration;s.node.visible=true;s.node.position=pos
		s.base=(1.25 if heavy else .32) if s.kind=="dust" else (1.5 if heavy else 1.0)
		s.node.scale=Vector3.ONE*s.base*(.45 if s.kind=="dust" else 1.0)
		var spread:float=.60 if s.kind=="dust" else (3.0 if heavy else 1.8)
		s.velocity=Vector3(cosmetic_rng.randf_range(-spread,spread),cosmetic_rng.randf_range(.4,1.1) if s.kind=="dust" else cosmetic_rng.randf_range(1.2,3.5),cosmetic_rng.randf_range(-spread,spread))
		# Reused dust must start transparent at its initial size, not flash once
		# at full size/opacity before _process applies its fade and growth.
		s.mat.albedo_color=(Color("f28c2d") if s.kind=="spark" else Color("b47a49")) if element=="fire" else (Color("f2c888") if s.kind=="spark" else Color("a58c67"))
		s.mat.albedo_color.a=0.0 if s.kind=="dust" else .82
func _process(delta: float):
	for s in slots:
		if s.life<=0:continue
		s.life=maxf(0.0,s.life-delta)
		var t:float=1.0-s.life/s.duration
		if s.kind=="dust":
			s.node.scale=Vector3.ONE*s.base*(.45+t*1.4)
			s.mat.albedo_color.a=minf(1.0,t/.16)*(1.0-t)*.44
		else:
			s.velocity.y-=9.8*delta
			if s.kind=="spark":s.mat.albedo_color.a=(1.0-t)*.82;s.node.scale=Vector3(s.base,s.base*(1.0-t*.75),s.base)
			else:s.node.rotate_x(delta*5);s.node.rotate_z(delta*3)
		s.node.position+=s.velocity*delta;s.node.visible=s.life>0
