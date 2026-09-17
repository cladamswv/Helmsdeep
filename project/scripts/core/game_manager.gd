extends Node3D
const FRIENDLIES := ["archer","swordsman","spearman","knight"]
const HOSTILES := ["raider","enemy_archer","enemy_spearman","mounted_raider","orc_guard","ogre","ogre_warthog","ogre_shaman","boss_gatebreaker","boss_dreadscale","boss_ashcaller","boss_ironjaw"]
var balance: Dictionary
var definitions: Dictionary
var economy: EconomyManager
var castle: CastleController
var projectiles: ProjectilePool
var vfx: VFXPool
var audio: AudioManager
var hud: CastleHUD
var director: WaveDirector
var targeting := TargetingSystem.new()
var unit_root: Node3D
var units: Array[UnitController] = []
var army: Dictionary
var checkpoint: Dictionary = {}
var lost_value := 0
var lost_count := 0
var initial_gate := 0.0
var camera: BattleCamera
var elapsed := 0.0
var test_mode := false
var crowd_clock := 0.0
var hud_clock := 0.0
var notice_time := 0.0
var last_reward := 0
var battle_speed: float:
	get:return audio.preferences.battle_speed if audio else 1.0
var wave: int:
	get:return maxi(1,director.wave) if director else 1
var phase: String:
	get:return director.phase if director else "gap"
	set(value):director.phase=value
func _ready():
	test_mode=OS.get_cmdline_user_args().has("--smoke") or OS.get_cmdline_user_args().has("--test")
	balance=JSON.parse_string(FileAccess.get_file_as_string("res://resources/waves/siege.json"))
	for id in FRIENDLIES:definitions[id]=load("res://resources/units/"+id+".tres")
	for id in HOSTILES:definitions[id]=load("res://resources/enemies/"+id+".tres")
	economy=EconomyManager.new(balance);army=balance.starting_army.duplicate(true)
	director=WaveDirector.new(balance);director.started.connect(on_wave_started);director.ended.connect(on_wave_ended)
	director.reinforcement.connect(func(id,index,source):spawn(id,true,Vector3(32,0,0) if definitions[id].boss else WaveDirector.formation(index),source))
	castle=CastleController.new();add_child(castle);castle.build(self)
	WorldBuilder.new().build(self)
	unit_root=Node3D.new();unit_root.name="Combatants";add_child(unit_root)
	projectiles=ProjectilePool.new();add_child(projectiles)
	vfx=VFXPool.new();add_child(vfx)
	audio=AudioManager.new();add_child(audio)
	apply_battle_speed()
	camera=BattleCamera.new();add_child(camera)
	hud=CastleHUD.new();add_child(hud);hud.build(self)
	for structure in castle.structures.values():
		structure.changed.connect(func(_s):hud.refresh())
		structure.breached.connect(on_breach)
	var saved:Dictionary={} if test_mode else SaveManager.read_state()
	if not saved.is_empty():
		restore(saved);checkpoint=saved.duplicate(true);set_paused(phase!="complete")
		if phase=="complete":hud.message.text="100 WAVES • VICTORY"
	else:new_siege({} if test_mode else SaveManager.read_legacy())
func live_play() -> bool:
	return phase in ["gap","assault","final"]
func snapshot() -> Dictionary:
	var troops:Array=[]
	for unit in units:
		if unit.hp>0:troops.append(unit.snapshot())
	var repairs:Dictionary={}
	for id in castle.structures:repairs[id]=castle.structures[id].repair_used
	return {"version":2,"mode":"continuous_siege","gold":economy.gold,"army":army.duplicate(true),"castle":castle.snapshot(),"repairs":repairs,"director":director.snapshot(),"units":troops,"lost_value":lost_value,"lost_count":lost_count,"initial_gate":initial_gate,"elapsed":elapsed}
func restore(state: Dictionary):
	clear_army();economy.gold=int(state.gold);army=state.army.duplicate(true);castle.restore(state.castle)
	for id in state.repairs:castle.structures[id].repair_used=float(state.repairs[id])
	director.restore(state.director);lost_value=int(state.lost_value);lost_count=int(state.lost_count)
	initial_gate=float(state.initial_gate);elapsed=float(state.elapsed)
	for entry in state.units:
		var unit:=spawn(entry.id,entry.enemy,Vector3(entry.position[0],entry.position[1],entry.position[2]),int(entry.source_wave))
		unit.restore_combat(entry)
	targeting.rebuild(units,projectiles);notice_time=0;hud.message.text="";hud.detail.text="Drag to scout  •  Recruit and repair at any time"
	apply_battle_speed();hud.refresh()
func save_checkpoint():
	checkpoint=snapshot()
	if not test_mode and not SaveManager.write_state(checkpoint):
		hud.detail.text="Save unavailable. Progress is still available in this session."
func clear_army():
	for child in unit_root.get_children():
		unit_root.remove_child(child);child.queue_free()
	units.clear();projectiles.clear();targeting.cells.clear()
func spawn(id: String, enemy: bool, at: Vector3, source_wave: int=1) -> UnitController:
	var unit:=UnitController.new();unit_root.add_child(unit)
	unit.setup(definitions[id],enemy,self,at,source_wave)
	unit.active=live_play();units.append(unit);unit.died.connect(on_unit_died)
	if unit.data.boss and is_instance_valid(hud):
		hud.message.text=unit.data.title.to_upper();notice_time=3.0;audio.cue("boss_roar")
	return unit
func used_capacity(category: String) -> int:
	var total:=0
	for id in FRIENDLIES:
		if definitions[id].category==category:total+=int(army[id])
	return total
func free_slot(category: String) -> int:
	var occupied:Dictionary={}
	for unit in units:
		if not unit.enemy and unit.data.category==category:occupied[unit.slot_index]=true
	for i in int(balance.capacity[category]):
		if not occupied.has(i):return i
	return -1
func home_for(category: String, slot: int) -> Vector3:
	if category=="ranged":
		var side:float=-1 if slot%2 else 1
		return Vector3(-4.12-floor(slot/10.0)*.60,3.18,side*(2.82+(slot/2%5)*.50))
	if category=="cavalry":return Vector3(-.5-floor(slot/4.0)*1.5,0,(slot%4-1.5)*1.6)
	var side:float=-1 if slot%2 else 1
	return Vector3(-.90-floor(slot/12.0)*.90,0,side*(.40+floor((slot%12)/2.0)*.72))
func recruit(id: String):
	var slot:=free_slot(definitions[id].category)
	if slot<0:return
	var unit:=spawn(id,false,home_for(definitions[id].category,slot));unit.slot_index=slot
func new_siege(legacy: Dictionary={}):
	get_tree().paused=false;clear_army();director.reset();elapsed=0;lost_value=0;lost_count=0;last_reward=0
	audio.set_battle_paused(false)
	apply_battle_speed()
	economy.gold=int(balance.starting_gold);army=balance.starting_army.duplicate(true)
	for structure in castle.structures.values():structure.restore(structure.max_hp)
	if not legacy.is_empty():
		economy.gold=int(legacy.gold);army.archer=int(legacy.army.archer);army.swordsman=int(legacy.army.swordsman);castle.restore(legacy.castle)
	for id in FRIENDLIES:
		for i in int(army[id]):recruit(id)
	initial_gate=castle.structures.gate.hp;camera.recenter();targeting.rebuild(units,projectiles)
	hud.message.text="HOLD THE VALLEY";notice_time=3
	hud.detail.text="The siege starts in 4 seconds. Pause to plan, train or repair."
	save_checkpoint();hud.refresh()
func can_purchase(id: String) -> bool:
	return live_play() and id in FRIENDLIES and economy.gold>=definitions[id].cost and used_capacity(definitions[id].category)<int(balance.capacity[definitions[id].category])
func purchase(id: String):
	if not can_purchase(id):return
	if economy.spend(definitions[id].cost):
		recruit(id);army[id]=int(army[id])+1;audio.cue("coin");hud.refresh()
func repair_structure(id: String):
	if not live_play():return
	var cost:=castle.repair_structure(id)
	if cost>0:audio.cue("coin")
	hud.detail.text="%s repaired • %d gold. Repair allowance refreshes each wave."%[id.capitalize(),cost]
	hud.refresh()
func repair_gate():repair_structure("gate")
func on_wave_started(number: int):
	# Keep the original survivor recovery rule without resetting positions or combat.
	for unit in units:
		if not unit.enemy:unit.hp=minf(unit.max_hp,unit.hp+unit.max_hp*float(balance.survivor_heal_fraction))
	for structure in castle.structures.values():structure.repair_used=0
	hud.message.text=("HORDE ASSAULT • %d" if number%5==0 else "WAVE %d")%number;notice_time=1.5
	var ogres:=0;var shields:=0;var riders:=0;var shamans:=0
	for entry in WaveDirector.composition(number,balance):
		if entry.id=="ogre":ogres+=1
		elif entry.id=="orc_guard":shields+=1
		elif entry.id=="ogre_warthog":riders+=1
		elif entry.id=="ogre_shaman":shamans+=1
	hud.detail.text=("Siege ogre approaching • Keep it away from the gate" if ogres==1 else "%d ogres approaching • Hold them away from the gate"%ogres) if ogres>0 else ("Ironshield orcs resist arrows • Meet them with blades" if shields>0 else "Drag to scout  •  Pause to plan")
	if riders>0:hud.detail.text="GIANT WARTHOG • Brace your spearmen for the charge"
	elif shamans>0:hud.detail.text="FIRE SHAMANS • Send knights after the casters"
	if balance.boss_waves.has(str(number)):
		var boss:UnitData=definitions[balance.boss_waves[str(number)]]
		hud.message.text="BOSS • "+boss.title.to_upper();notice_time=3.0
		hud.detail.text="%s approaches • Reinforce your army and watch its attacks"%boss.title
	if number%5==0 or number==1:audio.cue("horn")
	save_checkpoint();hud.refresh()
func on_wave_ended(number: int):
	var result:=economy.reward(number,lost_value,lost_count==0 and castle.structures.gate.hp>=initial_gate)
	last_reward=int(result.total);lost_count=0;lost_value=0;initial_gate=castle.structures.gate.hp
	hud.detail.text="+%d gold • Reinforcements keep coming. Protect the keep."%last_reward
	hud.refresh()
func _physics_process(delta: float):
	if not live_play() or get_tree().paused:return
	elapsed+=delta;crowd_clock-=delta;hud_clock-=delta
	if crowd_clock<=0:targeting.rebuild(units,projectiles);crowd_clock=.10
	director.tick(delta,enemy_count())
	if notice_time>0:
		notice_time-=delta
		if notice_time<=0:hud.message.text=""
	if phase=="final" and director.pending.is_empty() and enemy_count()==0:complete_siege()
	if hud_clock<=0:hud.refresh();hud_clock=.15
func enemy_count() -> int:
	var count:=0
	for unit in units:
		if unit.enemy and unit.hp>0:count+=1
	return count
func on_unit_died(unit: UnitController):
	units.erase(unit)
	if not unit.enemy:
		army[unit.data.id]=maxi(0,int(army[unit.data.id])-1);lost_value+=unit.data.cost;lost_count+=1
	elif unit.data.boss:
		economy.gold+=unit.data.boss.bounty
		hud.message.text="%s DEFEATED"%unit.data.title.to_upper();notice_time=3.0
		hud.detail.text="+%d boss bounty • Rally the survivors"%unit.data.boss.bounty
		vfx.burst(unit.global_position+Vector3.UP*2,true);audio.cue("boss_slam")
	hud.refresh()
func on_breach(structure: CastleStructure):
	if not live_play():return
	if structure.id=="keep":
		phase="defeat";projectiles.clear()
		apply_battle_speed()
		for unit in units:unit.active=false
		hud.message.text="THE KEEP HAS FALLEN";hud.detail.text="Retry the saved wave. Recruit and repair while paused before resuming."
		audio.cue("defeat");hud.refresh()
	elif structure.id=="gate":
		camera.recenter();hud.message.text="GATE BREACHED!";notice_time=2.5
		hud.detail.text="Enemies can reach the keep. Repair the gate or reinforce the defense."
func complete_siege():
	phase="complete";projectiles.clear()
	apply_battle_speed()
	for unit in units:unit.active=false;unit.play("cheer")
	hud.message.text="100 WAVES • VICTORY";hud.detail.text="The valley stands. Your surviving army held the castle."
	audio.cue("victory");hud.refresh();save_checkpoint()
func retry_wave():
	if phase=="complete":new_siege();return
	if checkpoint.is_empty():new_siege();return
	restore(checkpoint);camera.recenter();set_paused(true)
func set_paused(value: bool):
	get_tree().paused=value;camera.cancel_gesture()
	apply_battle_speed()
	audio.set_battle_paused(value)
	hud.refresh()
func set_battle_speed(value: float):
	if not SettingsManager.BATTLE_SPEEDS.has(value):return
	audio.preferences.battle_speed=value;apply_battle_speed()
	audio.save_timer.start();hud.refresh()
func apply_battle_speed():
	# One clock keeps movement, attack contact, animations and waves in step.
	# Pause still belongs to SceneTree; UI and result screens run at normal speed.
	Engine.time_scale=battle_speed if live_play() and not get_tree().paused else 1.0
func _exit_tree():
	Engine.time_scale=1.0
func _notification(what: int):
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED] and hud and not test_mode:
		set_paused(true);audio.set_backgrounded(true)
	elif what in [NOTIFICATION_APPLICATION_FOCUS_IN,NOTIFICATION_APPLICATION_RESUMED] and audio and not test_mode:
		audio.set_backgrounded(false)
