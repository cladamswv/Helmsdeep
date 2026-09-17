extends SceneTree
var failures:=0
func _initialize():call_deferred("run")
func check(ok: bool,label: String):
	if ok:print("PASS: "+label)
	else:push_error("FAIL: "+label);failures+=1
func first_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:return node
	for child in node.get_children():
		var found:=first_mesh(child)
		if found:return found
	return null
func ids(entries: Array) -> Array:
	var result:Array=[]
	for entry in entries:
		if entry.id not in result:result.append(entry.id)
	return result
func run():
	var game=load("res://scenes/battle/battle.tscn").instantiate();root.add_child(game)
	await process_frame;game.set_physics_process(false);game.audio.muted=true
	for unit in game.units:unit.set_physics_process(false)
	var data:Dictionary=game.balance
	var late:=WaveDirector.composition(44,data)
	check(late.size()>6+floori(44*.16) and ids(late).size()>=5,"wave 44 has more attackers and at least five distinct threats")
	var early_ogre:=false
	for n in range(1,12):early_ogre=early_ogre or "ogre" in ids(WaveDirector.composition(n,data))
	check(not early_ogre and "ogre" in ids(WaveDirector.composition(12,data)),"the first siege ogre arrives at wave 12, after basic counters")
	check("orc_guard" in ids(WaveDirector.composition(5,data)) and "mounted_raider" in ids(WaveDirector.composition(8,data)),"shielded orcs and wargs have staged introductions")
	var director:=WaveDirector.new(data);director.reset();director.wave=9;director.start_wave()
	var spawned:Array=[];director.reinforcement.connect(func(id,index,w):spawned.append([id,index,w]))
	director.tick(.01,0)
	check(spawned.size()==5 and spawned[0][1]!=spawned[4][1],"later reinforcements arrive as a five-lane formation")
	var old:=director.snapshot();old.erase("spawn_batch");director.restore(old)
	check(director.spawn_batch==1,"older checkpoints retain the original in-progress spawn cadence")
	var raider:UnitController=game.spawn("raider",true,Vector3(18,0,0));raider.set_physics_process(false)
	var ogre:UnitController=game.spawn("ogre",true,Vector3(17,0,2),12);ogre.set_physics_process(false)
	var guard:UnitController=game.spawn("orc_guard",true,Vector3(15,0,-2));guard.set_physics_process(false)
	var knight:UnitController=game.spawn("knight",false,Vector3(8,0,3));knight.set_physics_process(false)
	var hunter:UnitController=game.spawn("enemy_archer",true,Vector3(16,0,3));hunter.set_physics_process(false)
	check(knight.choose_target()==hunter,"knights can pursue hunters firing beyond the old 12-metre cutoff")
	hunter.position.x=22
	check(knight.choose_target()!=hunter,"mounted pursuit remains bounded before the enemy deployment road")
	check(first_mesh(ogre.visual).mesh.get_aabb().size.y*ogre.visual.scale.y>first_mesh(raider.visual).mesh.get_aabb().size.y*raider.visual.scale.y*1.25,"ogre geometry is visibly larger than an ordinary orc")
	check(is_equal_approx(ogre.animator.get_animation("attack_a").length*.5,ogre.data.hit_time),"ogre damage lands on the heavy club's animated contact frame")
	guard.take_damage(100);var melee_loss:=guard.max_hp-guard.hp;guard.hp=guard.max_hp
	game.projectiles.launch(Vector3(10,4,-2),guard,100);game.projectiles._process(2)
	check(is_equal_approx(guard.max_hp-guard.hp,melee_loss*.55),"Ironshield resistance is applied by actual arrow impacts, while melee bypasses it")
	guard.hp=80;game.targeting.incoming.clear();game.targeting.reserve(guard,100)
	check(not game.targeting.saturated(guard),"archers account for shields when reserving damage and choosing targets")
	var gate:CastleStructure=game.castle.structures.gate;ogre.position=gate.position+Vector3(2,0,0)
	ogre.target=gate;ogre.active=true;ogre.windup=ogre.data.hit_time;ogre.cooldown=ogre.data.interval;ogre.play("attack_a")
	var initial_gate:=gate.hp;ogre._physics_process(.84)
	check(gate.hp==initial_gate,"ogre windup gives an observable warning before structure damage")
	ogre._physics_process(.02)
	check(is_equal_approx(initial_gate-gate.hp,ogre.damage_against(gate)),"a landed club deals the configured 2.5-times structure damage")
	ogre._physics_process(.01)
	check(ogre.anim=="attack_a","the heavy club retains its follow-through instead of snapping to idle at contact")
	var fighters:Array[UnitController]=[]
	for i in 4:
		var unit:UnitController=game.spawn("swordsman",false,Vector3(11+i*.3,0,0));unit.set_physics_process(false);fighters.append(unit)
	ogre.position=Vector3(12,0,2);ogre.heavy_impact(fighters[0],64)
	var hurt:=0
	for unit in fighters:
		if unit.hp<unit.max_hp:hurt+=1
	check(hurt==2 and fighters[0].hp==fighters[0].max_hp,"club splash damages only two additional nearby ground defenders")
	game.vfx.slots[0].life=0
	for slot in game.vfx.slots:slot.life=0
	game.vfx.burst(Vector3.ZERO,true);var dust_ok:=true
	for slot in game.vfx.slots:
		if slot.kind=="dust" and slot.life>0:dust_ok=dust_ok and slot.mat.albedo_color.a==0 and is_equal_approx(slot.node.scale.x,slot.base*.45)
	check(dust_ok,"pooled dust begins transparent at its intended initial size, without a first-frame flash")
	game.vfx._process(.03);var softened:=true
	for slot in game.vfx.slots:
		if slot.kind=="dust" and slot.life>0:softened=softened and slot.mat.albedo_color.a>0 and slot.mat.albedo_color.a<.44
		if slot.kind=="spark":softened=softened and not slot.mat.emission_enabled
	check(softened,"dust fades in gradually and sparks do not add bright emission")
	check(game.camera.near>=.3 and game.camera.far<=150 and first_mesh(ogre.visual).extra_cull_margin>=2,"camera precision and animated mesh bounds are configured to reduce flicker")
	game.new_siege();game.set_physics_process(false)
	for id in game.HOSTILES:
		var unit:UnitController=game.spawn(id,true,Vector3(20,0,0),44);unit.set_physics_process(false)
	var state:Dictionary=game.snapshot()
	check(SaveManager.valid(state),"all old enemy IDs and new horde units validate in the existing save format")
	game.restore(state);var restored:={}
	for unit in game.units:
		unit.set_physics_process(false)
		if unit.enemy:restored[unit.data.id]=true
	check(restored.size()==game.HOSTILES.size() and restored.has("ogre") and restored.has("orc_guard"),"horde models and health restore from a saved battle")
	game.phase="tests_complete";game.audio.stop_all();await create_timer(.3,true).timeout
	game.queue_free();await process_frame
	print("HORDE COMPLETE failures=",failures);quit(failures)
