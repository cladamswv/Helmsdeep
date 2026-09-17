extends SceneTree
## Real boss assets, staged hits, bounded splash, persistence and final-wave rules.
var failures:=0
func _initialize():call_deferred("run")
func check(ok: bool,label: String):
	if ok:print("PASS: "+label)
	else:push_error("FAIL: "+label);failures+=1
func spawn(game: Node3D,id: String,hostile: bool,at: Vector3,wave: int=1) -> UnitController:
	var unit:UnitController=game.spawn(id,hostile,at,wave);unit.set_physics_process(false);return unit
func mesh_in(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:return node
	for child in node.get_children():
		var found:=mesh_in(child)
		if found:return found
	return null
func run():
	seed(2510075)
	var game=load("res://scenes/battle/battle.tscn").instantiate();root.add_child(game)
	game.set_physics_process(false);game.projectiles.set_process(false);game.audio.muted=true
	game.clear_army();await process_frame
	var boss_boost:float=game.balance.attacker_damage_multiplier*game.balance.boss_damage_multiplier
	var count:=0;var schedule_ok:=true
	for wave in range(1,101):
		var in_wave:=0
		for entry in WaveDirector.composition(wave,game.balance):
			if entry.id in SaveManager.BOSSES:
				count+=1;in_wave+=1;schedule_ok=schedule_ok and wave%25==0 and entry.id==game.balance.boss_waves[str(wave)]
		schedule_ok=schedule_ok and in_wave==(1 if wave%25==0 else 0)
	check(count==4 and schedule_ok,"exactly one distinct boss arrives at 25, 50, 75 and 100")
	var ordinary:Dictionary=game.balance.duplicate(true);ordinary.erase("boss_waves")
	check(WaveDirector.composition(25,game.balance).size()==WaveDirector.composition(25,ordinary).size()+1,"bosses supplement rather than replace their supporting army")
	for id in SaveManager.BOSSES:
		var unit:=spawn(game,id,true,Vector3(20,0,0),100)
		var mesh:=mesh_in(unit.visual);var skeleton:=unit.find_skeleton(unit.visual)
		check(mesh.mesh.get_surface_count()==1 and mesh.mesh.get_aabb().size.y>5.0 and skeleton.get_bone_count() in [24,40],id+" has giant skinned geometry on one material surface")
		check(unit.animator.has_animation("special") and unit.animator.has_animation("defeat") and is_equal_approx(unit.attack_duration*.5,unit.data.hit_time),id+" contact is synchronized to the authored attack clip")
		check(unit.max_hp==unit.data.hp and is_equal_approx(unit.damage_scale,boss_boost),id+" receives the attack boost without ordinary wave inflation")
		if id=="boss_gatebreaker":
			unit.animator.play("attack_a",0);unit.animator.seek(unit.data.hit_time,true);unit.animator.advance(0);await process_frame
			var maul_head:Vector3=skeleton.get_bone_global_pose(skeleton.find_bone("hand_R"))*Vector3(0,3.51,0)
			print("MAUL CONTACT ",maul_head)
			check(maul_head.y>0 and maul_head.y<1.5 and maul_head.z< -2.0,"the actual maul head reaches ground-contact height on its damage frame")
	game.clear_army();await process_frame
	var boss:=spawn(game,"boss_gatebreaker",true,Vector3(18,0,0),25)
	var targets:Array[UnitController]=[]
	for i in 7:targets.append(spawn(game,"swordsman",false,Vector3(15+(i%3)*.15,0,(i/3)*.2)))
	var archer:=spawn(game,"archer",false,Vector3(15,3.5,0))
	var ally:=spawn(game,"raider",true,Vector3(15,0,0))
	boss.boss_combat.cooldown=0;boss._physics_process(.01)
	check(boss.boss_combat.windup>1.1 and boss.boss_combat.ring.visible and targets[0].hp==targets[0].max_hp,"maul slam displays a warning before any damage")
	game.hud.refresh()
	check(game.hud.boss_panel.visible and game.hud.boss_title.text.contains("MAUL SLAM"),"the boss health display also names its anticipated attack")
	game.set_paused(true)
	var before:=boss.boss_combat.windup;var animation:=boss.animator.current_animation_position
	boss._physics_process(2.0);await create_timer(.10,true).timeout
	check(boss.boss_combat.windup==before and boss.animator.current_animation_position==animation and targets[0].hp==targets[0].max_hp,"pause freezes boss warning, animation and damage")
	game.set_paused(false);boss._physics_process(1.21)
	var hurt:=0
	for target in targets:
		if target.hp<target.max_hp:hurt+=1
	check(hurt==5 and archer.hp==archer.max_hp and ally.hp==ally.max_hp,"the shockwave caps casualties at five targets and respects height and faction")
	var remaining:=targets[0].hp;boss._physics_process(.2)
	check(targets[0].hp==remaining and not boss.boss_combat.ring.visible,"a slam applies once, then the boss visibly recovers")
	var gate:CastleStructure=game.castle.structures.gate;game.clear_army();await process_frame
	boss=spawn(game,"boss_gatebreaker",true,gate.position+Vector3(2.0,0,0),25)
	boss.target=gate;boss.windup=boss.data.hit_time;boss.cooldown=2.6
	before=gate.hp;boss._physics_process(1.19)
	check(gate.hp==before,"the oversized maul cannot damage the gate before contact")
	boss._physics_process(.02)
	check(is_equal_approx(before-gate.hp,384.0*boss_boost),"a completed Gatebreaker strike applies the stronger attack to persistent gate damage")
	game.clear_army();await process_frame
	var rider:=spawn(game,"boss_dreadscale",true,Vector3(20,0,0),50)
	var spear:=spawn(game,"spearman",false,Vector3(15,0,0))
	check(spear.damage_against(rider)==spear.data.damage*2,"spearmen counter the giant lizard cavalry")
	check(rider.flat_distance(spear)<rider.position.distance_to(spear.position)-2,"melee contact accounts for the giant mount's physical size")
	game.projectiles.launch(spear.position+Vector3.UP,rider,1)
	check(is_equal_approx(game.projectiles.slots[0].end.y,rider.data.impact_height),"arrows aim at the giant body rather than its feet")
	game.clear_army();await process_frame
	boss=spawn(game,"boss_ashcaller",true,Vector3(16,0,0),75)
	var start:=boss.position;boss.boss_combat.cooldown=0;boss._physics_process(.1)
	check(boss.position.x<start.x and boss.boss_combat.windup<0,"Ashcaller advances into the visible firing line before casting")
	boss.position=Vector3(8,0,0)
	var target:=spawn(game,"swordsman",false,Vector3(4,0,0))
	await process_frame
	check(is_equal_approx(boss.shaman_focus.tip.position.y,3.438),"Ashcaller's ember attaches to the tip of his giant staff")
	boss.boss_combat.cooldown=0;boss._physics_process(.01)
	var locked_center:=boss.boss_combat.center
	boss._physics_process(1.51)
	check(target.hp==target.max_hp and game.projectiles.fireballs.slots[0].active,"firestorm launches a traveling projectile before applying damage")
	var slot:Dictionary=game.projectiles.fireballs.slots[0]
	check(slot.area and slot.center==locked_center,"firestorm keeps its warned location instead of chasing troops at impact")
	game.projectiles.fireballs.tick(5)
	check(is_equal_approx(target.max_hp-target.hp,170*boss_boost*(1-target.data.armor)),"the stronger firestorm lands on arrival in its marked area")
	game.new_siege();game.set_physics_process(false);game.director.pending.clear()
	for unit in game.units:unit.set_physics_process(false)
	boss=spawn(game,"boss_ironjaw",true,Vector3(20,0,0),100);boss.hp=boss.max_hp*.69
	boss._physics_process(.01);boss._physics_process(1.21)
	check(boss.boss_combat.summons==1 and game.director.pending.size()==4,"Ironjaw's first health threshold queues four reinforcements at the enemy road")
	var state:Dictionary=game.snapshot()
	check(SaveManager.valid(state),"giant health and used summon thresholds persist in a valid version-two save")
	game.restore(state)
	for unit in game.units:
		unit.set_physics_process(false)
		if unit.data.id=="boss_ironjaw":boss=unit
	boss._physics_process(1.3);boss._physics_process(.01)
	check(boss.boss_combat.summons==1 and game.director.pending.size()==4,"restoring a checkpoint cannot repeat a consumed reinforcement roar")
	boss.hp=boss.max_hp*.34;boss._physics_process(.01);boss._physics_process(1.21)
	check(boss.boss_combat.summons==2 and game.director.pending.size()==8,"Ironjaw has a second, bounded reinforcement threshold")
	var emitted:Array=[];game.director.reinforcement.connect(func(id,index,w):emitted.append(id))
	game.director.wave=100;game.phase="final";game.director.spawn_clock=0
	game.director.tick(.1,84)
	check(emitted.is_empty() and game.director.pending.size()==8,"boss reinforcements obey the same 84-enemy performance cap")
	game.director.pending.clear();game._physics_process(.01)
	check(game.phase=="final","wave 100 cannot end while Ironjaw is still alive")
	var gold:int=game.economy.gold;boss.take_damage(100000);boss.take_damage(100000)
	check(game.economy.gold==gold+2500,"a defeated boss awards its bounty exactly once")
	game._physics_process(.01)
	check(game.phase=="complete","defeating the final boss and its army completes the siege")
	game.new_siege();game.set_physics_process(false)
	for unit in game.units:unit.set_physics_process(false)
	boss=spawn(game,"boss_gatebreaker",true,Vector3(1,0,0),25)
	boss.boss_combat.cooldown=0;boss._physics_process(.01)
	state=game.snapshot();check(SaveManager.valid(state),"a boss checkpoint remains valid during its windup")
	game.restore(state)
	for unit in game.units:
		unit.set_physics_process(false)
		if unit.data.id=="boss_gatebreaker":boss=unit
	check(boss.boss_combat.windup>0 and boss.boss_combat.ring.visible and boss.anim=="special","retry restores the same warning and special-attack pose")
	var corrupt:=state.duplicate(true)
	for entry in corrupt.units:
		if entry.id=="boss_gatebreaker":entry.boss.summons=99
	check(not SaveManager.valid(corrupt),"corrupted boss state is rejected instead of creating unbounded reinforcements")
	check(game.audio.sounds.boss_roar.get_length()>1 and game.audio.sounds.boss_slam.get_length()>.8,"original giant sounds use the adjustable effects channel")
	game.phase="tests_complete";game.audio.stop_all();await create_timer(.3,true).timeout
	game.queue_free();await process_frame
	print("BOSSES COMPLETE failures=",failures);quit(failures)
