extends SceneTree
## Fatal-hit integration, bounded voice mixing, sound settings and damage tuning.
var failures:=0
func _initialize():call_deferred("run")
func check(ok: bool,label: String):
	if ok:print("PASS: "+label)
	else:push_error("FAIL: "+label);failures+=1
func run():
	var game=load("res://scenes/battle/battle.tscn").instantiate();root.add_child(game)
	game.set_physics_process(false);game.projectiles.set_process(false)
	for unit in game.units:unit.set_physics_process(false)
	await process_frame
	var audio:AudioManager=game.audio;audio.stop_all();audio.muted=false
	var heard:Array[String]=[];audio.defeat_voice_played.connect(func(kind):heard.append(kind))
	var man:UnitController=game.units[0]
	man.take_damage(1)
	check(heard.is_empty(),"ordinary hits do not trigger defeat voices")
	man.take_damage(10000);man.take_damage(10000)
	check(heard==["human"] and man.anim=="defeat","a fatal defender hit triggers one human oof with the falling animation")
	var p:AudioStreamPlayer=audio.voice_players[0]
	check(p.playing and p.bus==AudioManager.VOICE_BUS and AudioServer.get_bus_send(AudioServer.get_bus_index(p.bus))==AudioManager.EFFECTS_BUS,"defeat playback uses the actual adjustable effects bus")
	var first:AudioStream=p.stream
	game.set_paused(true);var position:=p.get_playback_position()
	await create_timer(.1,true).timeout
	check(p.stream_paused and absf(p.get_playback_position()-position)<.04 and not audio.defeat_voice("ogre"),"Pause freezes a voiced fall and blocks new battle voices")
	game.set_paused(false)
	check(not p.stream_paused,"Resume continues the same defeat sound")
	audio.stop_all();heard.clear()
	var ogre:UnitController=game.spawn("ogre",true,Vector3(20,0,0));ogre.set_physics_process(false)
	ogre.take_damage(10000)
	check(heard==["ogre"],"a fallen siege ogre selects a deep grunt")
	audio.stop_all();heard.clear()
	var orc:UnitController=game.spawn("raider",true,Vector3(20,0,2));orc.set_physics_process(false)
	orc.take_damage(10000)
	check(heard==["orc"],"an orc uses a rough creature voice rather than a human voice")
	var categories:=true
	for id in ["ogre_warthog","ogre_shaman","boss_gatebreaker","boss_dreadscale","boss_ashcaller","boss_ironjaw"]:
		categories=categories and game.definitions[id].defeat_voice=="ogre"
	check(categories and game.definitions.knight.defeat_voice=="human","mounted and giant characters retain their rider's voice identity")
	audio.stop_all();heard.clear()
	for i in 100:audio.defeat_voice("ogre")
	check(heard.size()==1 and audio.voice_players.size()==3,"a simultaneous crowd defeat cannot queue a wall of grunts or grow the voice pool")
	check(audio.defeat_voice("human") and audio.defeat_voice("orc") and heard==["ogre","human","orc"],"human, orc and ogre deaths can be heard together without suppressing another family")
	audio._process(.08)
	check(audio.music.volume_db<=-4.9 and AudioServer.get_bus_volume_db(AudioServer.get_bus_index(AudioManager.COMBAT_BUS))<=-8.9 and p.volume_db>=-2.01,"voices retain a clear gain while impacts and music duck around them")
	audio.stop_all();audio._process(.3)
	check(is_zero_approx(audio.music.volume_db) and is_zero_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(AudioManager.COMBAT_BUS))),"the normal music and impact mix returns after the voices end")
	game.set_paused(true)
	check(audio.preview_defeat("ogre") and audio.voice_players[2].playing and not audio.voice_players[2].stream_paused and not audio.defeat_voice("human"),"Settings can preview a real ogre grunt while battle deaths remain paused")
	audio.stop_voice_previews()
	check(not audio.voice_players[2].playing and paused,"closing the preview stops it without resuming the battle")
	game.set_paused(false)
	audio.stop_all();audio.defeat_voice("human")
	check(audio.voice_players[0].stream!=first,"repeated human defeats rotate through distinct original clips")
	audio.set_backgrounded(true)
	check(audio.voice_players[0].stream_paused and not audio.defeat_voice("ogre"),"backgrounding suspends voices and suppresses new cues")
	audio.set_backgrounded(false);audio.stop_all();audio.set_effects_volume(0)
	check(not audio.defeat_voice("human"),"zero effects volume disables defeat voices without altering music")
	audio.set_effects_volume(.5);audio.muted=true
	check(not audio.defeat_voice("ogre"),"Mute all audio also suppresses defeat voices")
	audio.muted=false;audio.stop_all()
	var decoded_ok:=true;var distinct:Dictionary={}
	for bank in audio.voices.values():
		for stream:AudioStreamWAV in bank:
			var playback:=stream.instantiate_playback();playback.start()
			var samples:=playback.mix_audio(1.0,24000);var peak:=0.0
			for sample in samples:peak=maxf(peak,absf(sample.x))
			decoded_ok=decoded_ok and peak>.1 and peak<.98 and stream.get_length()<=.7 and not stream.stereo
			distinct[hash(stream.data)]=true;playback.stop()
	check(decoded_ok and distinct.size()==9,"all nine short mono voices decode audibly without clipped samples")
	audio.set_effects_volume(1);audio.stop_all()
	var capture:=AudioEffectCapture.new();capture.buffer_length=1.0
	var capture_index:=AudioServer.get_bus_effect_count(0);AudioServer.add_bus_effect(0,capture)
	audio.preview_defeat("human")
	await create_timer(.3,true).timeout
	var mix:=capture.get_buffer(capture.get_frames_available());var power:=0.0;var mixed_peak:=0.0
	for sample in mix:power+=sample.length_squared()*.5;mixed_peak=maxf(mixed_peak,maxf(absf(sample.x),absf(sample.y)))
	var rms:=sqrt(power/maxi(1,mix.size()))
	print("VOICE OUTPUT frames=",mix.size()," rms=",rms," peak=",mixed_peak)
	check(mix.size()>2000 and rms>.12 and mixed_peak>.35 and mixed_peak<1.0,"a death voice reaches the actual final audio mix at a clear unclipped level")
	audio.stop_all();capture.clear_buffer()
	for kind in AudioManager.VOICE_KINDS:audio.defeat_voice(kind)
	await create_timer(.3,true).timeout
	mix=capture.get_buffer(capture.get_frames_available());mixed_peak=0.0
	for sample in mix:mixed_peak=maxf(mixed_peak,maxf(absf(sample.x),absf(sample.y)))
	check(mix.size()>2000 and mixed_peak>.35 and mixed_peak<.95,"three simultaneous voice families stay audible below the final output ceiling")
	AudioServer.remove_bus_effect(0,capture_index);audio.stop_all()
	game.clear_army();await process_frame
	var enemy:UnitController=game.spawn("mounted_raider",true,Vector3(12,0,0),100);enemy.set_physics_process(false)
	var defender:UnitController=game.spawn("swordsman",false,Vector3(11,0,0));defender.set_physics_process(false)
	var boost:float=game.balance.attacker_damage_multiplier
	var expected:float=enemy.data.damage*(1+90*float(game.balance.damage_growth))*boost
	check(boost>1 and boost<=1.15 and is_equal_approx(enemy.damage_against(defender),expected) and defender.damage_scale==1.0,"attacker damage increases while defender damage and normal wave scaling keep their separate rules")
	enemy.target=defender;enemy.windup=.001;enemy.charge_distance=4;enemy.cooldown=2;enemy._physics_process(.002)
	check(is_equal_approx(defender.max_hp-defender.hp,(expected+enemy.data.charge_damage*boost)*(1-defender.data.armor)),"late cavalry charges gain the attack increase without accidental extra growth scaling")
	game.phase="tests_complete";audio.stop_all();await create_timer(.15,true).timeout
	game.queue_free();await process_frame;print("DEFEAT VOICES COMPLETE failures=",failures);quit(failures)
