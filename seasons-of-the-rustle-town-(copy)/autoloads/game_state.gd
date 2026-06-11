extends Node

signal gold_changed(new_amount: int)
signal energy_changed(current: int, maximum: int)
signal equipped_weapon_changed(weapon_id: StringName)

const INITIAL_GOLD: int = 500
const INITIAL_MAX_ENERGY: int = 270

var gold: int = INITIAL_GOLD
var energy: int = INITIAL_MAX_ENERGY
var max_energy: int = INITIAL_MAX_ENERGY
var current_weapon_id: StringName = &""


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
