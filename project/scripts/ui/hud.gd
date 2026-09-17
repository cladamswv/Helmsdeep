class_name CastleHUD
extends CanvasLayer
var game: Node3D
var safe: MarginContainer
var top: Label
var message: Label
var detail: Label
var pause_label: Label
var cards: HBoxContainer
var repair: Button
var repair_keep: Button
var retry: Button
var overlay: PanelContainer
var pause_button: Button
var speed_button: Button
var speed_choices: Dictionary = {}
var recenter_button: Button
var recruit_buttons: Dictionary = {}
var was_paused := false
var backdrop: ColorRect
var overlay_kind:=""
var music_slider: HSlider
var effects_slider: HSlider
var audio_status: Label
var boss_panel: PanelContainer
var boss_title: Label
var boss_health: ProgressBar
func style(color: String) -> StyleBoxFlat:
	var s:=StyleBoxFlat.new();s.bg_color=Color(color);s.border_color=Color("b49458")
	s.set_border_width_all(1);s.set_corner_radius_all(12);s.content_margin_left=12;s.content_margin_right=12;s.content_margin_top=9;s.content_margin_bottom=9
	s.shadow_color=Color(0.025,.04,.045,.40);s.shadow_size=5;s.shadow_offset=Vector2(0,3)
	return s
func button(text: String, action: Callable, width: float=150) -> Button:
	var b:=Button.new();b.text=text;b.custom_minimum_size=Vector2(width,60)
	b.add_theme_stylebox_override("normal",style("192d38ef"));b.add_theme_stylebox_override("hover",style("345364"))
	b.add_theme_stylebox_override("pressed",style("9b7438"));b.add_theme_stylebox_override("disabled",style("1c252cdd"))
	b.add_theme_color_override("font_color",Color("f1e4c5"));b.add_theme_color_override("font_disabled_color",Color("889497"))
	b.add_theme_font_size_override("font_size",19);b.pressed.connect(action)
	b.button_down.connect(func():b.self_modulate=Color("d5b785"))
	b.button_up.connect(func():
		var tween:=b.create_tween();tween.set_ignore_time_scale(true);tween.tween_property(b,"self_modulate",Color.WHITE,.14))
	return b
func _ready():process_mode=Node.PROCESS_MODE_ALWAYS
func build(owner_game: Node3D):
	game=owner_game
	safe=MarginContainer.new();add_child(safe);safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);safe.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var column:=VBoxContainer.new();safe.add_child(column);column.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var top_panel:=PanelContainer.new();column.add_child(top_panel);top_panel.add_theme_stylebox_override("panel",style("102430eb"))
	var row:=HBoxContainer.new();top_panel.add_child(row)
	top=Label.new();top.add_theme_font_size_override("font_size",18);top.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(top)
	top.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	top.add_theme_color_override("font_color",Color("eddfbb"))
	recenter_button=button("Castle",func():game.camera.recenter(),94);row.add_child(recenter_button);recenter_button.disabled=true
	game.camera.pan_changed.connect(func(away:bool):recenter_button.disabled=not away)
	speed_button=button("Speed 1×",cycle_speed,130);speed_button.tooltip_text="Battle speed: 1×, 1.5× or 2×";row.add_child(speed_button)
	pause_button=button("Pause",toggle_pause,98);row.add_child(pause_button)
	row.add_child(button("Settings",show_settings,112));row.add_child(button("Credits",show_credits,94))
	boss_panel=PanelContainer.new();boss_panel.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
	boss_panel.custom_minimum_size=Vector2(560,0);boss_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
	boss_panel.add_theme_stylebox_override("panel",style("2b2523df"));column.add_child(boss_panel)
	var boss_column:=VBoxContainer.new();boss_column.mouse_filter=Control.MOUSE_FILTER_IGNORE;boss_panel.add_child(boss_column)
	boss_title=Label.new();boss_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;boss_title.add_theme_font_size_override("font_size",19)
	boss_title.mouse_filter=Control.MOUSE_FILTER_IGNORE;boss_column.add_child(boss_title)
	boss_health=ProgressBar.new();boss_health.custom_minimum_size=Vector2(0,12);boss_health.show_percentage=false
	boss_health.mouse_filter=Control.MOUSE_FILTER_IGNORE;boss_column.add_child(boss_health)
	var boss_fill:=StyleBoxFlat.new();boss_fill.bg_color=Color("cb773c");boss_fill.set_corner_radius_all(5)
	var empty:=StyleBoxFlat.new();empty.bg_color=Color("121f26");empty.set_corner_radius_all(5)
	boss_health.add_theme_stylebox_override("fill",boss_fill);boss_health.add_theme_stylebox_override("background",empty);boss_panel.hide()
	game.audio.preferences_save_failed.connect(func():
		if is_instance_valid(audio_status):audio_status.text="Couldn't save settings. Changes work for this session.")
	var space:=Control.new();space.size_flags_vertical=Control.SIZE_EXPAND_FILL;space.mouse_filter=Control.MOUSE_FILTER_IGNORE;column.add_child(space)
	pause_label=Label.new();pause_label.text="PAUSED • Recruit and repair, then tap Resume";pause_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	pause_label.add_theme_font_size_override("font_size",25);pause_label.mouse_filter=Control.MOUSE_FILTER_IGNORE;column.add_child(pause_label)
	message=Label.new();message.mouse_filter=Control.MOUSE_FILTER_IGNORE;message.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;message.add_theme_font_size_override("font_size",32);column.add_child(message)
	message.add_theme_color_override("font_color",Color("ffe0a0"));message.add_theme_color_override("font_shadow_color",Color("192526"));message.add_theme_constant_override("shadow_offset_y",2)
	detail=Label.new();detail.mouse_filter=Control.MOUSE_FILTER_IGNORE;detail.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;detail.add_theme_font_size_override("font_size",17);column.add_child(detail)
	var bottom:=HBoxContainer.new();column.add_child(bottom);bottom.alignment=BoxContainer.ALIGNMENT_CENTER
	cards=HBoxContainer.new();bottom.add_child(cards)
	for id in game.FRIENDLIES:
		var card:=button("",func():game.purchase(id),192);card.custom_minimum_size.y=88;cards.add_child(card);recruit_buttons[id]=card
		var view:=SubViewport.new();view.size=Vector2i(192,192);view.transparent_bg=true;view.own_world_3d=true
		view.msaa_3d=Viewport.MSAA_2X
		view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;add_child(view)
		var model:Node3D=game.definitions[id].model.instantiate();view.add_child(model);model.rotation.y=.30;CharacterPresentation.apply(model)
		var animation:=find_animation(model)
		if animation:animation.play("idle");animation.advance(0);animation.pause()
		var cam:=Camera3D.new();view.add_child(cam)
		var y:float=2.61 if id=="knight" else 1.65
		cam.position=Vector3(.26,y+.16,-2.35);cam.look_at(Vector3(0,y,0));cam.fov=35
		var sun:=DirectionalLight3D.new();view.add_child(sun);sun.rotation_degrees=Vector3(-35,-145,0);sun.light_color=Color("ffe3b7");sun.light_energy=1.0
		var fill:=DirectionalLight3D.new();view.add_child(fill);fill.rotation_degrees=Vector3(-15,20,0);fill.light_color=Color("9bc2dc");fill.light_energy=.42
		var world:=WorldEnvironment.new();world.environment=Environment.new();var sky:=Sky.new();var sky_mat:=ProceduralSkyMaterial.new()
		sky_mat.sky_top_color=Color("85a5ba");sky_mat.sky_horizon_color=Color("e2d5b9");sky.sky_material=sky_mat;sky.radiance_size=Sky.RADIANCE_SIZE_32
		world.environment.sky=sky;world.environment.ambient_light_source=Environment.AMBIENT_SOURCE_SKY;world.environment.ambient_light_energy=.45
		world.environment.reflected_light_source=Environment.REFLECTION_SOURCE_SKY;world.environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC;view.add_child(world)
		card.icon=view.get_texture();card.expand_icon=true;card.add_theme_constant_override("icon_max_width",70)
		settle_portrait(view)
		card.tooltip_text={"archer":"Long-range arrows. Prioritizes ogres within range.","swordsman":"Durable sword-and-shield defender. Cut through Ironshield orcs.","spearman":"Long reach. Double damage against warg riders and other cavalry.","knight":"Armored cavalry. Flanks enemy hunters; withdraws when badly hurt."}[id]
	repair=button("Repair\nGate",func():game.repair_gate(),126);cards.add_child(repair)
	repair_keep=button("Repair\nKeep",func():game.repair_structure("keep"),126);cards.add_child(repair_keep)
	retry=button("RETRY WAVE",func():game.retry_wave(),230);bottom.add_child(retry);retry.hide()
	get_viewport().size_changed.connect(update_safe_area);update_safe_area()
func settle_portrait(view: SubViewport):
	# Give sky reflections several frames to initialize, then cache the portrait.
	for frame in 6:await get_tree().process_frame
	if is_instance_valid(view):view.render_target_update_mode=SubViewport.UPDATE_DISABLED
func find_animation(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:return node
	for child in node.get_children():
		var result:=find_animation(child)
		if result:return result
	return null
func update_safe_area():
	var area:=DisplayServer.get_display_safe_area();var screen:=DisplayServer.screen_get_size();var logical:=get_viewport().get_visible_rect().size
	var left:=16;var right:=16;var up:=12;var down:=16
	if OS.has_feature("mobile") and screen.x>0 and area.size.x>0:
		left=maxi(left,int(area.position.x*logical.x/screen.x));right=maxi(right,int((screen.x-area.end.x)*logical.x/screen.x))
		up=maxi(up,int(area.position.y*logical.y/screen.y));down=maxi(down,int((screen.y-area.end.y)*logical.y/screen.y))
	for pair in [["left",left],["right",right],["top",up],["bottom",down]]:safe.add_theme_constant_override("margin_"+pair[0],pair[1])
	position_overlay()
func position_overlay():
	if not is_instance_valid(overlay):return
	var logical:=get_viewport().get_visible_rect().size
	var top_left:=Vector2(safe.get_theme_constant("margin_left"),safe.get_theme_constant("margin_top"))
	var bottom_right:=Vector2(safe.get_theme_constant("margin_right"),safe.get_theme_constant("margin_bottom"))
	var available:=logical-top_left-bottom_right
	overlay.position=top_left+(available-overlay.size)*.5
func refresh():
	if not top or not game.director:return
	var boss:UnitController;var count:=0
	for unit in game.units:
		if unit.enemy and unit.hp>0 and unit.data.boss:
			count+=1
			if not boss or unit.source_wave<boss.source_wave:boss=unit
	boss_panel.visible=is_instance_valid(boss)
	if boss:
		boss_title.text="%s • %d%%"%[boss.data.title.to_upper(),ceili(boss.hp/boss.max_hp*100)]
		if boss.boss_combat.windup>=0:boss_title.text+=" • "+boss.data.boss.warning
		elif count>1:boss_title.text+=" • +%d BOSS"%(count-1)
		boss_health.max_value=boss.max_hp;boss_health.value=boss.hp
	var status:="ATTACK %ds"%ceili(maxf(0,game.director.remaining))
	if game.phase=="gap":status="NEXT WAVE %d IN %ds"%[game.director.wave+1,ceili(maxf(0,game.director.remaining))]
	elif game.phase=="final":status="CLEAR THE REMAINING ENEMIES"
	elif game.phase in ["defeat","complete"]:status=game.phase.to_upper()
	top.text="%d GOLD    •    WAVE %d / %d    •    %s\nGATE %d%%    •    KEEP %d%%    •    %d ENEMIES"%[game.economy.gold,game.wave,int(game.balance.wave_count),status,game.castle.structures.gate.hp/game.castle.structures.gate.max_hp*100,game.castle.structures.keep.hp/game.castle.structures.keep.max_hp*100,game.enemy_count()]
	pause_label.visible=get_tree().paused and game.live_play();pause_button.text="Resume" if get_tree().paused else "Pause"
	pause_button.disabled=not game.live_play() or is_instance_valid(overlay)
	speed_button.text="Speed "+SettingsManager.speed_label(game.battle_speed)
	speed_button.disabled=not game.live_play() or is_instance_valid(overlay)
	for speed in speed_choices:
		speed_choices[speed].set_pressed_no_signal(is_equal_approx(speed,game.battle_speed))
	cards.visible=game.live_play();retry.visible=game.phase in ["defeat","complete"];retry.text="PLAY AGAIN" if game.phase=="complete" else "RETRY WAVE"
	for id in recruit_buttons:
		var b:Button=recruit_buttons[id];b.text="%s ×%d\n%d gold"%[game.definitions[id].title,game.army[id],game.definitions[id].cost];b.disabled=not game.can_purchase(id)
	for pair in [[repair,"gate"],[repair_keep,"keep"]]:
		var structure:CastleStructure=game.castle.structures[pair[1]]
		pair[0].disabled=not game.live_play() or structure.hp>=structure.max_hp or structure.repair_used>=structure.max_hp*float(game.balance.repair_fraction) or game.economy.gold<=0
func toggle_pause():
	if game.live_play() and not is_instance_valid(overlay):game.set_paused(not get_tree().paused)
func cycle_speed():
	if speed_button.disabled:return
	var next:=(SettingsManager.BATTLE_SPEEDS.find(game.battle_speed)+1)%SettingsManager.BATTLE_SPEEDS.size()
	game.set_battle_speed(SettingsManager.BATTLE_SPEEDS[next])
func begin_overlay(kind: String,size: Vector2) -> VBoxContainer:
	if is_instance_valid(overlay):close_credits()
	was_paused=get_tree().paused;game.set_paused(true);game.camera.set_interaction_enabled(false)
	overlay_kind=kind
	backdrop=ColorRect.new();backdrop.color=Color(.018,.035,.045,.72);add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);backdrop.mouse_filter=Control.MOUSE_FILTER_STOP
	overlay=PanelContainer.new();add_child(overlay);overlay.size=size;overlay.add_theme_stylebox_override("panel",style("142c38"))
	var col:=VBoxContainer.new();col.add_theme_constant_override("separation",12);overlay.add_child(col)
	overlay.resized.connect(position_overlay);position_overlay();refresh();return col
func add_volume_control(parent: VBoxContainer,label: String,value: float,apply: Callable) -> HSlider:
	var row:=HBoxContainer.new();parent.add_child(row)
	var title:=Label.new();title.text=label;title.add_theme_font_size_override("font_size",22);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(title)
	var percent:=Label.new();percent.text="%d%%"%roundi(value*100);percent.add_theme_font_size_override("font_size",22);percent.add_theme_color_override("font_color",Color("f2d392"));row.add_child(percent)
	var slider:=HSlider.new();slider.min_value=0;slider.max_value=100;slider.step=1;slider.value=roundi(value*100)
	slider.custom_minimum_size=Vector2(480,64);slider.size_flags_horizontal=Control.SIZE_EXPAND_FILL;slider.scrollable=false
	var rail:=StyleBoxFlat.new();rail.bg_color=Color("091c26");rail.set_corner_radius_all(5);rail.content_margin_top=4;rail.content_margin_bottom=4
	var fill:=rail.duplicate();fill.bg_color=Color("d2af69")
	slider.add_theme_stylebox_override("slider",rail);slider.add_theme_stylebox_override("grabber_area",fill);slider.add_theme_stylebox_override("grabber_area_highlight",fill)
	for name in ["grabber","grabber_highlight"]:slider.add_theme_icon_override(name,load("res://assets/ui/volume_knob.svg"))
	parent.add_child(slider)
	slider.value_changed.connect(func(next: float):percent.text="%d%%"%roundi(next);apply.call(next/100.0))
	return slider
func show_settings():
	if is_instance_valid(overlay) and overlay_kind=="settings":close_credits();return
	var col:=begin_overlay("settings",Vector2(760,640))
	var title:=Label.new();title.text="SETTINGS";title.add_theme_font_size_override("font_size",30);title.add_theme_color_override("font_color",Color("f1d18d"));col.add_child(title)
	var speeds:=HBoxContainer.new();col.add_child(speeds)
	var speed_title:=Label.new();speed_title.text="Battle speed";speed_title.add_theme_font_size_override("font_size",22);speed_title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;speeds.add_child(speed_title)
	var speed_group:=ButtonGroup.new()
	for value in SettingsManager.BATTLE_SPEEDS:
		var choice:=button(SettingsManager.speed_label(value),func():game.set_battle_speed(value),120)
		choice.toggle_mode=true;choice.button_group=speed_group;choice.set_pressed_no_signal(is_equal_approx(value,game.battle_speed))
		speeds.add_child(choice);speed_choices[value]=choice
	var subtitle:=Label.new();subtitle.text="The Valley Watch • Original medieval instrumental";subtitle.add_theme_font_size_override("font_size",18);col.add_child(subtitle)
	music_slider=add_volume_control(col,"Music",game.audio.preferences.music_volume,game.audio.set_music_volume)
	effects_slider=add_volume_control(col,"Sound effects",game.audio.preferences.effects_volume,game.audio.set_effects_volume)
	var mute:=CheckButton.new();mute.text="Mute all audio";mute.custom_minimum_size=Vector2(0,60);mute.add_theme_font_size_override("font_size",22);mute.button_pressed=game.audio.muted
	mute.toggled.connect(func(value:bool):game.audio.muted=value);col.add_child(mute)
	var voices:=HBoxContainer.new();voices.alignment=BoxContainer.ALIGNMENT_CENTER;col.add_child(voices)
	for pair in [["human","Test human"],["orc","Test orc"],["ogre","Test ogre"]]:
		var kind:String=pair[0]
		voices.add_child(button(pair[1],func():preview_voice(kind),190))
	audio_status=Label.new();audio_status.text="Music keeps playing here so you can adjust it.";audio_status.add_theme_font_size_override("font_size",17);col.add_child(audio_status)
	var actions:=HBoxContainer.new();actions.alignment=BoxContainer.ALIGNMENT_END;col.add_child(actions)
	actions.add_child(button("Test effects",game.audio.preview_effects,170));actions.add_child(button("Close",close_credits,150))
func preview_voice(kind: String):
	var played:bool=game.audio.preview_defeat(kind)
	if is_instance_valid(audio_status):
		audio_status.text=kind.capitalize()+" death voice • Adjust with Sound effects." if played else "Turn up Sound effects and turn off Mute all audio."
func show_credits():
	if is_instance_valid(overlay) and overlay_kind=="credits":close_credits();return
	var col:=begin_overlay("credits",Vector2(940,575))
	var text:=TextEdit.new();text.custom_minimum_size=Vector2(900,460);text.editable=false
	text.text="CASTLEHOLD — Warcry 0.4.2\nOriginal medieval defenders, orc warriors, warg mounts, siege ogres, giant warthog riders, fire shamans, four giant siege bosses, sculpted armor, surface textures, fortress geometry and synthesized audio created for this game.\nDefeat voices: original synthesized human oofs, orc exhalations and ogre grunts. No external voice recordings.\nMusic: The Valley Watch — original composition and synthesized lute, recorder, dulcimer and hand percussion. No third-party music or samples.\n100 automatic waves. 10–15 second assaults, 3–5 second reinforcement gaps.\n\nGodot Engine\n"+Engine.get_license_text()+"\n\nThird-party engine notices\n"+str(Engine.get_license_info())
	text.wrap_mode=TextEdit.LINE_WRAPPING_BOUNDARY;col.add_child(text);col.add_child(button("Close",close_credits));refresh()
func close_credits():
	if not is_instance_valid(overlay):return
	game.audio.stop_voice_previews()
	game.audio.save_preferences()
	overlay.queue_free();overlay=null
	if is_instance_valid(backdrop):backdrop.queue_free();backdrop=null
	overlay_kind="";music_slider=null;effects_slider=null;audio_status=null;speed_choices.clear()
	game.camera.set_interaction_enabled(true);game.set_paused(was_paused)
