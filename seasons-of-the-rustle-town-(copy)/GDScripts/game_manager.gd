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
	call_deferred(&"_refresh_inventory_ui")


func _refresh_inventory_ui() -> void:
	var ui_layer: CanvasLayer = get_node_or_null("CanvasLayer_UI") as CanvasLayer
	if ui_layer != null and ui_layer.has_method(&"refresh_all_slots"):
		ui_layer.refresh_all_slots()


func _grant_starter_items() -> void:
	_grant_starter_hotbar()
	_grant_starter_inventory()


func _grant_starter_hotbar() -> void:
	var hoe: ToolResource = ToolRegistry.get_tool(&"wooden_hoe")
	if hoe != null and HotbarManager.get_slot(0).is_empty:
		HotbarManager.add_item_to_slot(0, hoe, 1)

	var rapier: WeaponResource = WeaponRegistry.get_weapon(&"rapier")
	if rapier != null and HotbarManager.get_slot(1).is_empty:
		HotbarManager.add_item_to_slot(1, rapier, 1)

	var axe: ToolResource = ToolRegistry.get_tool(&"wooden_axe")
	if axe != null and HotbarManager.get_slot(2).is_empty:
		HotbarManager.add_item_to_slot(2, axe, 1)


func _grant_starter_inventory() -> void:
	_grant_starter_crop_seeds()


func _grant_starter_crop_seeds() -> void:
	var starter_seeds: Array[StringName] = [
		&"parsnip_seed",
		&"cauliflower_seed",
		&"corn_seed",
		&"wheat_seed",
		&"tomato_seed",
	]
	for seed_id: StringName in starter_seeds:
		if InventoryManager.get_item_count(seed_id) > 0:
			continue
		var seed: ItemResource = ItemRegistry.get_item(seed_id)
		if seed != null:
			InventoryManager.add_item(seed, 5)


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
