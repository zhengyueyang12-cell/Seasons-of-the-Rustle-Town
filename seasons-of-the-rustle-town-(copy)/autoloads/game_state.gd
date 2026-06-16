extends Node

signal gold_changed(new_amount: int)
signal energy_changed(current: int, maximum: int)
signal equipped_weapon_changed(weapon_id: StringName)
signal equipped_tool_changed(tool_id: StringName)

const INITIAL_GOLD: int = 500
const INITIAL_MAX_ENERGY: int = 270

var gold: int = INITIAL_GOLD
var energy: int = INITIAL_MAX_ENERGY
var max_energy: int = INITIAL_MAX_ENERGY
var current_weapon_id: StringName = &""
var current_tool_id: StringName = &""
## 觅食技能等级，影响木材等掉落数量
var foraging_level: int = 0
## 运气加成 0.0~1.0
var luck: float = 0.0


func get_foraging_drop_bonus() -> int:
	return foraging_level + int(luck * 2.0)


func roll_luck_bonus() -> bool:
	return randf() < luck * 0.35


func add_gold(amount: int) -> void:
	if amount == 0:
		return
	gold += amount
	gold_changed.emit(gold)


func spend_gold(amount: int) -> bool:
	if amount <= 0:
		return true
	if gold < amount:
		return false
	gold -= amount
	gold_changed.emit(gold)
	return true


func use_energy(amount: int) -> bool:
	if amount <= 0:
		return true
	if energy < amount:
		return false
	energy -= amount
	energy_changed.emit(energy, max_energy)
	return true


func restore_energy(amount: int) -> void:
	if amount <= 0:
		return
	energy = mini(energy + amount, max_energy)
	energy_changed.emit(energy, max_energy)


func set_max_energy(value: int) -> void:
	max_energy = maxi(value, 1)
	energy = mini(energy, max_energy)
	energy_changed.emit(energy, max_energy)


func set_equipped_weapon(weapon_id: StringName) -> void:
	if current_weapon_id == weapon_id:
		return
	current_weapon_id = weapon_id
	equipped_weapon_changed.emit(weapon_id)


func set_equipped_tool(tool_id: StringName) -> void:
	if current_tool_id == tool_id:
		return
	current_tool_id = tool_id
	equipped_tool_changed.emit(tool_id)
