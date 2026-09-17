extends SceneTree
var failures:=0
func _initialize():call_deferred("run")
func check(ok: bool,label: String):
	if ok:print("PASS: "+label)
	else:push_error("FAIL: "+label);failures+=1
func find_mute(node: Node) -> CheckButton:
	if node is CheckButton:return node
	for child in node.get_children():
		var found:=find_mute(child)
		if found:return found
	return null
func find_button(node: Node,label: String) -> Button:
	if node is Button and node.text==label:return node
	for child in node.get_children():
		var found:=find_button(child,label)
		if found:return found
	return null
func run():
	var path:="user://castlehold_audio_fixture_%d.cfg"%OS.get_process_id()
	var prefs:=SettingsManager.new();prefs.path=path;prefs.load_saved()
	check(prefs.music_volume==.35 and prefs.effects_volume==1.0 and not prefs.muted,"new installs default to 35 percent music and the existing effects level")
	prefs.music_volume=.27;prefs.effects_volume=.64;prefs.muted=true
	check(prefs.save(),"audio preferences save independently of the campaign")
	var loaded:=SettingsManager.new();loaded.path=path;loaded.load_saved()
	check(is_equal_approx(loaded.music_volume,.27) and is_equal_approx(loaded.effects_volume,.64) and loaded.muted,"both volume levels and mute survive a new settings instance")
	var malformed:=ConfigFile.new();malformed.set_value("meta","version",1);malformed.set_value("audio","music",10);malformed.set_value("audio","effects","invalid");malformed.set_value("audio","muted",25);malformed.save(path)
	loaded.load_saved()
	check(loaded.music_volume==1.0 and loaded.effects_volume==1.0 and not loaded.muted,"out-of-range or malformed preference values fall back safely")
	var game=load("res://scenes/battle/battle.tscn").instantiate();root.add_child(game)
	await process_frame;await process_frame
	var audio:AudioManager=game.audio;audio.preferences.path=path;audio.preferences.persistence_enabled=true
	var music_bus:=AudioServer.get_bus_index(AudioManager.MUSIC_BUS);var effects_bus:=AudioServer.get_bus_index(AudioManager.EFFECTS_BUS)
	check(audio.music.playing and is_equal_approx(AudioServer.get_bus_volume_db(music_bus),linear_to_db(.35)),"the medieval soundtrack starts at the saved/default music gain")
	var stream:AudioStreamOggVorbis=audio.music.stream
	check(stream.loop and absf(stream.get_length()-80.0)<.05,"compressed stereo music is configured as an 80-second loop")
	var playback:AudioStreamPlayback=stream.instantiate_playback();playback.start(stream.get_length()-.03)
	var decoded:PackedVector2Array=playback.mix_audio(1.0,8192);var peak:=0.0
	for sample in decoded:peak=maxf(peak,maxf(absf(sample.x),absf(sample.y)))
	check(playback.get_loop_count()>0 and decoded.size()==8192 and peak>.01 and peak<1.0,"Godot decodes audible music across the loop boundary without clipping")
	playback.stop();playback=null;stream=null
	game.hud.show_settings();await process_frame
	check(paused and not audio.music.stream_paused and not game.camera.enabled,"Settings pauses combat and scouting while music remains adjustable")
	var safe_rect:=Rect2(Vector2(16,12),root.get_visible_rect().size-Vector2(32,28))
	check(safe_rect.encloses(game.hud.overlay.get_global_rect()),"the complete audio panel fits the landscape safe area")
	game.hud.music_slider.value=22;game.hud.effects_slider.value=75
	check(is_equal_approx(AudioServer.get_bus_volume_db(music_bus),linear_to_db(.22)) and is_equal_approx(AudioServer.get_bus_volume_db(effects_bus),linear_to_db(.75)),"both sliders change their actual playback buses immediately")
	audio.preview_effects()
	check(audio.interface_player.playing and not audio.interface_player.stream_paused,"effects preview is audible while the battle is paused")
	var previews_ok:=true
	for kind in AudioManager.VOICE_KINDS:
		var button:=find_button(game.hud.overlay,"Test "+kind)
		previews_ok=previews_ok and button!=null
		if button:
			button.pressed.emit()
			var voice:AudioStreamPlayer=audio.voice_players[AudioManager.VOICE_KINDS.find(kind)]
			previews_ok=previews_ok and voice.playing and not voice.stream_paused and game.hud.audio_status.text.begins_with(kind.capitalize())
	check(previews_ok and paused,"all three visible death-test buttons play their own family while gameplay stays paused")
	var mute:=find_mute(game.hud.overlay);mute.button_pressed=true
	check(AudioServer.is_bus_mute(music_bus) and AudioServer.is_bus_mute(effects_bus),"Mute all audio silences both buses")
	find_button(game.hud.overlay,"Test ogre").pressed.emit()
	check(game.hud.audio_status.text.contains("Turn up Sound effects"),"a muted death preview explains which setting to change")
	mute.button_pressed=false;game.hud.music_slider.value=0
	check(AudioServer.is_bus_mute(music_bus) and not AudioServer.is_bus_mute(effects_bus),"zero music volume leaves battle effects enabled")
	game.hud.music_slider.value=22;game.hud.close_credits();await process_frame
	loaded.load_saved()
	check(not paused and is_equal_approx(loaded.music_volume,.22) and is_equal_approx(loaded.effects_volume,.75),"closing Settings saves both levels and resumes a previously running battle")
	audio.cue("horn");game.set_paused(true);game.hud.show_settings();game.hud.close_credits()
	check(paused,"closing Settings preserves a pre-existing pause")
	audio.set_backgrounded(true)
	check(audio.music.stream_paused and audio.interface_player.stream_paused,"leaving the app suspends music and interface audio")
	audio.set_backgrounded(false)
	check(not audio.music.stream_paused and paused and audio.players[0].stream_paused,"returning restores music while combat remains paused")
	game.retry_wave()
	check(is_equal_approx(audio.preferences.music_volume,.22) and is_equal_approx(audio.preferences.effects_volume,.75),"retrying a wave does not reset audio preferences")
	audio.stop_all();await create_timer(.2,true).timeout
	game.queue_free();await process_frame;paused=false
	DirAccess.remove_absolute(path)
	print("AUDIO SETTINGS COMPLETE failures=",failures);quit(failures)
