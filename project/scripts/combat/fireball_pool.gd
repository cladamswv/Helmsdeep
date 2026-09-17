class_name FireballPool
extends Node3D
## A fixed pool, stepped by ProjectilePool so pause and accelerated tests agree.
## Fireballs remain alive after their caster falls; damage occurs on arrival.
const CAPACITY := 16
var battle: Node3D
var slots: Array[Dictionary] = []
func _ready():
	var mesh:=SphereMesh.new();mesh.radius=.22;mesh.height=.53;mesh.radial_segments=12;mesh.rings=6
	var shader:Shader=load("res://assets/materials/ember_fire.gdshader")
	for i in CAPACITY:
		var visual:=Node3D.new();visual.visible=false;add_child(visual)
		var material:=ShaderMaterial.new();material.shader=shader
		material.set_shader_parameter("strength",.72)
		var tail_material:ShaderMaterial=material.duplicate()
		tail_material.set_shader_parameter("strength",.30);tail_material.set_shader_parameter("opacity",.46)
		for j in 3:
			var flame:=MeshInstance3D.new();flame.mesh=mesh
			flame.material_override=material if j==0 else tail_material
			flame.position.y=-j*.28;flame.scale=Vector3.ONE*(1.0-j*.20)
			if j>0:flame.scale.y*=1.6
			flame.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			flame.extra_cull_margin=.15;visual.add_child(flame)
		slots.append({"node":visual,"material":material,"tail_material":tail_material,"active":false,"t":0.0})
func launch(start: Vector3, target: Node3D, damage: float, hostile: bool, definition: UnitData) -> bool:
	for slot in slots:
		if slot.active:continue
		slot.active=true;slot.t=0.0;slot.start=start
		slot.area=false
		slot.end=target.impact_point() if target is UnitController else target.global_position+Vector3.UP
		slot.target=weakref(target);slot.damage=damage;slot.hostile=hostile
		slot.radius=definition.projectile_splash_radius;slot.fraction=definition.projectile_splash_fraction
		slot.splash_targets=definition.projectile_splash_targets
		slot.duration=maxf(.22,start.distance_to(slot.end)/definition.projectile_speed)
		slot.node.global_position=start;slot.node.scale=Vector3.ONE*.45
		slot.node.quaternion=Quaternion(Vector3.UP,(slot.end-start).normalized())
		slot.material.set_shader_parameter("phase",0.0);slot.tail_material.set_shader_parameter("phase",0.0)
		slot.node.visible=true
		return true
	return false
func launch_area(start: Vector3, center: Vector3, damage: float, structure_damage: float, radius: float, limit: int, hostile: bool) -> bool:
	for slot in slots:
		if slot.active:continue
		slot.active=true;slot.t=0.0;slot.start=start;slot.end=center+Vector3.UP*.2
		slot.target=weakref(null);slot.area=true;slot.center=center
		slot.damage=damage;slot.structure_damage=structure_damage;slot.hostile=hostile
		slot.radius=radius;slot.splash_targets=limit
		slot.duration=maxf(.4,start.distance_to(slot.end)/11.0)
		slot.node.global_position=start;slot.node.scale=Vector3.ONE*.65
		slot.node.quaternion=Quaternion(Vector3.UP,(slot.end-start).normalized())
		slot.material.set_shader_parameter("phase",0.0);slot.tail_material.set_shader_parameter("phase",0.0)
		slot.node.visible=true;return true
	return false
func tick(delta: float):
	for slot in slots:
		if not slot.active:continue
		var target=slot.target.get_ref()
		if is_instance_valid(target) and target.hp>0:slot.end=target.impact_point() if target is UnitController else target.global_position+Vector3.UP
		slot.t+=delta/slot.duration
		var t:=minf(slot.t,1.0)
		var point:Vector3=slot.start.lerp(slot.end,t)+Vector3.UP*sin(t*PI)*.30
		var motion:Vector3=point-slot.node.global_position
		slot.node.global_position=point
		if motion.length_squared()>.00001:slot.node.quaternion=Quaternion(Vector3.UP,motion.normalized())
		slot.node.scale=Vector3.ONE*lerpf(.45,1.65 if slot.area else 1.0,minf(t/.12,1.0))
		slot.material.set_shader_parameter("phase",t*slot.duration)
		slot.tail_material.set_shader_parameter("phase",t*slot.duration+.27)
		if t>=1.0:
			impact(slot);slot.active=false;slot.node.visible=false
func impact(slot: Dictionary):
	if slot.area:
		impact_area(slot);return
	var primary=slot.target.get_ref()
	if is_instance_valid(primary) and primary.hp>0:
		if primary is CastleStructure or primary.enemy!=slot.hostile:primary.take_damage(slot.damage)
	var center:Vector3=primary.global_position if is_instance_valid(primary) else slot.end-Vector3.UP
	var nearby:Array[UnitController]=[]
	for candidate in battle.units:
		if candidate==primary or candidate.hp<=0 or candidate.enemy==slot.hostile:continue
		# Height separation prevents a ground blast splashing through battlements.
		if candidate.global_position.distance_to(center)<=slot.radius:nearby.append(candidate)
	nearby.sort_custom(func(a,b):return a.global_position.distance_squared_to(center)<b.global_position.distance_squared_to(center))
	for i in mini(int(slot.splash_targets),nearby.size()):nearby[i].take_damage(slot.damage*slot.fraction)
	battle.vfx.burst(slot.end,true,"fire")
	battle.audio.cue("fire_impact")
func impact_area(slot: Dictionary):
	var nearby:Array[UnitController]=[]
	for candidate in battle.units:
		if candidate.hp<=0 or candidate.enemy==slot.hostile:continue
		if candidate.global_position.distance_to(slot.center)<=slot.radius:nearby.append(candidate)
	nearby.sort_custom(func(a,b):return a.global_position.distance_squared_to(slot.center)<b.global_position.distance_squared_to(slot.center))
	for i in mini(int(slot.splash_targets),nearby.size()):nearby[i].take_damage(slot.damage)
	var structure:CastleStructure=battle.castle.structures.gate if battle.castle.structures.gate.hp>0 else battle.castle.structures.keep
	if structure.global_position.distance_to(slot.center)<=slot.radius:structure.take_damage(slot.structure_damage)
	# Four local bursts read as a ground firestorm without flashing the screen.
	for point in [Vector3.ZERO,Vector3(1.1,0,.6),Vector3(-.7,0,1.0),Vector3(.1,0,-1.0)]:battle.vfx.burst(slot.center+point,true,"fire")
	battle.audio.cue("fire_impact")
func clear():
	for slot in slots:slot.active=false;slot.t=0.0;slot.node.visible=false
