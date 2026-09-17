class_name ContactShadow
extends MeshInstance3D
static var soft_material: StandardMaterial3D
static var footprint: PlaneMesh
func _init():
	if not soft_material:
		soft_material=StandardMaterial3D.new()
		soft_material.albedo_texture=load("res://assets/materials/contact_shadow.png")
		soft_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		soft_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		soft_material.disable_receive_shadows=true
		soft_material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		footprint=PlaneMesh.new();footprint.size=Vector2(1.05,1.0)
	mesh=footprint;material_override=soft_material;position.y=.018
	cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
