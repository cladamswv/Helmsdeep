class_name TargetingSystem
extends RefCounted
## Ground crowd buckets refreshed at 10 Hz; each mover visits nine local cells.
var cells: Dictionary = {}
var incoming: Dictionary = {}
const CELL_SIZE := 1.8
func rebuild(units: Array[UnitController], projectiles: ProjectilePool=null):
	cells.clear();incoming.clear()
	for unit in units:
		if unit.data.ranged and unit.windup>=0 and is_instance_valid(unit.target) and unit.target.hp>0:reserve(unit.target,unit.damage_against(unit.target),unit.data.projectile_kind!="fireball")
	if projectiles:
		for shot in projectiles.slots:
			if not shot.active:continue
			var target=shot.target.get_ref()
			if is_instance_valid(target) and target.hp>0:reserve(target,shot.damage)
		for shot in projectiles.fireballs.slots:
			if not shot.active:continue
			var target=shot.target.get_ref()
			if is_instance_valid(target) and target.hp>0:reserve(target,shot.damage,false)

	for unit in units:
		if unit.hp<=0 or (unit.data.ranged and not unit.enemy):continue
		var key:=Vector2i(floori(unit.position.x/CELL_SIZE),floori(unit.position.z/CELL_SIZE))
		if not cells.has(key):cells[key]=[]
		cells[key].append(unit)
func separation(unit: UnitController) -> Vector3:
	var result:=Vector3.ZERO
	var cell:=Vector2i(floori(unit.position.x/CELL_SIZE),floori(unit.position.z/CELL_SIZE))
	for x in range(-1,2):
		for z in range(-1,2):
			var key:=cell+Vector2i(x,z)
			if not cells.has(key):continue
			for friend in cells[key]:
				if not is_instance_valid(friend) or friend==unit or friend.hp<=0:continue
				var diff:Vector3=unit.position-friend.position;diff.y=0
				var distance:=diff.length()
				var spacing:float=unit.data.spacing*.5+friend.data.spacing*.5
				if distance>.005 and distance<spacing:result+=diff/distance*(spacing-distance)*2.5
	return result

func reserve(target: Node3D, damage: float, arrow: bool=true):
	if target is UnitController:damage*=(1.0-target.data.armor)*(1.0-target.data.ranged_resistance if arrow else 1.0)
	var id:=target.get_instance_id()
	incoming[id]=float(incoming.get(id,0))+damage
func saturated(target: UnitController) -> bool:
	return float(incoming.get(target.get_instance_id(),0))>=target.hp
