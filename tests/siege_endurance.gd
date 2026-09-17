extends SceneTree
## Deterministic input policy driving the real combat, economy and wave systems.
## This checks completion and accumulation; it is not a human balance verdict.
func _initialize():call_deferred("run")
func intended_purchase(game: Node3D) -> String:
	if OS.get_cmdline_user_args().has("--archers-only"):
		return "archer" if game.army.archer<30 else ""
	# Establish a wall battery and frontline before growing the mounted wing.
	# Preserve six anti-cavalry troops; replace essential losses before expansion.
	var priorities:Array=[]
	if game.army.swordsman<6:priorities.append("swordsman")
	if game.army.archer<14:priorities.append("archer")
	var frontline_goal:=mini(30,14+maxi(0,game.wave-20)/3)
	if game.army.swordsman<frontline_goal and game.wave>5:priorities.append("swordsman")
	if game.army.knight<2 and game.wave>10:priorities.append("knight")
	if game.army.spearman<6 and game.wave>6:priorities.append("spearman")
	priorities.append_array(["archer","knight","swordsman","spearman"])
	for id in priorities:
		if game.used_capacity(game.definitions[id].category)<int(game.balance.capacity[game.definitions[id].category]):return id
	return ""

func run():
	seed(72020)
	var game=load("res://scenes/battle/battle.tscn").instantiate();root.add_child(game)
	game.set_physics_process(false);game.audio.muted=true;game.audio.stop_all()
	game.projectiles.set_process(false);game.vfx.set_process(false)
	for unit in game.units:unit.set_physics_process(false)
	await process_frame
	var policy_clock:=0.0;var max_active:=0;var max_nodes:=0;var prior_wave:=0
	var repair_gold:=0;var casualties:=0;var gate_min:=2200.0
	game.director.started.connect(func(n):
		if n%25==0:print("BOSS WAVE ",n," army=",game.army," gate=",game.castle.structures.gate.hp," gold=",game.economy.gold))
	for frame in 45000:
		if not game.live_play():break
		policy_clock-=.05
		if policy_clock<=0:
			policy_clock=.5
			var gold_before_repairs:int=game.economy.gold
			if game.castle.structures.keep.hp<4500:game.repair_structure("keep")
			if game.castle.structures.gate.hp<1400:game.repair_gate()
			repair_gold+=gold_before_repairs-game.economy.gold
			var id:=intended_purchase(game)
			if id!="" and game.can_purchase(id):game.purchase(id)
		game._physics_process(.05)
		for unit in game.units.duplicate():unit.set_physics_process(false);unit._physics_process(.05)
		game.projectiles._process(.05);game.vfx._process(.05)
		gate_min=minf(gate_min,game.castle.structures.gate.hp)
		max_active=maxi(max_active,game.units.size());max_nodes=maxi(max_nodes,game.unit_root.get_child_count())
		if frame%200==0:
			# Death animation lifetime is tested separately with real frame time.
			# Dispose expired simulation casualties without waiting wall-clock time.
			for corpse in game.unit_root.get_children():
				if corpse.hp<=0:
					if not corpse.enemy:casualties+=1
					corpse.free()
			await process_frame
		for boss in game.units:
			if boss.data.boss and not boss.has_meta("endurance_tracked"):
				boss.set_meta("endurance_tracked",true)
				boss.died.connect(func(dead):print("BOSS DEFEATED ",dead.data.id," wave=",game.wave," elapsed=",game.elapsed," gate=",game.castle.structures.gate.hp," gold=",game.economy.gold," army=",game.army))
		if game.wave!=prior_wave and game.wave%20==0:
			prior_wave=game.wave;print("SIM wave=",game.wave," gold=",game.economy.gold," army=",game.army," keep=",game.castle.structures.keep.hp)
	for unit in game.units:
		if unit.data.boss:print("BOSS SURVIVING ",unit.data.id," hp=",unit.hp," position=",unit.position)
	var archer_policy:=OS.get_cmdline_user_args().has("--archers-only")
	var success:bool=(game.phase=="defeat" and game.wave<100) if archer_policy else (game.phase=="complete" and game.wave==100)
	print("ENDURANCE result=",game.phase," wave=",game.wave," simulated_seconds=",game.elapsed," max_active=",max_active," max_nodes_between_cleanup=",max_nodes," casualties=",casualties," repair_gold=",repair_gold," minimum_gate_hp=",gate_min)
	if success:print("PASS: unsupported archer stacking cannot coast through the horde" if archer_policy else "PASS: mixed recruitment and repair policy completes 100 continuous waves")
	else:push_error("FAIL: horde difficulty policy check did not meet its expected outcome")
	game.phase="tests_complete"
	game.audio.stop_all()
	await create_timer(.3).timeout;game.queue_free();await process_frame;quit(0 if success else 1)
