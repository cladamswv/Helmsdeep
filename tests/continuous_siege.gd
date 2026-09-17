extends SceneTree
var failures:=0
func check(ok: bool,label: String):
	if ok:print("PASS: "+label)
	else:push_error("FAIL: "+label);failures+=1
func _initialize():call_deferred("run")
func run():
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://resources/waves/siege.json"))
	var director:=WaveDirector.new(data);director.reset()
	var started:Array=[];var ended:Array=[];var spawned:Array=[];var time:={"t":0.0}
	director.started.connect(func(n):started.append([n,time.t]))
	director.ended.connect(func(n):ended.append([n,time.t]))
	director.reinforcement.connect(func(id,index,w):spawned.append([id,index,w]))
	for frame in 125000:
		time.t+=.02;director.tick(.02,0)
		if director.phase=="final" and director.pending.is_empty():break
	check(started.size()==100 and ended.size()==100,"all 100 assaults start and finish exactly once")
	var durations_ok:=true;var gaps_ok:=true
	for i in 100:
		var duration:float=ended[i][1]-started[i][1]
		durations_ok=durations_ok and duration>=9.97 and duration<=15.03
		if i<99:
			var gap:float=started[i+1][1]-ended[i][1]
			gaps_ok=gaps_ok and gap>=2.97 and gap<=5.03
	check(durations_ok,"every assault lasts 10–15 simulated seconds")
	check(gaps_ok,"every reinforcement gap lasts 3–5 simulated seconds")
	var expected:=0
	for n in range(1,101):expected+=WaveDirector.composition(n,data).size()
	check(spawned.size()==expected,"no scheduled attackers are lost across wave boundaries")
	director.tick(120,0);check(director.wave==100,"no wave 101 is generated")
	var limited:=WaveDirector.new(data);limited.reset();limited.start_wave()
	var before:=limited.pending.size();limited.tick(.25,int(data.enemy_limit))
	check(limited.pending.size()==before,"enemy limit defers reinforcements instead of discarding them")
	limited.tick(.25,int(data.enemy_limit)-1);check(limited.pending.size()==before-1,"a deferred formation uses only the free enemy slots")
	var game=load("res://scenes/battle/battle.tscn").instantiate();root.add_child(game)
	await process_frame;game.director.start_wave()
	var enemy:UnitController=game.spawn("raider",true,Vector3(14,0,0));var start:=enemy.position
	game.projectiles.launch(Vector3(0,4,0),enemy,1)
	game.hud.toggle_pause();var seconds:float=game.director.remaining;var projectile:float=game.projectiles.slots[0].t
	var animation:float=enemy.animator.current_animation_position
	await create_timer(.15,true).timeout
	check(paused and game.director.remaining==seconds and enemy.position==start,"pause freezes the wave clock and troop movement")
	check(game.projectiles.slots[0].t==projectile and enemy.animator.current_animation_position==animation,"pause freezes projectiles and skeletal animations")
	var gold:int=game.economy.gold;game.hud.recruit_buttons.archer.pressed.emit()
	check(game.economy.gold==gold-60 and paused,"recruitment remains usable while paused")
	game.hud.show_credits();game.hud.close_credits()
	check(paused,"closing Credits preserves an existing pause")
	game.hud.toggle_pause();await create_timer(.1).timeout
	check(not paused and game.director.remaining<seconds and enemy.position!=start,"Resume continues the same attack without resetting it")
	# Final victory needs both an empty reinforcement queue and no live enemies.
	game.director.wave=100;game.phase="final";game.director.pending.clear();game._physics_process(.02)
	check(game.phase=="final","100th assault does not award victory while enemies survive")
	for unit in game.units.duplicate():
		if unit.enemy:unit.take_damage(100000)
	game._physics_process(.02);check(game.phase=="complete","clearing the final attackers awards 100-wave victory")
	check(SaveManager.valid(game.snapshot()),"completed siege is a valid resumable save")
	print("CONTINUOUS SIEGE COMPLETE failures=",failures)
	game.audio.stop_all()
	await create_timer(.3).timeout;game.queue_free();await process_frame;quit(failures)
