class_name AudioManager
extends Node
signal preferences_save_failed
signal defeat_voice_played(kind: String)
const MUSIC_BUS:="Castlehold Music"
const EFFECTS_BUS:="Castlehold Effects"
const COMBAT_BUS:="Castlehold Combat"
const VOICE_BUS:="Castlehold Voices"
const VOICE_KINDS:=["human","orc","ogre"]
var players: Array[AudioStreamPlayer] = []
var voice_players: Array[AudioStreamPlayer] = []
var voices: Dictionary = {}
var voice_last: Dictionary = {}
var voice_variant: Dictionary = {}
var duck_amount:=0.0
var music: AudioStreamPlayer
var interface_player: AudioStreamPlayer
var preferences:=SettingsManager.new()
var save_timer: Timer
var dirty:=false
var backgrounded:=false
var battle_paused:=false
var sounds: Dictionary={}
var muted: bool:
	get:return preferences.muted
	set(value):
		preferences.muted=value
		if is_node_ready():apply_levels();schedule_save()
var last: Dictionary = {}
var pitch_rng:=RandomNumberGenerator.new()
func _ready():
	# Music stays audible in Settings/Pause; backgrounding suspends everything.
	process_mode=Node.PROCESS_MODE_ALWAYS
	preferences.persistence_enabled=not OS.get_cmdline_user_args().has("--test") and not OS.get_cmdline_user_args().has("--smoke")
	preferences.load_saved()
	for name in [MUSIC_BUS,EFFECTS_BUS,COMBAT_BUS,VOICE_BUS]:
		if AudioServer.get_bus_index(name)<0:
			AudioServer.add_bus();AudioServer.set_bus_name(AudioServer.bus_count-1,name)
	for name in [COMBAT_BUS,VOICE_BUS]:AudioServer.set_bus_send(AudioServer.get_bus_index(name),EFFECTS_BUS)
	# Keep simultaneous cries and impacts within the final output headroom.
	var has_limiter:=false
	for i in AudioServer.get_bus_effect_count(0):
		if AudioServer.get_bus_effect(0,i).has_meta("castlehold_limiter"):has_limiter=true
	if not has_limiter:
		var limiter:=AudioEffectHardLimiter.new();limiter.ceiling_db=-.6;limiter.set_meta("castlehold_limiter",true)
		AudioServer.add_bus_effect(0,limiter)
	for id in ["hit","bow","gate","collapse","coin","horn","victory","defeat","fire_cast","fire_impact","boss_roar","boss_slam"]:sounds[id]=load("res://assets/audio/"+id+".wav")
	for i in 8:
		var p := AudioStreamPlayer.new();p.volume_db=-12;p.bus=COMBAT_BUS;add_child(p);players.append(p)
	for kind in VOICE_KINDS:
		voices[kind]=[]
		for i in 3:voices[kind].append(load("res://assets/audio/voices/"+kind+"_defeat_"+str(i+1)+".wav"))
		# Each family owns one slot: a rain of orc deaths cannot suppress an ogre.
		var p:=AudioStreamPlayer.new();p.name="DefeatVoice_"+kind;p.volume_db=-2;p.bus=VOICE_BUS
		p.set_meta("voice_kind",kind);p.set_meta("preview",false)
		add_child(p);voice_players.append(p)
	interface_player=AudioStreamPlayer.new();interface_player.volume_db=-12;interface_player.bus=EFFECTS_BUS;add_child(interface_player)
	music=AudioStreamPlayer.new();music.name="MedievalSoundtrack";music.bus=MUSIC_BUS
	var stream:AudioStreamOggVorbis=load("res://assets/audio/music/valley_watch.ogg")
	stream.loop=true;stream.loop_offset=0;music.stream=stream;add_child(music)
	save_timer=Timer.new();save_timer.one_shot=true;save_timer.wait_time=.4;save_timer.ignore_time_scale=true;add_child(save_timer);save_timer.timeout.connect(save_preferences)
	apply_levels();music.play()
func _process(delta: float):
	# Voices/music play in real time, so their gain envelope must do the same.
	delta/=Engine.time_scale
	var speaking:=false
	for p in voice_players:
		if p.playing and not p.stream_paused:speaking=true
	duck_amount=move_toward(duck_amount,1.0 if speaking else 0.0,delta*(30.0 if speaking else 5.0))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(COMBAT_BUS),-9.0*duck_amount)
	if is_instance_valid(music):music.volume_db=-5.0*duck_amount
func apply_levels():
	for pair in [[MUSIC_BUS,preferences.music_volume],[EFFECTS_BUS,preferences.effects_volume]]:
		var bus:=AudioServer.get_bus_index(pair[0]);var value:float=pair[1]
		AudioServer.set_bus_volume_db(bus,linear_to_db(maxf(value,.0001)))
		AudioServer.set_bus_mute(bus,preferences.muted or value<=0)
func set_music_volume(value: float):
	preferences.music_volume=preferences.level(value,SettingsManager.DEFAULT_MUSIC);apply_levels();schedule_save()
func set_effects_volume(value: float):
	preferences.effects_volume=preferences.level(value,SettingsManager.DEFAULT_EFFECTS);apply_levels();schedule_save()
func schedule_save():
	dirty=true;save_timer.start()
func save_preferences():
	if not dirty:return
	save_timer.stop()
	if preferences.save():dirty=false
	else:preferences_save_failed.emit()
func set_battle_paused(value: bool):
	battle_paused=value
	for p in players:p.stream_paused=battle_paused or backgrounded
	for p in voice_players:p.stream_paused=backgrounded or (battle_paused and not bool(p.get_meta("preview",false)))
func set_backgrounded(value: bool):
	backgrounded=value;music.stream_paused=value;interface_player.stream_paused=value
	set_battle_paused(battle_paused)
	if value:save_preferences()
func preview_effects():
	if muted or backgrounded:return
	interface_player.volume_db=-12
	interface_player.stream=sounds.hit;interface_player.play()
func defeat_voice(kind: String) -> bool:
	return play_voice(kind,false)
func preview_defeat(kind: String) -> bool:
	# Use the real clip, gain and mixing while Settings has the battle paused.
	for p in voice_players:p.stop()
	voice_last.clear()
	return play_voice(kind,true)
func stop_voice_previews():
	for p in voice_players:
		if bool(p.get_meta("preview",false)):p.stop();p.set_meta("preview",false)
func play_voice(kind: String, preview: bool) -> bool:
	if muted or backgrounded or (battle_paused and not preview) or preferences.effects_volume<=0 or not voices.has(kind):return false
	var now:=Time.get_ticks_msec()
	var chosen:AudioStreamPlayer=voice_players[VOICE_KINDS.find(kind)]
	# Never queue late cries or cut off the previous cry to restart a crowd sample.
	if chosen.playing or now-int(voice_last.get(kind,-1000))<180:return false
	var index:=int(voice_variant.get(kind,0))%3;voice_variant[kind]=(index+1)%3
	chosen.stream=voices[kind][index];chosen.set_meta("preview",preview)
	chosen.pitch_scale=pitch_rng.randf_range(.97,1.03);chosen.volume_db=-2
	chosen.stream_paused=false;chosen.play();voice_last[kind]=now;defeat_voice_played.emit(kind)
	return true
func cue(id: String):
	if muted or backgrounded or not sounds.has(id):return
	var now := Time.get_ticks_msec()
	if now-int(last.get(id,0)) < 70: return
	last[id]=now
	if id=="coin":interface_player.volume_db=-12;interface_player.stream=sounds.coin;interface_player.play();return
	if battle_paused:return
	for p in players:
		if not p.playing:
			p.stream=sounds[id]
			p.pitch_scale=pitch_rng.randf_range(.95,1.05);p.play();return
func _exit_tree():
	if dirty:preferences.save()
	stop_all()
func stop_all():
	if is_instance_valid(music):music.stop();music.stream=null
	if is_instance_valid(interface_player):interface_player.stop();interface_player.stream=null
	for player in players:
		if is_instance_valid(player):player.stop();player.stream=null
	for player in voice_players:
		if is_instance_valid(player):player.stop();player.stream=null
	voice_last.clear();duck_amount=0
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(COMBAT_BUS),0)
	if is_instance_valid(music):music.volume_db=0
