extends SceneTree
var triangles:Array=[]
func _initialize():call_deferred("run")
func run():
	var game=load("res://scenes/battle/battle.tscn").instantiate();root.add_child(game)
	await process_frame
	walk(game.castle)
	var out: String=ProjectSettings.globalize_path("res://../docs/fortress-geometry-review.json")
	var file:=FileAccess.open(out,FileAccess.WRITE);file.store_string(JSON.stringify(triangles));file.close()
	print("FORTRESS GEOMETRY: ",triangles.size()," triangles")
	game.queue_free();await process_frame;quit()
func walk(node: Node):
	if node is MeshInstance3D and node.visible and node.mesh:
		for surface in node.mesh.get_surface_count():
			var a:Array=node.mesh.surface_get_arrays(surface)
			var verts:PackedVector3Array=a[Mesh.ARRAY_VERTEX];var indices:PackedInt32Array=a[Mesh.ARRAY_INDEX] if a[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
			var material:Material=node.get_active_material(surface)
			var color:Color=material.albedo_color if material is StandardMaterial3D else Color.GRAY
			if node is ClothBanner:color=Color("18506e")
			var texture_path:String=material.albedo_texture.resource_path.get_file() if material is StandardMaterial3D and material.albedo_texture else ""
			var count:int=indices.size() if indices.size()>0 else verts.size()
			for i in range(0,count,3):
				var tri:Array=[]
				for k in 3:
					var index:int=indices[i+k] if indices.size()>0 else i+k
					var p:Vector3=node.global_transform*verts[index];tri.append([p.x,p.y,p.z])
				tri.append([color.r,color.g,color.b]);tri.append(texture_path);triangles.append(tri)
	for child in node.get_children():walk(child)
