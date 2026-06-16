extends Node2D

signal game_paused()
signal game_resumed()

var is_paused: bool = false


func _ready() -> void:
	_connect_signals()
	call_deferred(&"_initialize_systems")


func _initialize_systems() -> void:
	UIManager.refresh_all_displays()
	_grant_starter_items()
	_equip_player_hotbar(0)


func _grant_starter_items() -> void:
	if InventoryManager.get_item_count(&"wooden_hoe") == 0:
		var hoe: ToolResource = ToolRegistry.get_tool(&"wooden_hoe")
		if hoe != null:
			InventoryManager.add_item(hoe, 1)

	if InventoryManager.get_item_count(&"rapier") == 0:
		var rapier: WeaponResource = WeaponRegistry.get_weapon(&"rapier")
		if rapier != null:
			InventoryManager.add_item(rapier, 1)

	if InventoryManager.get_item_count(&"wooden_axe") == 0:
		var axe: ToolResource = ToolRegistry.get_tool(&"wooden_axe")
		if axe != null:
			InventoryManager.add_item(axe, 1)


func _equip_player_hotbar(slot_index: int) -> void:
	var player: Node = get_node_or_null("World/YSort_Objects/Player")
	if player == null:
		return
	var equipment: EquipmentController = player.get_node_or_null("EquipmentController") as EquipmentController
	if equipment != null:
		equipment.equip_from_hotbar(slot_index)


func _connect_signals() -> void:
	TimeManager.tick.connect(_on_time_tick)
	TimeManager.season_changed.connect(_on_season_changed)
	GameState.gold_changed.connect(_on_gold_changed)
	GameState.energy_changed.connect(_on_energy_changed)


func pause_game() -> void:
	if is_paused:
		return

	is_paused = true
	get_tree().paused = true
	TimeManager.pause()
	game_paused.emit()


func resume_game() -> void:
	if not is_paused:
		return

	is_paused = false
	get_tree().paused = false
	TimeManager.resume()
	game_resumed.emit()


func toggle_pause() -> void:
	if is_paused:
		resume_game()
	else:
		pause_game()


func _on_time_tick(
	_minute: int, _hour: int, _day: int, _season: TimeManager.Season, _year: int
) -> void:
	UIManager.refresh_time_display()


func _on_season_changed(_new_season: TimeManager.Season) -> void:
	UIManager.refresh_time_display()


func _on_gold_changed(_new_amount: int) -> void:
	UIManager.refresh_money_display()


func _on_energy_changed(_current: int, _maximum: int) -> void:
	UIManager.refresh_energy_display()
