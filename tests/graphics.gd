extends SceneTree
var failures:=0
func _initialize():call_deferred("run")
func check(ok: bool,label: String):
	if ok:print("PASS: "+label)
	else:push_error("FAIL: "+label);failures+=1
func mesh_in(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:return node
	for child in node.get_children():
		var found:=mesh_in(child)
		if found:return found
	return null
func collect(node: Node,type: String,result: Array):
	if (type=="banner" and node is ClothBanner) or (type=="mesh" and node is MeshInstance3D):result.append(node)
	for child in node.get_children():collect(child,type,result)
func run():
	var game=load("res://scenes/battle/battle.tscn").instantiate();root.add_child(game)
	await process_frame;await process_frame;game.set_physics_process(false)
	var orm_ok:=true;var atlas_ok:=true;var shared_ok:=true;var surface_ok:=true
	for id in game.definitions:
		var model:Node3D=game.definitions[id].model.instantiate();root.add_child(model);CharacterPresentation.apply(model)
		var visual:=mesh_in(model);var mat:StandardMaterial3D=visual.get_active_material(0)
		orm_ok=orm_ok and mat.vertex_color_use_as_albedo and mat.metallic_texture!=null and mat.roughness_texture!=null and mat.roughness==1.0 and mat.metallic==1.0
		surface_ok=surface_ok and mat.albedo_texture!=null and mat.normal_enabled and mat.normal_texture!=null and mat.albedo_texture.get_width()==512 and mat.albedo_texture.get_image().has_mipmaps() and mat.texture_filter==BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		var uv:PackedVector2Array=visual.mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV]
		var entries:Dictionary={}
		for point in uv:entries[point]=true
		atlas_ok=atlas_ok and entries.size()>=3
		shared_ok=shared_ok and visual.mesh.get_surface_count()==1
		model.queue_free()
	check(orm_ok,"all sixteen classes preserve their authored color, roughness and metal textures")
	check(surface_ok,"every unit and boss imports the 512-pixel surface atlas and normal detail with mipmap filtering")
	check(atlas_ok,"cloth and polished metal address different regions of the material atlas")
	check(shared_ok,"each complete character remains one mesh surface including mounted knights")
	var meshes:Array=[];collect(game.castle,"mesh",meshes);var textured:=0
	for node in meshes:
		var mat:Material=node.get_active_material(0)
		if mat is StandardMaterial3D and mat.normal_enabled and mat.normal_texture and mat.albedo_texture and mat.uv1_world_triplanar:textured+=1
	check(textured>15,"castle batches retain albedo and normal maps with world-scaled stone detail")
	var banners:Array=[];collect(game.castle,"banner",banners)
	game.vfx.burst(Vector3(0,1,0),true);var before:float=banners[0].clock;var life:float=game.vfx.slots[0].life
	game.set_paused(true);await create_timer(.15,true).timeout
	check(banners.size()>=5 and banners[0].clock==before and game.vfx.slots[0].life==life,"pause freezes cloth wind and new impact effects")
	game.set_paused(false);await create_timer(.05).timeout
	check(banners[0].clock>before and game.vfx.slots[0].life<life,"Resume advances cloth and impacts from the frozen point")
	for i in 200:game.vfx.burst(Vector3(0,1,0),true)
	check(game.vfx.get_child_count()==96 and game.vfx.slots.size()==96,"repeated impacts cannot grow the effect pool")
	await create_timer(1.15).timeout
	var cleared:=true
	for slot in game.vfx.slots:cleared=cleared and slot.life==0 and not slot.node.visible
	check(cleared,"all spark, chip and dust slots return to the pool after fading")
	check(game.units[0].contact_shadow.material_override==game.units[1].contact_shadow.material_override,"troop contact shadows share their mesh material")
	print("GRAPHICS COMPLETE failures=",failures)
	game.audio.stop_all();await create_timer(.3,true).timeout
	game.queue_free();await process_frame;quit(failures)
