class_name TileDestructor
extends Node

## 瓦片动态破坏与地形自动融合系统。
## 默认：锄土(1) → 耕地(2)。草地(0) 不能直接锄成耕地。

signal tiles_destroyed(cells_changed: Array[Vector2i], center_cell: Vector2i)

enum DestroyMode {
	REPLACE_TERRAIN,
	ERASE_CELL,
}

enum RangeShape {
	CIRCLE,
	SQUARE,
}

const NEIGHBOR_OFFSETS_8: Array[Vector2i] = [
	Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1),
	Vector2i(-1, -1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(1, 1),
]

const CARDINAL_OFFSETS: Array[Vector2i] = [
	Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1),
]

@export var ground_layer_path: NodePath = NodePath("../TileMapLayerGround")
@export var terrain_set_id: int = 0
@export var meadow_terrain_id: int = 0
@export var source_terrain_id: int = 1
@export var target_terrain_id: int = 2
@export var auto_initialize: bool = true

var _layer: TileMapLayer
var _terrain_set_id: int = 0
var _meadow_terrain_id: int = 0
var _target_terrain_id: int = 0
var _source_terrain_id: int = -1


func _ready() -> void:
	add_to_group(&"tile_destructor")
	if not auto_initialize:
		return
	var layer: TileMapLayer = get_node_or_null(ground_layer_path) as TileMapLayer
	if layer == null:
		push_warning("TileDestructor: 找不到 ground_layer_path，请在 Inspector 中配置")
		return
	init_system(layer, terrain_set_id, target_terrain_id, source_terrain_id, meadow_terrain_id)


func init_system(
	target_layer: TileMapLayer,
	terrain_set_id: int,
	terrain_id: int,
	source_terrain_id: int = -1,
	meadow_id: int = 0
) -> void:
	_layer = target_layer
	_terrain_set_id = terrain_set_id
	_target_terrain_id = terrain_id
	_source_terrain_id = source_terrain_id
	_meadow_terrain_id = meadow_id


func set_destroy_mode(mode: DestroyMode) -> void:
	_destroy_mode = mode


func set_range_shape(shape: RangeShape) -> void:
	_range_shape = shape


var _destroy_mode: DestroyMode = DestroyMode.REPLACE_TERRAIN
var _range_shape: RangeShape = RangeShape.CIRCLE


func destroy_tile_at_position(global_pos: Vector2, radius: float) -> int:
	if _layer == null:
		push_warning("TileDestructor: 未初始化，请先调用 init_system()")
		return 0
	if radius < 0.0:
		return 0
	var local_pos: Vector2 = _layer.to_local(global_pos)
	var center_cell: Vector2i = _layer.local_to_map(local_pos)
	return destroy_tiles_at_cell(center_cell, radius)


func destroy_tiles_at_cell(center_cell: Vector2i, radius: float) -> int:
	if _layer == null:
		push_warning("TileDestructor: 未初始化，请先调用 init_system()")
		return 0
	if radius < 0.0:
		return 0

	var cells_in_range: Array[Vector2i] = _collect_cells_in_range(center_cell, radius)
	var cells_to_change: Array[Vector2i] = _filter_destructible_cells(cells_in_range)
	if cells_to_change.is_empty():
		return 0

	var changed_lookup: Dictionary = _build_cell_lookup(cells_to_change)
	var cells_to_update: Array[Vector2i] = _collect_outer_ring_neighbors(cells_to_change, changed_lookup)

	_apply_destruction(cells_to_change, cells_to_update)
	tiles_destroyed.emit(cells_to_change, center_cell)
	return cells_to_change.size()


func global_to_map(global_pos: Vector2) -> Vector2i:
	if _layer == null:
		return Vector2i.ZERO
	return _layer.local_to_map(_layer.to_local(global_pos))


func map_to_global(cell: Vector2i) -> Vector2:
	if _layer == null:
		return Vector2.ZERO
	return _layer.to_global(_layer.map_to_local(cell))


func get_cell_terrain(cell: Vector2i) -> int:
	return _get_cell_terrain(cell)


func get_runtime_meadow_terrain_id() -> int:
	return _meadow_terrain_id


func get_runtime_source_terrain_id() -> int:
	return _source_terrain_id


func get_runtime_target_terrain_id() -> int:
	return _target_terrain_id


func _apply_destruction(
	cells_to_change: Array[Vector2i],
	cells_to_update: Array[Vector2i]
) -> void:
	match _destroy_mode:
		DestroyMode.ERASE_CELL:
			_erase_cells(cells_to_change)
			_refresh_terrain_blend(cells_to_change, cells_to_update)
		DestroyMode.REPLACE_TERRAIN:
			_replace_with_target_terrain(cells_to_change)
			_refresh_terrain_blend(cells_to_change, cells_to_update)


func _erase_cells(cells: Array[Vector2i]) -> void:
	for cell: Vector2i in cells:
		_layer.erase_cell(cell)


func _replace_with_target_terrain(cells: Array[Vector2i]) -> void:
	if cells.is_empty():
		return
	var ready_cells: Array[Vector2i] = _repair_stale_atlas_cells(cells)
	if ready_cells.is_empty():
		return
	_layer.set_cells_terrain_connect(
		ready_cells,
		_terrain_set_id,
		_target_terrain_id,
		true
	)


func _refresh_terrain_blend(
	cells_changed: Array[Vector2i],
	cells_to_update: Array[Vector2i]
) -> void:
	var refresh_lookup: Dictionary = {}
	for cell: Vector2i in cells_changed:
		refresh_lookup[cell] = true
	for cell: Vector2i in cells_to_update:
		refresh_lookup[cell] = true

	var refresh_cells: Array[Vector2i] = []
	for key: Variant in refresh_lookup.keys():
		refresh_cells.append(key as Vector2i)

	var safe_cells: Array[Vector2i] = _repair_stale_atlas_cells(refresh_cells)
	if safe_cells.is_empty():
		return

	var by_terrain: Dictionary = {}
	for cell: Vector2i in safe_cells:
		var terrain: int = _get_cell_terrain(cell)
		if terrain < 0:
			continue
		if not by_terrain.has(terrain):
			by_terrain[terrain] = [] as Array[Vector2i]
		(by_terrain[terrain] as Array[Vector2i]).append(cell)

	for terrain_id: Variant in by_terrain.keys():
		var group: Array[Vector2i] = _expand_terrain_blend_cells(
			by_terrain[terrain_id] as Array[Vector2i],
			int(terrain_id)
		)
		if group.is_empty():
			continue
		_layer.set_cells_terrain_connect(group, _terrain_set_id, int(terrain_id), true)


func _expand_terrain_blend_cells(cells: Array[Vector2i], terrain_id: int) -> Array[Vector2i]:
	var lookup: Dictionary = {}
	for cell: Vector2i in cells:
		lookup[cell] = true

	var expanded: Array[Vector2i] = cells.duplicate()
	for cell: Vector2i in cells:
		for offset: Vector2i in CARDINAL_OFFSETS:
			var neighbor: Vector2i = cell + offset
			if lookup.has(neighbor):
				continue
			if _get_cell_terrain(neighbor) != terrain_id:
				continue
			lookup[neighbor] = true
			expanded.append(neighbor)
	return expanded


func _repair_stale_atlas_cells(cells: Array[Vector2i]) -> Array[Vector2i]:
	var stale: Array[Vector2i] = []
	var result: Array[Vector2i] = []

	for cell: Vector2i in cells:
		if not _has_tile(cell):
			continue
		if FarmTilemapUtils.is_stale_cell(_layer, cell):
			stale.append(cell)
		else:
			result.append(cell)

	if stale.is_empty():
		return result

	for cell: Vector2i in stale:
		_layer.erase_cell(cell)

	_layer.set_cells_terrain_connect(stale, _terrain_set_id, _meadow_terrain_id, false)
	result.append_array(stale)
	return result


func _collect_cells_in_range(center: Vector2i, radius: float) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var extent: int = int(ceil(radius))
	var radius_sq: float = radius * radius

	for dy: int in range(-extent, extent + 1):
		for dx: int in range(-extent, extent + 1):
			if _range_shape == RangeShape.CIRCLE:
				if float(dx * dx + dy * dy) > radius_sq + 0.001:
					continue
			result.append(center + Vector2i(dx, dy))
	return result


func _filter_destructible_cells(cells: Array[Vector2i]) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for cell: Vector2i in cells:
		if _is_destructible_cell(cell):
			result.append(cell)
	return result


func _is_destructible_cell(cell: Vector2i) -> bool:
	if not _has_tile(cell):
		return false
	if _source_terrain_id < 0:
		return true
	var terrain: int = _get_cell_terrain(cell)
	if terrain == _source_terrain_id:
		return true
	if FarmTilemapUtils.is_stale_cell(_layer, cell):
		return true
	return false


func _has_tile(cell: Vector2i) -> bool:
	return _layer.get_cell_source_id(cell) != -1


func _get_cell_terrain(cell: Vector2i) -> int:
	var tile_data: TileData = FarmTilemapUtils.get_safe_tile_data(_layer, cell)
	if tile_data == null:
		return -1
	if tile_data.get_terrain_set() != _terrain_set_id:
		return -1
	return tile_data.get_terrain()


func _build_cell_lookup(cells: Array[Vector2i]) -> Dictionary:
	var lookup: Dictionary = {}
	for cell: Vector2i in cells:
		lookup[cell] = true
	return lookup


func _collect_outer_ring_neighbors(
	cells_to_change: Array[Vector2i],
	changed_lookup: Dictionary
) -> Array[Vector2i]:
	var update_lookup: Dictionary = {}
	for cell: Vector2i in cells_to_change:
		for offset: Vector2i in NEIGHBOR_OFFSETS_8:
			var neighbor: Vector2i = cell + offset
			if changed_lookup.has(neighbor):
				continue
			if not _has_tile(neighbor):
				continue
			update_lookup[neighbor] = true

	var result: Array[Vector2i] = []
	for key: Variant in update_lookup.keys():
		result.append(key as Vector2i)
	return result
