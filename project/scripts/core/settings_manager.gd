class_name SettingsManager
extends RefCounted
## Player preferences are independent of battle checkpoints and Retry Wave.
const DEFAULT_MUSIC:=.35
const DEFAULT_EFFECTS:=1.0
const BATTLE_SPEEDS:=[1.0,1.5,2.0]
var music_volume:=DEFAULT_MUSIC
var effects_volume:=DEFAULT_EFFECTS
var muted:=false
var battle_speed:=1.0
var path:="user://castlehold_settings_v1.cfg"
var persistence_enabled:=true
func level(value: Variant,fallback: float) -> float:
	if not (value is int or value is float) or not is_finite(float(value)):return fallback
	return clampf(float(value),0.0,1.0)
static func speed_value(value: Variant) -> float:
	if (value is int or value is float) and BATTLE_SPEEDS.has(float(value)):return float(value)
	return 1.0
static func speed_label(value: float) -> String:
	return str(value).trim_suffix(".0")+"×"
func load_saved():
	music_volume=DEFAULT_MUSIC;effects_volume=DEFAULT_EFFECTS;muted=false;battle_speed=1.0
	if not persistence_enabled:return
	var file:=ConfigFile.new()
	if file.load(path)!=OK or file.get_value("meta","version",0)!=1:return
	music_volume=level(file.get_value("audio","music",DEFAULT_MUSIC),DEFAULT_MUSIC)
	effects_volume=level(file.get_value("audio","effects",DEFAULT_EFFECTS),DEFAULT_EFFECTS)
	var mute_value:Variant=file.get_value("audio","muted",false)
	muted=mute_value if mute_value is bool else false
	battle_speed=speed_value(file.get_value("battle","speed",1.0))
func save() -> bool:
	if not persistence_enabled:return true
	var file:=ConfigFile.new();file.set_value("meta","version",1)
	file.set_value("audio","music",music_volume);file.set_value("audio","effects",effects_volume);file.set_value("audio","muted",muted)
	file.set_value("battle","speed",speed_value(battle_speed))
	if file.save(path+".tmp")!=OK:return false
	return DirAccess.rename_absolute(path+".tmp",path)==OK
