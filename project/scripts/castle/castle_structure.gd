class_name CastleStructure
extends Node3D
signal changed(structure)
signal breached(structure)
var id: String
var hp: float
var max_hp: float
var repair_used := 0.0
var pieces: Array[Node3D] = []
var rubble: Array[Node3D] = []
var cracks: Array[Node3D] = []
var game: Node3D
var debris_tweens: Array[Tween] = []
func take_damage(amount: float):
	if hp <= 0: return
	hp = maxf(0,hp-amount); update_visuals(); changed.emit(self)
	game.vfx.burst(global_position+Vector3.UP, hp<=0)
	game.audio.cue("collapse" if hp <= 0 else "gate")
	if hp <= 0: breached.emit(self)
func restore(value: float):
	hp = clampf(value,0,max_hp); repair_used = 0; update_visuals()
func update_visuals():
	for tween in debris_tweens:
		if tween.is_valid():tween.kill()
	debris_tweens.clear()
	var stage := 4 - int(ceil(hp/max_hp*4))
	for i in cracks.size(): cracks[i].visible = stage > i
	for i in pieces.size():
		var piece := pieces[i]
		if not piece.has_meta("rest"): piece.set_meta("rest",piece.transform)
		if hp <= 0:
			var tween := create_tween().set_parallel(true)
			debris_tweens.append(tween)
			tween.tween_property(piece,"position",Vector3((i%3-1)*.5,.15,float(i%4)*.35-.5),.6)
			tween.tween_property(piece,"rotation",Vector3(1.4, i*.6,.3),.6)
		else:
			piece.transform = piece.get_meta("rest")
	for piece in rubble: piece.visible = hp <= 0
