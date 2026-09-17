class_name EconomyManager
extends RefCounted
var balance: Dictionary
var gold: int
func _init(data: Dictionary):
	balance = data
	gold = int(data.starting_gold)
func spend(amount: int) -> bool:
	if amount < 0 or amount > gold: return false
	gold -= amount
	return true
func reward(wave: int, lost_value: int, clean: bool) -> Dictionary:
	var base := int(balance.reward_base + balance.reward_linear * wave)
	var bonus := int(base * float(balance.clean_bonus)) if clean else 0
	var relief := mini(int(lost_value * float(balance.relief_fraction)), int(balance.relief_cap_base + balance.relief_cap_wave * wave))
	gold += base + bonus + relief
	return {"base":base,"bonus":bonus,"relief":relief,"total":base+bonus+relief}
