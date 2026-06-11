extends Node

signal time_display_updated(time_string: String)
signal money_display_updated(amount: int)
signal energy_display_updated(current: int, maximum: int)
signal inventory_visibility_changed(visible: bool)

var is_inventory_visible: bool = false


func _ready() -> void:
	set_inventory_visible(false)


func refresh_all_displays() -> void:
	refresh_time_display()
	refresh_money_display()
	refresh_energy_display()


func refresh_time_display() -> void:
	time_display_updated.emit(TimeManager.get_full_datetime_string())


func refresh_money_display() -> void:
	money_display_updated.emit(GameState.gold)


func refresh_energy_display() -> void:
	energy_display_updated.emit(GameState.energy, GameState.max_energy)


func toggle_inventory() -> void:
	set_inventory_visible(not is_inventory_visible)


func set_inventory_visible(visible: bool) -> void:
	is_inventory_visible = visible
	inventory_visibility_changed.emit(visible)
