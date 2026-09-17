class_name BattleCamera
extends Camera3D
## One-finger map inspection. Only gestures started outside GUI are captured.
## Position is bounded; orientation never changes, so combat remains readable.
signal pan_changed(is_away: bool)
const LEFT_LIMIT := -1.5
const RIGHT_LIMIT := 8.5
const DEPTH_LIMIT := 1.35
const DRAG_THRESHOLD := 8.0
var home_position := Vector3(7.5,10.5,25)
var desired_pan := Vector3.ZERO
var current_pan := Vector3.ZERO
var finger := -1
var mouse_drag := false
var dragged := false
var accumulated := Vector2.ZERO
var away := false
var enabled := true
func _ready():
	# The battlefield fits this depth range; the default 0.05–4000 range wastes
	# depth precision on distant geometry and makes near-overlapping detail shimmer.
	near=.4;far=140.0
	position=home_position;look_at(Vector3(1,1.6,0));fov=35;current=true
func cancel_gesture():
	finger=-1;mouse_drag=false;dragged=false;accumulated=Vector2.ZERO
func set_interaction_enabled(value: bool):
	enabled=value
	if not enabled:cancel_gesture()
func recenter():
	desired_pan=Vector3.ZERO;cancel_gesture()
func _notification(what: int):
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT or what==NOTIFICATION_PAUSED:
		cancel_gesture()
func _unhandled_input(event: InputEvent):
	if not enabled or get_tree().paused: return
	# A touchscreen may also generate synthetic mouse events; process once.
	if event.device == -1: return
	if event is InputEventScreenTouch and event.pressed and finger<0 and not mouse_drag:
		finger=event.index;accumulated=Vector2.ZERO;dragged=false
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed and finger<0:
		mouse_drag=true;accumulated=Vector2.ZERO;dragged=false
		get_viewport().set_input_as_handled()
func _input(event: InputEvent):
	if not enabled: return
	if event.device == -1: return
	# Release is observed before GUI so releasing over a button cannot leave
	# a stuck drag. A second finger never takes over an existing gesture.
	if event is InputEventScreenTouch and event.index==finger and not event.pressed:
		cancel_gesture()
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and not event.pressed:
		mouse_drag=false;dragged=false;accumulated=Vector2.ZERO
	elif event is InputEventScreenDrag and event.index==finger:
		drag_by(event.relative);get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and mouse_drag:
		drag_by(event.relative);get_viewport().set_input_as_handled()
func drag_by(relative: Vector2):
	if not enabled: return
	if not dragged:
		accumulated+=relative
		if accumulated.length()<DRAG_THRESHOLD:return
		relative=accumulated;accumulated=Vector2.ZERO;dragged=true
	var middle:Vector2=get_viewport().get_visible_rect().size*.5
	var ground:=Plane(Vector3.UP,0)
	var start:Variant=ground.intersects_ray(project_ray_origin(middle),project_ray_normal(middle))
	var end:Variant=ground.intersects_ray(project_ray_origin(middle+relative),project_ray_normal(middle+relative))
	if start is Vector3 and end is Vector3:
		set_pan(desired_pan+start-end)
func set_pan(value: Vector3):
	desired_pan=Vector3(clampf(value.x,LEFT_LIMIT,RIGHT_LIMIT),0,clampf(value.z,-DEPTH_LIMIT,DEPTH_LIMIT))
func _process(delta: float):
	# Scouting follows the finger at the same rate at every battle speed.
	delta/=Engine.time_scale
	current_pan=current_pan.lerp(desired_pan,1.0-exp(-18.0*delta))
	if current_pan.distance_to(desired_pan)<.001:current_pan=desired_pan
	position=home_position+current_pan
	var next_away:bool=current_pan.length()>.16 or desired_pan.length()>.16
	if next_away!=away:away=next_away;pan_changed.emit(away)
