class_name SaveManager
extends RefCounted
const FRIENDLY := ["archer","swordsman","spearman","knight"]
const BOSSES := ["boss_gatebreaker","boss_dreadscale","boss_ashcaller","boss_ironjaw"]
const ENEMY := ["raider","enemy_archer","enemy_spearman","mounted_raider","orc_guard","ogre","ogre_warthog","ogre_shaman","boss_gatebreaker","boss_dreadscale","boss_ashcaller","boss_ironjaw"]
const STRUCTURES := {"gate":2200,"keep":5000,"north":1600,"center":1600,"south":1600,"tower":1400}
static func save_path() -> String:
	return "user://castlehold_test_v2.json" if OS.get_cmdline_user_args().has("--test") else "user://castlehold_siege_v2.json"
static func number(value: Variant, low: float, high: float) -> bool:
	return (value is float or value is int) and is_finite(float(value)) and value>=low and value<=high
static func whole(value: Variant, low: int, high: int) -> bool:
	return number(value,low,high) and floor(float(value))==float(value)
static func vector(value: Variant) -> bool:
	if not value is Array or value.size()!=3:return false
	return number(value[0],-50,70) and number(value[1],-1,10) and number(value[2],-20,20)
static func valid(d: Variant) -> bool:
	if not d is Dictionary or d.get("version")!=2 or d.get("mode")!="continuous_siege":return false
	if not whole(d.get("gold"),0,1000000):return false
	for key in ["army","castle","repairs","director"]:
		if not d.get(key) is Dictionary:return false
	for id in FRIENDLY:
		if not whole(d.army.get(id),0,36):return false
	if d.army.archer>30 or d.army.knight>8 or d.army.swordsman+d.army.spearman>36:return false
	for id in STRUCTURES:
		if not number(d.castle.get(id),0,STRUCTURES[id]) or not number(d.repairs.get(id),0,STRUCTURES[id]*.35+.01):return false
	var director:Dictionary=d.director
	if not whole(director.get("wave"),0,100) or director.get("phase") not in ["gap","assault","final","complete"]:return false
	if director.phase in ["final","complete"] and director.wave!=100:return false
	if director.phase=="assault" and director.wave<1:return false
	if director.phase=="gap" and director.wave>=100:return false
	if not number(director.get("remaining"),-.1,15.1) or not number(director.get("spawn_clock"),-.1,15.1):return false
	if not number(director.get("spawn_interval"),.01,15) or not whole(director.get("spawn_index"),0,10000):return false
	if not whole(director.get("spawn_batch",1),1,5):return false
	if not director.get("pending") is Array or director.pending.size()>3000:return false
	for entry in director.pending:
		if not entry is Dictionary or entry.get("id") not in ENEMY or not whole(entry.get("wave"),1,100):return false
	if not d.get("units") is Array or d.units.size()>158:return false
	var army:Dictionary={"archer":0,"swordsman":0,"spearman":0,"knight":0};var slots:Dictionary={};var enemies:=0
	for unit in d.units:
		if not unit is Dictionary or not unit.get("enemy") is bool:return false
		if unit.get("id") not in (ENEMY if unit.enemy else FRIENDLY):return false
		if not number(unit.get("hp"),.001,30000 if unit.id in BOSSES else 10000) or not whole(unit.get("source_wave"),1,100):return false
		if unit.has("boss"):
			if unit.id not in BOSSES or not valid_boss(unit.boss,unit.id):return false
		if not vector(unit.get("position")) or not vector(unit.get("home")):return false
		if not whole(unit.get("slot"),-1,35):return false
		for key in ["cooldown","charge_distance","charge_cooldown"]:
			if not number(unit.get(key),0,100000):return false
		if unit.enemy:enemies+=1
		else:
			var category:String="ranged" if unit.id=="archer" else ("cavalry" if unit.id=="knight" else "infantry")
			var capacity:int={"ranged":30,"infantry":36,"cavalry":8}[category]
			if unit.slot<0 or unit.slot>=capacity:return false
			var key:=category+str(unit.slot)
			if slots.has(key):return false
			slots[key]=true;army[unit.id]+=1
	if enemies>84:return false
	for id in FRIENDLY:
		if army[id]!=d.army[id]:return false
	if not whole(d.get("lost_value"),0,100000) or not whole(d.get("lost_count"),0,10000):return false
	return number(d.get("initial_gate"),0,2200) and number(d.get("elapsed"),0,1000000)
static func valid_boss(state: Variant, id: String) -> bool:
	if not state is Dictionary:return false
	if not number(state.get("cooldown"),0,30) or not number(state.get("windup"),-1,1.5):return false
	if not number(state.get("recovery"),0,1.5) or not whole(state.get("summons"),0,2 if id=="boss_ironjaw" else 0):return false
	return vector(state.get("center"))
static func parse_file(path: String) -> Variant:
	var parser:=JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path))==OK:return parser.data
	return null
static func write_state(state: Dictionary) -> bool:
	if not valid(state):return false
	var file:=FileAccess.open(save_path()+".tmp",FileAccess.WRITE)
	if file==null:return false
	file.store_string(JSON.stringify(state));file.flush();file.close()
	# Never replace a known-good backup with corrupt primary bytes.
	if FileAccess.file_exists(save_path()):
		var previous:Variant=parse_file(save_path())
		if valid(previous):DirAccess.copy_absolute(save_path(),save_path()+".bak")
	return DirAccess.rename_absolute(save_path()+".tmp",save_path())==OK
static func read_state() -> Dictionary:
	for path in [save_path(),save_path()+".bak"]:
		if FileAccess.file_exists(path):
			var data:Variant=parse_file(path)
			if valid(data):return data
	return {}
static func read_legacy() -> Dictionary:
	var path:="user://castlehold_slice_v1.json"
	if not FileAccess.file_exists(path):return {}
	var d:Variant=parse_file(path)
	if not d is Dictionary or d.get("version")!=1 or not d.get("army") is Dictionary or not d.get("castle") is Dictionary:return {}
	if not whole(d.get("gold"),0,100000):return {}
	if not whole(d.army.get("archer"),0,20) or not whole(d.army.get("swordsman"),0,24):return {}
	for id in STRUCTURES:
		if not number(d.castle.get(id),0,STRUCTURES[id]):return {}
	if d.castle.keep<=0:return {}
	return d
