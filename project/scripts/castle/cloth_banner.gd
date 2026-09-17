class_name ClothBanner
extends MeshInstance3D
## One small shared grid per pennant. Explicit time respects scene-tree pause.
static var fabric_mesh: ArrayMesh
var clock:=0.0
func _ready():
	if not fabric_mesh:
		var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for row in 10:
			for col in 6:
				for corner in [Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,0),Vector2(1,1),Vector2(0,1)]:
					var uv:Vector2=(Vector2(col,row)+corner)/Vector2(6,10)
					var hem:=.16*(1.0-absf(uv.x*2.0-1.0))*pow(uv.y,8)
					st.set_uv(uv);st.add_vertex(Vector3(.085,.55-uv.y*1.05+hem,(uv.x-.5)*.64))
		st.generate_normals();fabric_mesh=st.commit()
	mesh=fabric_mesh
	extra_cull_margin=.12
	var fabric:=ShaderMaterial.new();fabric.shader=load("res://assets/materials/banner_cloth.gdshader");material_override=fabric
	clock=position.y*1.5+position.z;cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
func _process(delta: float):
	clock+=delta
	material_override.set_shader_parameter("wind_time",clock)
