extends SceneTree

var failures:=0

func _initialize():call_deferred("run")

func check(ok: bool,label: String):
	if ok:print("PASS: "+label)
	else:push_error("FAIL: "+label);failures+=1

func find_button(node: Node,label: String) -> Button:
	if node is Button and node.text==label:return node
	for child in node.get_children():
		var found:=find_button(child,label)
		if found:return found
	return null

func run():
	var path:="user://castlehold_speed_fixture_%d.cfg"%OS.get_process_id()
	var prefs:=SettingsManager.new();prefs.path=path;prefs.battle_speed=2.0
	check(prefs.save(),"battle speed preferences save independently")
	var loaded:=SettingsManager.new();loaded.path=path;loaded.load_saved()
	check(is_equal_approx(loaded.battle_speed,2.0),"saved battle speed survives a new settings instance")
	check(SettingsManager.speed_value("fast")==1.0 and SettingsManager.speed_value(1.25)==1.0,"unsupported speed values fall back to 1x")
	check(SettingsManager.speed_label(1.0)=="1×" and SettingsManager.speed_label(1.5)=="1.5×" and SettingsManager.speed_label(2.0)=="2×","speed labels are compact and readable")
	var game=load("res://scenes/battle/battle.tscn").instantiate();root.add_child(game)
	await process_frame;await process_frame
	game.audio.preferences.path=path;game.audio.preferences.persistence_enabled=true
	check(is_equal_approx(game.battle_speed,1.0) and is_equal_approx(Engine.time_scale,1.0),"new battles start at normal speed")
	var speed_button:=find_button(game,"Speed 1×")
	check(speed_button!=null,"battle HUD exposes the speed control")
	game.set_battle_speed(2.0)
	check(is_equal_approx(game.battle_speed,2.0) and is_equal_approx(Engine.time_scale,2.0),"2x speed scales the live battle clock")
	game.set_paused(true)
	check(game.get_tree().paused and is_equal_approx(Engine.time_scale,1.0),"pause freezes the clock regardless of selected speed")
	game.set_paused(false)
	check(not game.get_tree().paused and is_equal_approx(Engine.time_scale,2.0),"resume restores the selected battle speed")
	game.set_battle_speed(1.5)
	check(is_equal_approx(Engine.time_scale,1.5),"1.5x speed applies without restarting the wave")
	game.set_battle_speed(9.0)
	check(is_equal_approx(game.battle_speed,1.5),"invalid speed changes are ignored")
	game.audio.stop_all();game.set_physics_process(false);game.phase="tests_complete";game.free();await process_frame;quit(failures)
