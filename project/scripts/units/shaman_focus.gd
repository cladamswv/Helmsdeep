class_name ShamanFocus
extends BoneAttachment3D
## The ember and projectile origin follow the animated staff hand.
var caster: Node3D
var tip: MeshInstance3D
var material: ShaderMaterial
var clock := 0.0
func _ready():
	tip=MeshInstance3D.new();tip.name="StaffEmber"
	var mesh:=SphereMesh.new();mesh.radius=.14;mesh.height=.40;mesh.radial_segments=12;mesh.rings=6
	tip.mesh=mesh;tip.position=Vector3(0,caster.data.staff_tip,0)
	material=ShaderMaterial.new();material.shader=load("res://assets/materials/ember_fire.gdshader")
	tip.material_override=material;tip.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	tip.extra_cull_margin=.2;add_child(tip)
func _process(delta: float):
	clock+=delta
	var intensity:=.18
	if is_instance_valid(caster) and caster.hp>0 and caster.windup>=0:
		intensity=lerpf(.25,.92,1.0-clampf(caster.windup/caster.data.hit_time,0,1))
	if is_instance_valid(caster) and caster.boss_combat and caster.boss_combat.windup>=0:intensity=.85
	material.set_shader_parameter("phase",clock)
	material.set_shader_parameter("strength",intensity)
	tip.scale=Vector3.ONE*(.80+intensity*.30)*caster.data.focus_scale
func origin() -> Vector3:
	return tip.global_position
