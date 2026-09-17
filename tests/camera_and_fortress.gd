extends SceneTree
var failures:=0
func check(ok: bool,label: String):
	if ok: print("PASS: "+label)
	else:failures+=1;push_error("FAIL: "+label)
func _initialize():call_deferred("run")
func touch(at: Vector2,down: bool,index: int=3):
	var event:=InputEventScreenTouch.new();event.index=index;event.position=at;event.pressed=down
	root.push_input(event,true)
func drag(at: Vector2,relative: Vector2,index: int=3):
	var event:=InputEventScreenDrag.new();event.index=index;event.position=at;event.relative=relative
	root.push_input(event,true)
func find_button(node: Node,label: String) -> Button:
	if node is Button and node.text==label:return node
	for child in node.get_children():
		var b:=find_button(child,label)
		if b:return b
	return null
func run():
	var game=load("res://scenes/battle/battle.tscn").instantiate();root.add_child(game)
	await process_frame;await process_frame
	var cam:BattleCamera=game.camera
	var middle:=root.get_visible_rect().size*.5
	touch(middle,true)
	check(cam.finger==3,"battlefield touch starts map inspection through normal viewport input")
	drag(middle-Vector2(2,0),Vector2(-2,0))
	check(cam.desired_pan==Vector3.ZERO,"tap jitter does not shift map")
	drag(middle-Vector2(130,0),Vector2(-128,0))
	check(cam.desired_pan.x>0,"swiping left scouts toward incoming army")
	var held:=cam.desired_pan
	drag(middle,Vector2(250,0),4)
	check(cam.desired_pan==held,"second finger cannot hijack a drag")
	touch(Vector2(20,20),false)
	check(cam.finger==-1,"releasing over HUD ends drag")
	cam.set_pan(Vector3(999,0,999));cam._process(1)
	check(cam.current_pan.x<=8.5001 and cam.current_pan.z<=1.3501,"scouting stays inside map bounds")
	check(cam.unproject_position(WaveDirector.formation(0)).x>root.get_visible_rect().size.x,"enemy spawn remains outside furthest scout view")
	game.hud.recenter_button.pressed.emit();cam._process(1)
	check(cam.current_pan.length()<.01,"Castle button returns camera home")
	var sound:=find_button(game.hud,"Settings");var point:=sound.get_global_rect().get_center()
	touch(point,true);drag(point-Vector2(150,0),Vector2(-150,0));touch(point,false)
	check(cam.desired_pan.length()<.01 and cam.finger==-1,"drag begun on UI cannot move battlefield")
	game.hud.show_credits();touch(middle,true);drag(middle,Vector2(-150,0));touch(middle,false)
	check(cam.desired_pan.length()<.01 and not cam.enabled,"credits modal blocks camera input")
	game.hud.show_credits();await process_frame
	check(cam.enabled,"closing credits restores map interaction")
	root.size=Vector2i(1600,720);await process_frame
	cam.set_pan(Vector3(8.5,0,1.35));cam._process(1)
	check(cam.unproject_position(WaveDirector.formation(0)).x>root.get_visible_rect().size.x,"spawn stays offscreen on wide landscape viewport")
	var gate:CastleStructure=game.castle.structures.gate
	check(gate.pieces.size()>=40,"timber gate and iron portcullis are destructible pieces")
	gate.restore(gate.max_hp)
	var rest:Transform3D=gate.pieces[0].transform
	gate.take_damage(gate.max_hp)
	await create_timer(.8).timeout
	check(gate.pieces[0].position.y<.4,"gate debris falls clear of archway")
	gate.restore(770)
	await create_timer(.1).timeout
	check(gate.pieces[0].transform.is_equal_approx(rest),"repair restores exact gate geometry without lingering collapse tween")
	print("CAMERA AND FORTRESS COMPLETE failures=",failures)
	game.audio.stop_all()
	await create_timer(.30).timeout
	game.queue_free();await process_frame;quit(failures)
