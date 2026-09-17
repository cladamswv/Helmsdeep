class_name ProjectilePool
extends Node3D
var fireballs: FireballPool
var slots: Array[Dictionary] = []
func _ready():
	# One shared mesh with a shaft, steel point and crossed feather vanes.
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var shaft:=CylinderMesh.new();shaft.top_radius=.012;shaft.bottom_radius=.017;shaft.height=.56;shaft.radial_segments=6
	var tip:=CylinderMesh.new();tip.bottom_radius=.055;tip.top_radius=0;tip.height=.16;tip.radial_segments=4
	for piece in [[shaft,Transform3D.IDENTITY,Color("b99055")],[tip,Transform3D(Basis.IDENTITY,Vector3(0,.36,0)),Color("c9d7df")]]:
		var array:Array=piece[0].surface_get_arrays(0);var vertices:PackedVector3Array=array[Mesh.ARRAY_VERTEX];var indices:PackedInt32Array=array[Mesh.ARRAY_INDEX]
		for index in indices:st.set_color(piece[2]);st.add_vertex(piece[1]*vertices[index])
	for axis in [Vector3.RIGHT,Vector3.FORWARD]:
		for sign_value in [-1,1]:
			for point in [Vector3(0,-.27,0),Vector3(0,-.13,0),Vector3(0,-.23,0)+axis*sign_value*.085]:
				st.set_color(Color("e8deba"));st.add_vertex(point)
	st.generate_normals();var mesh:=st.commit()
	var mat:=StandardMaterial3D.new();mat.vertex_color_use_as_albedo=true;mat.vertex_color_is_srgb=true;mat.roughness=.65;mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	for i in 128:
		var arrow := MeshInstance3D.new()
		arrow.mesh = mesh
		arrow.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		arrow.material_override = mat; arrow.visible = false; add_child(arrow)
		slots.append({"node":arrow,"active":false,"t":0.0})
	fireballs=FireballPool.new();fireballs.battle=get_parent();add_child(fireballs)
func launch(start: Vector3, target: Node3D, damage: float):
	for slot in slots:
		if slot.active: continue
		slot.active = true; slot.t = 0.0; slot.start = start
		slot.end = target.impact_point() if target is UnitController else target.global_position+Vector3.UP
		slot.target = weakref(target); slot.damage = damage
		slot.duration = maxf(0.18, start.distance_to(slot.end) / 16.0)
		slot.node.global_position = start; slot.node.visible = true
		return
func _process(delta: float):
	fireballs.tick(delta)
	for s in slots:
		if not s.active: continue
		var moving_target = s.target.get_ref()
		if is_instance_valid(moving_target) and moving_target.hp>0:
			s.end=moving_target.impact_point() if moving_target is UnitController else moving_target.global_position+Vector3.UP*1.2
		s.t += delta / s.duration
		var t := minf(s.t, 1.0)
		var p: Vector3 = s.start.lerp(s.end, t) + Vector3.UP * sin(t * PI) * 1.25
		var velocity: Vector3 = p - s.node.global_position
		s.node.global_position = p
		if velocity.length_squared() > 0.0001:
			s.node.quaternion = Quaternion(Vector3.UP, velocity.normalized())
		if t >= 1.0:
			var target = s.target.get_ref()
			if is_instance_valid(target) and target.hp > 0:
				if target is UnitController:target.take_damage(s.damage,true)
				else:target.take_damage(s.damage)
			s.active = false; s.node.visible = false
func clear():
	fireballs.clear()
	for s in slots: s.active = false; s.node.visible = false
