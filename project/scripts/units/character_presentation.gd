class_name CharacterPresentation
extends RefCounted
## glTF vertex colors exist, but this importer leaves albedo use disabled.
## Share one corrected material per imported surface across units and portraits.
static var materials: Dictionary = {}
static func apply(node: Node):
	if node is MeshInstance3D and node.mesh:
		# Weapons and ogre arms move beyond the rest-pose bounds during swings.
		node.extra_cull_margin=2.0
		for i in node.mesh.get_surface_count():
			var original: Material = node.mesh.surface_get_material(i)
			if not original is StandardMaterial3D: continue
			var key: int = original.get_instance_id()
			if not materials.has(key):
				var mat: StandardMaterial3D = original.duplicate()
				mat.vertex_color_use_as_albedo = true
				mat.vertex_color_is_srgb = true
				mat.albedo_color = Color.WHITE
				mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
				# Preserve the authored ORM map: cloth stays matte while steel reflects
				# the sky. Overriding these values made every surface look like plastic.
				materials[key] = mat
			node.set_surface_override_material(i, materials[key])
	for child in node.get_children(): apply(child)
