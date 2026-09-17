class_name BossCombat
extends Node3D
## A boss owns its anticipation, recovery and fixed warning area. Combat time
## drives these effects: pausing never advances a shader or deals hidden damage.
var unit: UnitController
var spec: BossData
var cooldown := 4.0
var windup := -1.0
var recovery := 0.0
var summons := 0
var center := Vector3.ZERO
var ring: MeshInstance3D
var material: StandardMaterial3D
func setup(owner_unit: UnitController):
	unit=owner_unit;spec=unit.data.boss
	ring=MeshInstance3D.new();ring.name="AttackWarning";add_child(ring);ring.top_level=true
	var mesh:=ImmediateMesh.new();mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 64:
		if i%8==7:continue
		var a:=TAU*i/64.0;var b:=TAU*(i+1)/64.0
		var outer_a:=Vector3(cos(a),0,sin(a))*spec.radius
		var outer_b:=Vector3(cos(b),0,sin(b))*spec.radius
		for v in [outer_a,outer_a*.92,outer_b,outer_b,outer_a*.92,outer_b*.92]:mesh.surface_add_vertex(v)
	mesh.surface_end();ring.mesh=mesh
	material=StandardMaterial3D.new();material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode=BaseMaterial3D.CULL_DISABLED;material.albedo_color=Color("f1b850")
	ring.material_override=material;ring.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;ring.hide()
func busy() -> bool:
	return windup>=0 or recovery>0
func tick(delta: float) -> bool:
	if unit.hp<=0 or not unit.active or get_tree().paused:return false
	cooldown=maxf(0,cooldown-delta)
	if windup>=0:
		windup-=delta
		var progress:=1.0-maxf(0,windup)/spec.special_windup
		material.albedo_color=Color("d79b45").lerp(Color("ffe2a0"),progress)
		if windup<=0:
			windup=-1;strike();ring.hide();recovery=spec.special_duration-spec.special_windup
		return true
	if recovery>0:
		recovery=maxf(0,recovery-delta)
		return true
	if unit.windup>=0:return false
	var ready_to_roar:=spec.special_kind=="roar" and summons<spec.summon_thresholds.size() and unit.hp/unit.max_hp<=spec.summon_thresholds[summons]
	var victim:Node3D=unit.choose_target()
	var reachable:=is_instance_valid(victim) and unit.flat_distance(victim)<=unit.data.attack_range+.4
	if ready_to_roar or (spec.special_kind!="roar" and cooldown<=0 and reachable):
		center=unit.global_position if spec.special_kind in ["tail","roar"] else victim.global_position
		center.y=victim.global_position.y if spec.special_kind=="firestorm" and is_instance_valid(victim) else 0.0
		windup=spec.special_windup;cooldown=spec.special_interval
		unit.anim="";unit.play("special");unit.cooldown=maxf(unit.cooldown,spec.special_duration)
		ring.global_position=center+Vector3.UP*.08;ring.show()
		unit.battle.audio.cue("boss_roar" if spec.special_kind=="roar" else "horn")
		return true
	return false
func strike():
	var battle:Node3D=unit.battle
	if spec.special_kind=="roar":
		if summons<spec.summon_thresholds.size():
			summons+=1
			for id in spec.summon_ids:battle.director.pending.append({"id":id,"wave":unit.source_wave})
		battle.vfx.burst(unit.global_position+Vector3.UP*3,true)
		return
	if spec.special_kind=="firestorm":
		var origin:Vector3=unit.shaman_focus.origin() if is_instance_valid(unit.shaman_focus) else unit.global_position+Vector3.UP*5
		battle.projectiles.fireballs.launch_area(origin,center,spec.special_damage*unit.damage_scale,spec.structure_damage*unit.damage_scale,spec.radius,spec.target_limit,unit.enemy)
		battle.audio.cue("fire_cast")
		return
	var nearby:Array[UnitController]=[]
	for candidate in battle.units:
		if candidate.hp<=0 or candidate.enemy==unit.enemy:continue
		if candidate.global_position.distance_to(center)<=spec.radius:nearby.append(candidate)
	nearby.sort_custom(func(a,b):return a.global_position.distance_squared_to(center)<b.global_position.distance_squared_to(center))
	for i in mini(spec.target_limit,nearby.size()):
		var candidate:UnitController=nearby[i]
		candidate.take_damage(spec.special_damage*unit.damage_scale)
		if candidate.hp>0:
			var away:=candidate.global_position-unit.global_position;away.y=0
			candidate.position+=away.normalized()*spec.knockback
			candidate.position.z=clampf(candidate.position.z,-4.4,4.4)
	# Only the active strategic structure can be damaged, never the keep through
	# an intact gate and never all six castle components in a single splash.
	var structure:CastleStructure=battle.castle.structures.gate if battle.castle.structures.gate.hp>0 and unit.position.x>-4.5 else battle.castle.structures.keep
	if structure.global_position.distance_to(center)<=spec.radius:structure.take_damage(spec.structure_damage*unit.damage_scale)
	battle.vfx.burst(center+Vector3.UP*.5,true);battle.audio.cue("boss_slam")
func snapshot() -> Dictionary:
	return {"cooldown":cooldown,"windup":windup,"recovery":recovery,"summons":summons,"center":[center.x,center.y,center.z]}
func restore(state: Dictionary):
	if state.is_empty():return
	cooldown=float(state.cooldown);windup=float(state.windup);recovery=float(state.recovery);summons=int(state.summons)
	center=Vector3(state.center[0],state.center[1],state.center[2])
	if busy():
		unit.anim="";unit.play("special")
		if unit.animator:unit.animator.seek(spec.special_windup-windup if windup>=0 else spec.special_duration-recovery,true)
	ring.global_position=center+Vector3.UP*.08;ring.visible=windup>=0
