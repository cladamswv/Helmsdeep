extends SceneTree
## Real scene, animated muzzle, pooled impacts, counters and checkpoint coverage.
var failures:=0
func _initialize():call_deferred("run")
func check(ok: bool,label: String):
	if ok:print("PASS: "+label)
	else:push_error("FAIL: "+label);failures+=1
func spawn(game: Node3D,id: String,hostile: bool,at: Vector3) -> UnitController:
	var unit:UnitController=game.spawn(id,hostile,at);unit.set_physics_process(false);return unit
func count_id(entries: Array,id: String) -> int:
	var count:=0
	for entry in entries:
		if entry.id==id:count+=1
	return count
func active(slots: Array[Dictionary]) -> int:
	var count:=0
	for slot in slots:
		if slot.active:count+=1
	return count
func run():
	seed(31825)
	var game=load("res://scenes/battle/battle.tscn").instantiate();root.add_child(game)
	game.set_physics_process(false);game.audio.muted=true;game.clear_army()
	game.projectiles.set_process(false)
	var pool:FireballPool=game.projectiles.fireballs
	var shaman:=spawn(game,"ogre_shaman",true,Vector3(16,0,0))
	var rider:=spawn(game,"ogre_warthog",true,Vector3(24,0,4))
	var target:=spawn(game,"swordsman",false,Vector3(8,0,0))
	await process_frame;await process_frame
	check(shaman.find_skeleton(shaman.visual).get_bone_count()==24 and rider.find_skeleton(rider.visual).get_bone_count()==36,"the shaman and mounted ogre load their complete articulated rigs")
	check(is_equal_approx(shaman.attack_duration,1.6) and is_equal_approx(shaman.data.hit_time,.8) and is_equal_approx(rider.attack_duration*.5,rider.data.hit_time),"cast and axe contact align with their authored animation timing")
	check(shaman.shaman_focus!=null and shaman.shaman_focus.get_bone_idx()==shaman.find_skeleton(shaman.visual).find_bone("hand_R"),"the projectile muzzle attaches to the actual animated staff hand")
	shaman.play("shoot");shaman.animator.advance(.01)
	await process_frame
	var first_tip:=shaman.shaman_focus.origin()
	shaman.animator.advance(.7);await process_frame
	check(first_tip.distance_to(shaman.shaman_focus.origin())>.1 and shaman.shaman_focus.origin().y>2,"the ember follows the casting gesture above the battlefield")
	shaman.target=target;shaman.active=true;shaman.windup=.8;shaman.cooldown=3.2
	shaman._physics_process(.79)
	check(active(pool.slots)==0 and target.hp==target.max_hp,"the shaman visibly winds up before launching or dealing damage")
	shaman._physics_process(.02)
	check(active(pool.slots)==1 and active(game.projectiles.slots)==0 and target.hp==target.max_hp,"cast contact launches a fireball instead of an arrow or instant damage")
	var shot:Dictionary=pool.slots[0]
	check(shot.node.global_position.is_equal_approx(shaman.shaman_focus.origin()),"fireballs start at the animated staff ember")
	pool.tick(.08)
	check(shot.node.global_position.distance_to(shot.start)>.1 and target.hp==target.max_hp,"a fireball visibly travels before its impact")
	game.projectiles.set_process(true);game.set_paused(true)
	var frozen_t:float=shot.t;var frozen_clock:float=shaman.shaman_focus.clock
	var frozen_animation:float=shaman.animator.current_animation_position
	await create_timer(.10,true).timeout
	check(shot.t==frozen_t and shaman.shaman_focus.clock==frozen_clock and shaman.animator.current_animation_position==frozen_animation,"Pause freezes fireball flight, staff flame phase and the casting animation")
	game.set_paused(false);await create_timer(.04).timeout;game.projectiles.set_process(false)
	check(shot.t>frozen_t and shaman.shaman_focus.clock>frozen_clock,"Resume continues the same projectile and staff effect")
	pool.tick(2)
	check(is_equal_approx(target.max_hp-target.hp,52*float(game.balance.attacker_damage_multiplier)*(1-target.data.armor)),"stronger direct fireball damage lands once on arrival with armor applied")
	var hp_after:float=target.hp;pool.tick(2)
	check(target.hp==hp_after and active(pool.slots)==0,"a returned projectile cannot damage its target again")
	var guard:=spawn(game,"orc_guard",true,Vector3(7,0,-4))
	pool.launch(Vector3(16,3,-4),guard,100,false,shaman.data);pool.tick(2)
	check(is_equal_approx(guard.max_hp-guard.hp,100*(1-guard.data.armor)),"fire magic bypasses arrow-only shield resistance, while retaining armor")
	guard.hp=70;game.targeting.incoming.clear();game.targeting.reserve(guard,100)
	var arrow_saturated:bool=game.targeting.saturated(guard)
	game.targeting.incoming.clear();game.targeting.reserve(guard,100,false)
	check(not arrow_saturated and game.targeting.saturated(guard),"target reservations distinguish blocked arrows from incoming magic")
	var friends:Array[UnitController]=[]
	for i in 4:friends.append(spawn(game,"swordsman",false,Vector3(8+i*.30,0,0)))
	var high_archer:=spawn(game,"archer",false,Vector3(8,4,0))
	var ally:=spawn(game,"raider",true,Vector3(8,0,.1))
	target.hp=target.max_hp
	pool.launch(Vector3(16,3,0),target,52,true,shaman.data);pool.tick(2)
	var hurt:=0
	for unit in friends:
		if unit.hp<unit.max_hp:hurt+=1
	check(hurt==2 and is_equal_approx(friends[0].max_hp-friends[0].hp,52*.35*(1-friends[0].data.armor)),"the blast hurts at most two nearby secondary defenders at reduced damage")
	check(high_archer.hp==high_archer.max_hp and ally.hp==ally.max_hp,"ground splash cannot pass through battlements or hit the caster's allies")
	var node_count:=pool.get_child_count();var launched:=0
	for i in 20:
		if pool.launch(Vector3(16,3,0),target,1,true,shaman.data):launched+=1
	check(launched==16 and active(pool.slots)==16 and pool.get_child_count()==node_count,"crowded fireball launches stay inside the fixed 16-projectile pool")
	pool.clear();hp_after=target.hp;pool.tick(10)
	check(active(pool.slots)==0 and target.hp==hp_after,"clearing the battlefield cancels every pending pooled impact")
	pool.launch(Vector3(16,3,0),target,10,true,shaman.data)
	shaman.take_damage(10000);hp_after=target.hp;pool.tick(2)
	check(target.hp<hp_after,"an already launched fireball continues after its caster falls")
	var doomed:=spawn(game,"swordsman",false,Vector3(25,0,-4))
	pool.launch(Vector3(16,3,-4),doomed,52,true,game.definitions.ogre_shaman)
	doomed.take_damage(10000);doomed.free();pool.tick(2)
	check(active(pool.slots)==0,"a removed target safely releases its projectile slot")
	game.clear_army();await process_frame
	rider=spawn(game,"ogre_warthog",true,Vector3(20,0,0))
	var spear:=spawn(game,"spearman",false,Vector3(8,0,0))
	check(is_equal_approx(spear.damage_against(rider),spear.data.damage*2),"spearmen retain their full anti-cavalry counter against the giant warthog")
	rider.charge_distance=0;rider.charge_cooldown=0
	var start:=rider.position;rider.move_toward_point(Vector3(8,0,0),.1);var slow_step:=start.distance_to(rider.position)
	rider.position=start;rider.charge_distance=3.5;rider.move_toward_point(Vector3(8,0,0),.1)
	check(start.distance_to(rider.position)>slow_step*1.3,"the warthog accelerates once it has room to build its charge")
	target=spawn(game,"swordsman",false,Vector3(18,0,0));rider.position=Vector3(20,0,0)
	rider.target=target;rider.active=true;rider.charge_distance=4;rider.windup=.85;rider.cooldown=2.1
	start=target.position;rider._physics_process(.84)
	check(target.hp==target.max_hp,"the rider's axe and charge share a readable contact windup")
	rider._physics_process(.02)
	check(is_equal_approx(target.max_hp-target.hp,(60+130)*float(game.balance.attacker_damage_multiplier)*(1-target.data.armor)) and target.position.distance_to(start)>.6,"stronger charge contact applies once and knocks the defender back")
	target.hp=target.max_hp;rider.position=target.position+Vector3(2,0,0);rider.charge_distance=4;rider.windup=.001
	rider._physics_process(.002)
	check(is_equal_approx(target.max_hp-target.hp,60*float(game.balance.attacker_damage_multiplier)*(1-target.data.armor)) and rider.charge_cooldown>11,"the charge cannot repeat before its recovery ends")
	var intro_ok:=true;var counts_ok:=true
	for n in range(1,101):
		var group:=WaveDirector.composition(n,game.balance)
		if n<18:intro_ok=intro_ok and count_id(group,"ogre_shaman")==0
		if n<25:intro_ok=intro_ok and count_id(group,"ogre_warthog")==0
		counts_ok=counts_ok and group.size()-(1 if game.balance.boss_waves.has(str(n)) else 0)==int(game.balance.enemy_base)+floori(n*float(game.balance.enemy_growth))+(int(game.balance.surge_extra) if n%5==0 else 0)
	check(intro_ok and count_id(WaveDirector.composition(18,game.balance),"ogre_shaman")==1 and count_id(WaveDirector.composition(25,game.balance),"ogre_warthog")==1,"shamans enter at wave 18 and giant warthogs at wave 25")
	var late:=WaveDirector.composition(60,game.balance)
	check(count_id(late,"ogre_shaman")==2 and count_id(late,"ogre_warthog")==1 and count_id(late,"ogre")==1,"late assaults combine two shamans, a rider and a foot ogre")
	check(counts_ok,"elite introductions replace existing slots apart from explicitly scheduled milestone bosses")
	game.new_siege();game.set_physics_process(false)
	for unit in game.units:unit.set_physics_process(false)
	rider=spawn(game,"ogre_warthog",true,Vector3(20,0,1));rider.hp=500;rider.charge_distance=2.2;rider.charge_cooldown=7
	shaman=spawn(game,"ogre_shaman",true,Vector3(22,0,-1));shaman.hp=200
	var state:Dictionary=game.snapshot()
	check(SaveManager.valid(state) and int(state.version)==2,"both elites fit the existing versioned checkpoint format")
	pool.launch(Vector3(16,3,0),game.units[0],52,true,shaman.data);game.restore(state)
	var restored_ok:=0
	for unit in game.units:
		unit.set_physics_process(false)
		if unit.data.id=="ogre_warthog" and unit.hp==500 and is_equal_approx(unit.charge_distance,2.2) and unit.charge_cooldown==7:restored_ok+=1
		if unit.data.id=="ogre_shaman" and unit.hp==200 and unit.shaman_focus!=null:restored_ok+=1
	check(restored_ok==2 and active(pool.slots)==0,"retry restores elite health, charge state and staff attachment without stale fireballs")
	check(game.audio.sounds.fire_cast.get_length()>.5 and game.audio.sounds.fire_impact.get_length()>.5,"original cast and fire impact sounds load into the adjustable effects system")
	game.phase="tests_complete";game.audio.stop_all();await create_timer(.3,true).timeout
	game.queue_free();await process_frame
	print("OGRE ELITES COMPLETE failures=",failures);quit(failures)
