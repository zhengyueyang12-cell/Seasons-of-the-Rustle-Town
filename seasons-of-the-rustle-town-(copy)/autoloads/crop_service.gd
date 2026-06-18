extends Node

## 耕地种植、生长与收获。

const CROP_SCENE: PackedScene = preload("res://Scenes/crops/crop.tscn")
const TILE_MATCH_RADIUS: float = 18.0

var _crops_by_cell: Dictionary = {}


func _ready() -> void:
	TimeManager.day_advanced.connect(_on_day_advanced)


func try_plant_at(global_pos: Vector2, seed: SeedResource, slot_index: int) -> bool:
	if seed == null or seed.crop_id == &"":
		return false
	if slot_index < 0:
		return false

	var slot: ItemSlotData = HotbarManager.get_slot(slot_index)
	if slot == null or slot.is_empty or slot.item != seed:
		return false

	var crop_data: CropResource = CropRegistry.get_crop(seed.crop_id)
	if crop_data == null:
		return false
	if not _is_valid_planting_season(crop_data):
		return false

	var tile_destructor: TileDestructor = _get_tile_destructor()
	var crops_parent: Node2D = _get_crops_parent()
	if tile_destructor == null or crops_parent == null:
		return false

	var cell: Vector2i = tile_destructor.global_to_map(global_pos)
	if not _is_tilled_cell(cell, tile_destructor):
		return false
	if _has_crop_at_cell(cell):
		return false
	if _is_cell_blocked(cell, tile_destructor):
		return false
	if not HotbarManager.remove_from_slot(slot_index, 1):
		return false

	_spawn_crop(crops_parent, cell, tile_destructor, seed.crop_id)
	return true


func try_harvest_at(global_pos: Vector2) -> bool:
	var tile_destructor: TileDestructor = _get_tile_destructor()
	if tile_destructor == null:
		return false

	var cell: Vector2i = tile_destructor.global_to_map(global_pos)
	var crop: CropEntity = _crops_by_cell.get(cell) as CropEntity
	if crop == null or not crop.is_mature():
		return false

	var data: CropResource = crop.get_crop_data()
	if data == null or data.harvest_item_id == &"":
		return false

	var harvest_item: ItemResource = ItemRegistry.get_item(data.harvest_item_id)
	if harvest_item == null:
		return false

	var leftover: int = InventoryManager.add_item(harvest_item, data.harvest_amount)
	if leftover > 0:
		return false

	_remove_crop(crop)
	return true


func has_crop_at(global_pos: Vector2) -> bool:
	var tile_destructor: TileDestructor = _get_tile_destructor()
	if tile_destructor == null:
		return false
	return _has_crop_at_cell(tile_destructor.global_to_map(global_pos))


func is_tilled_at(global_pos: Vector2) -> bool:
	var tile_destructor: TileDestructor = _get_tile_destructor()
	if tile_destructor == null:
		return false
	return _is_tilled_cell(tile_destructor.global_to_map(global_pos), tile_destructor)


func _on_day_advanced(_day: int, _season: TimeManager.Season, _year: int) -> void:
	for crop: Variant in _crops_by_cell.values():
		if crop is CropEntity:
			(crop as CropEntity).advance_stage()


func _spawn_crop(
	parent: Node2D,
	cell: Vector2i,
	tile_destructor: TileDestructor,
	crop_id: StringName
) -> void:
	if CROP_SCENE == null:
		return

	var crop: CropEntity = CROP_SCENE.instantiate() as CropEntity
	if crop == null:
		return

	parent.add_child(crop)
	crop.global_position = tile_destructor.map_to_global(cell)
	crop.setup(crop_id, cell, 0)
	_crops_by_cell[cell] = crop
	crop.harvested.connect(_on_crop_harvested)


func _remove_crop(crop: CropEntity) -> void:
	if crop == null:
		return
	_crops_by_cell.erase(crop.cell)
	crop.queue_free()


func _on_crop_harvested(_crop_id: StringName, _cell: Vector2i) -> void:
	pass


func _has_crop_at_cell(cell: Vector2i) -> bool:
	return _crops_by_cell.has(cell)


func _is_tilled_cell(cell: Vector2i, tile_destructor: TileDestructor) -> bool:
	return tile_destructor.get_cell_terrain(cell) == tile_destructor.get_runtime_target_terrain_id()


func _is_valid_planting_season(crop_data: CropResource) -> bool:
	if crop_data.valid_seasons.is_empty():
		return true
	return crop_data.valid_seasons.has(int(TimeManager.current_season))


func _is_cell_blocked(cell: Vector2i, tile_destructor: TileDestructor) -> bool:
	var world_pos: Vector2 = tile_destructor.map_to_global(cell)
	for node: Node in get_tree().get_nodes_in_group(&"tree"):
		if node is Node2D:
			if (node as Node2D).global_position.distance_to(world_pos) < TILE_MATCH_RADIUS:
				return true
	for node: Node in get_tree().get_nodes_in_group(&"tree_stump"):
		if node is Node2D:
			if (node as Node2D).global_position.distance_to(world_pos) < TILE_MATCH_RADIUS:
				return true
	return false


func _get_tile_destructor() -> TileDestructor:
	return get_tree().get_first_node_in_group(&"tile_destructor") as TileDestructor


func _get_crops_parent() -> Node2D:
	var main: Node = get_tree().current_scene
	if main == null:
		return null
	return main.get_node_or_null("World/YSort_Objects/Crops") as Node2D
