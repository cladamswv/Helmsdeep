extends SceneTree
var failures:=0
func check(ok: bool,label: String):
	if ok:print("PASS: "+label)
	else:push_error("FAIL: "+label);failures+=1
func _initialize():call_deferred("run")
func first_mesh(node: Node):
	if node is MeshInstance3D:return node
	for child in node.get_children():
		var mesh=first_mesh(child)
		if mesh:return mesh
	return null
func run():
	var game=load("res://scenes/battle/battle.tscn").instantiate();root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	check(game.units.size()==12 and game.phase=="gap","automatic siege starts with 12 defenders and a short countdown")
	check(game.balance.wave_count==100,"100 waves configured")
	var archer:UnitController=game.units[0]
	check(archer.animator.has_animation("shoot"),"skeletal bow-release animation imported")
	var mesh=first_mesh(archer.visual)
	check(mesh.get_active_material(0).vertex_color_use_as_albedo,"authored medieval material colors enabled")
	var stationary:=archer.position;archer.hp=50
	game.purchase("archer")
	check(game.economy.gold==440 and game.army.archer==7,"recruitment charges the displayed cost once")
	check(archer.position==stationary and archer.hp==50,"recruitment neither teleports nor heals existing troops")
	game.purchase("knight");check(game.army.knight==1 and game.units[-1].data.category=="cavalry","mounted knight can be recruited")
	check(game.units[-1].animator.has_animation("run"),"articulated horse locomotion imports")
	var knight:UnitController=game.units[-1]
	game.purchase("spearman");var spear:UnitController=game.units[-1]
	check(is_equal_approx(spear.damage_against(knight),spear.data.damage*2),"spearman has a functional cavalry counter")
	var foe_a:UnitController=game.spawn("raider",true,Vector3(4,0,0))
	var foe_b:UnitController=game.spawn("raider",true,Vector3(5,0,0))
	game.targeting.reserve(foe_a,1000)
	check(archer.choose_target()==foe_b,"archers spread fire away from enemies already covered by incoming arrows")
	foe_a.take_damage(100000);foe_b.take_damage(100000)
	game.economy.gold=0;var count:int=game.units.size();game.purchase("swordsman")
	check(game.units.size()==count and game.economy.gold==0,"recruitment cannot overspend")
	game.economy.gold=1000;game.castle.structures.gate.take_damage(1500);game.repair_gate()
	var repaired:float=game.castle.structures.gate.hp;game.repair_gate()
	check(repaired==1470 and game.castle.structures.gate.hp==repaired,"35 percent cumulative repair allowance per wave")
	game.castle.structures.keep.take_damage(200);game.repair_structure("keep")
	check(game.castle.structures.keep.hp==5000,"keep can be repaired during the continuous siege")
	game.director.start_wave();game.director.remaining=.02
	var existing:UnitController=game.spawn("raider",true,Vector3(16,0,0));var identity:int=existing.get_instance_id()
	var gold:int=game.economy.gold;game._physics_process(.03)
	check(game.phase=="gap" and game.economy.gold>gold,"timed assault ends and awards gold while enemies remain")
	check(is_instance_valid(existing) and existing.get_instance_id()==identity and existing.active,"enemies continue fighting through gaps")
	var previous_count:int=game.enemy_count();game.director.tick(.1,previous_count)
	check(game.enemy_count()==previous_count,"short gap does not spawn reinforcements")
	game.director.remaining=.01;game._physics_process(.02)
	check(game.wave==2 and game.phase=="assault","next wave starts automatically without a Begin button")
	check(game.castle.structures.gate.repair_used==0,"new wave refreshes repair allowance")
	check(archer.hp==archer.max_hp,"survivors recover between waves without being recreated")
	archer.hp=50
	var state:Dictionary=game.snapshot()
	check(SaveManager.valid(state),"continuous checkpoint validates")
	check(not SaveManager.valid({"version":2}),"corrupt checkpoint rejected")
	var bad:Dictionary=state.duplicate(true);bad.director.wave=101
	check(not SaveManager.valid(bad),"out-of-range saved wave rejected")
	bad=state.duplicate(true);bad.army.archer+=1
	check(not SaveManager.valid(bad),"mismatched roster and saved soldiers rejected")
	check(SaveManager.write_state(state),"atomic version 2 save writes")
	var loaded:=SaveManager.read_state()
	check(loaded.director.wave==state.director.wave and loaded.units.size()==state.units.size(),"wave queue and live army survive a save round trip")
	check(SaveManager.write_state(state),"backup checkpoint is created before replacement")
	var corrupt:=FileAccess.open(SaveManager.save_path(),FileAccess.WRITE);corrupt.store_string("broken");corrupt.close()
	check(not SaveManager.read_state().is_empty(),"corrupted primary save falls back to a valid backup")
	SaveManager.write_state(state)
	game.restore(loaded)
	check(game.units[0].hp==50 and game.castle.structures.gate.hp==1470,"restore preserves wounds and castle damage")
	game.checkpoint=loaded.duplicate(true);game.castle.structures.gate.take_damage(5000)
	check(game.castle.structures.gate.hp==0,"gate physically breaches")
	var attacker:UnitController=game.spawn("raider",true,Vector3(-7.8,0,0));game.castle.structures.gate.restore(770)
	check(attacker.choose_target()==game.castle.structures.keep,"repair does not teleport an intruder back outside")
	game.castle.structures.keep.take_damage(5000);check(game.phase=="defeat","keep destruction triggers defeat")
	game.retry_wave()
	check(game.wave==2 and game.castle.structures.gate.hp==1470 and paused,"retry restores saved battle and pauses for planning")
	game.set_paused(false)
	var victim:UnitController=game.units[0];var before:int=game.units.size();victim.take_damage(100000)
	check(game.units.size()==before-1,"defeated soldier immediately leaves active combat lists")
	await create_timer(1.5).timeout
	check(not is_instance_valid(victim),"defeated mesh is freed after its fall animation")
	var clean:=EconomyManager.new(game.balance);var damaged:=EconomyManager.new(game.balance)
	clean.reward(20,0,true);damaged.reward(20,600,false)
	check(clean.gold>damaged.gold-600,"intentional casualties cannot increase net army wealth")
	print("INTEGRATION COMPLETE failures=",failures)
	game.phase="tests_complete"
	game.audio.stop_all()
	await create_timer(.3).timeout;game.queue_free();await process_frame;quit(failures)
