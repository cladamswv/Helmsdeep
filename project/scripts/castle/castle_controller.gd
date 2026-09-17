class_name CastleController
extends Node3D
var structures: Dictionary = {}
var game: Node3D
func build(owner_game: Node3D):
	game = owner_game
	for id in ["gate","keep","north","center","south","tower"]:
		var s := CastleStructure.new(); s.name = id; s.id = id; s.game = game
		s.max_hp = float(game.balance.get(id+"_hp",game.balance.wall_hp)); s.hp=s.max_hp
		structures[id]=s; add_child(s)
	structures.gate.position=Vector3(-4,0,0)
	structures.keep.position=Vector3(-9,0,0)
	structures.north.position=Vector3(-4,0,-3.3)
	structures.center.position=Vector3(-4,0,0)
	structures.south.position=Vector3(-4,0,3.3)
	structures.tower.position=Vector3(-8,0,-4)
func snapshot() -> Dictionary:
	var d := {}
	for id in structures: d[id]=structures[id].hp
	return d
func restore(d: Dictionary):
	for id in structures: structures[id].restore(float(d.get(id,structures[id].max_hp)))
func repair_gate() -> int:
	return repair_structure("gate")
func repair_structure(id: String) -> int:
	if not id in ["gate","keep"]:return 0
	var s: CastleStructure = structures[id]
	var remaining := maxf(0,s.max_hp * float(game.balance.repair_fraction)-s.repair_used)
	var heal := minf(remaining,s.max_hp-s.hp)
	heal = minf(heal,game.economy.gold * float(game.balance.repair_hp_per_gold))
	if heal <= 0: return 0
	var cost := int(ceil(heal/float(game.balance.repair_hp_per_gold)))
	if game.economy.spend(cost):
		s.hp += heal; s.repair_used += heal; s.update_visuals()
		return cost
	return 0
