class_name WaveDirector
extends RefCounted
## Timed reinforcements. Living enemies are never cleared at wave boundaries.
signal started(number: int)
signal ended(number: int)
signal reinforcement(id: String, index: int, source_wave: int)
var balance: Dictionary
var wave := 0
var phase := "gap"
var remaining := 4.0
var spawn_clock := 0.0
var spawn_interval := 1.0
var spawn_batch := 1
var spawn_index := 0
var pending: Array = []
func _init(data: Dictionary={}):
	balance=data
func reset():
	wave=0;phase="gap";remaining=float(balance.initial_gap);spawn_clock=0;spawn_index=0;spawn_batch=1;pending.clear()
static func formation(index: int) -> Vector3:
	return Vector3(32.0+floor(index/5.0)*1.1,0,(index%5-2)*1.05)
static func duration(number: int, data: Dictionary) -> float:
	return float(data.assault_min)+(number*7%6)*float(data.assault_max-data.assault_min)/5.0
static func gap_duration(number: int, data: Dictionary) -> float:
	return float(data.gap_min)+(number%3)*float(data.gap_max-data.gap_min)/2.0
static func composition(number: int, data: Dictionary) -> Array:
	var result:Array=[]
	var count:=int(data.enemy_base)+int(floor(number*float(data.enemy_growth)))
	if number%5==0:count+=int(data.surge_extra)
	var shields:=0
	if number>=int(data.shield_unlock):shields=mini(int(data.shield_max),1+int(number/int(data.shield_step)))
	var ogres:=0
	if number>=int(data.ogre_unlock) and (number==int(data.ogre_unlock) or number%int(data.ogre_interval)==0 or (number>=int(data.ogre_regular_wave) and number%int(data.ogre_late_interval)==0)):
		ogres=mini(int(data.ogre_max),1+int(number/int(data.ogre_step)))
		if number%5==0 and number>=int(data.ogre_surge_wave):ogres=mini(int(data.ogre_max),ogres+1)
	for i in count:
		var id: String="raider"
		if number>=int(data.archer_unlock) and i%5==3:id="enemy_archer"
		if number>=int(data.spear_unlock) and i%5==1:id="enemy_spearman"
		if number>=int(data.cavalry_unlock) and i%9==7:id="mounted_raider"
		# Early shields screen the support rank; ogres arrive behind the first line.
		if shields>0 and i%4==0:id="orc_guard";shields-=1
		if ogres>0 and i>=5 and i%5==0 and id!="orc_guard":id="ogre";ogres-=1
		result.append({"id":id,"wave":number})
	# Elites replace existing budget slots; the assault size never jumps for art additions.
	var shaman_intro:=int(data.shaman_unlock)
	if number>=shaman_intro and (number-shaman_intro)%int(data.shaman_interval)==0:
		var casters:=mini(int(data.shaman_max),2 if number>=int(data.shaman_pair_wave) else 1)
		for entry in result:
			if entry.id=="enemy_archer" and casters>0:entry.id="ogre_shaman";casters-=1
	var rider_intro:=int(data.warthog_unlock)
	if number>=rider_intro and ((number-rider_intro)%int(data.warthog_interval)==0 or (number>=int(data.warthog_late_wave) and number%int(data.warthog_late_interval)==0)):
		for entry in result:
			if entry.id=="ogre":entry.id="ogre_warthog";break
	# Milestone bosses are authored additions, never replacements for normal foes.
	var bosses:Dictionary=data.get("boss_waves",{})
	if bosses.has(str(number)):result.insert(0,{"id":bosses[str(number)],"wave":number})
	return result
func start_wave():
	wave+=1;phase="assault";remaining=duration(wave,balance)
	var group:=composition(wave,balance);pending.append_array(group)
	spawn_batch=int(balance.formation_size) if wave>=int(balance.formation_wave) else 2
	spawn_interval=remaining/maxf(1,ceilf(float(group.size())/batch_size()));spawn_clock=0
	started.emit(wave)
func batch_size() -> int:
	return spawn_batch
func tick(delta: float, living_enemies: int):
	if phase not in ["gap","assault","final"]:return
	if phase in ["assault","final"]:
		spawn_clock=maxf(-.1,spawn_clock-delta)
		if not pending.is_empty() and spawn_clock<=0 and living_enemies<int(balance.enemy_limit):
			var slots:=mini(batch_size(),int(balance.enemy_limit)-living_enemies)
			for i in mini(slots,pending.size()):
				var entry:Dictionary=pending.pop_front()
				reinforcement.emit(entry.id,spawn_index%5,int(entry.wave));spawn_index+=1
			spawn_clock=spawn_interval
	if phase=="final":return
	remaining-=delta
	if remaining>0:return
	var overshoot:=remaining
	if phase=="gap":
		start_wave();remaining+=overshoot
	else:
		phase="final" if wave>=int(balance.wave_count) else "gap"
		remaining=gap_duration(wave,balance)+overshoot
		ended.emit(wave)
func snapshot() -> Dictionary:
	return {"wave":wave,"phase":phase,"remaining":remaining,"spawn_clock":spawn_clock,"spawn_interval":spawn_interval,"spawn_index":spawn_index,"spawn_batch":spawn_batch,"pending":pending.duplicate(true)}
func restore(state: Dictionary):
	wave=int(state.wave);phase=state.phase;remaining=float(state.remaining);spawn_clock=float(state.spawn_clock)
	spawn_interval=float(state.spawn_interval);spawn_index=int(state.spawn_index);pending=state.pending.duplicate(true)
	# Pre-Horde checkpoints emitted one soldier at a time. Finish that saved
	# interval at its original cadence; new waves use the new formations.
	spawn_batch=int(state.get("spawn_batch",1))
