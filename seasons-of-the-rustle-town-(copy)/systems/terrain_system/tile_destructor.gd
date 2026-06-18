class_name TileDestructor
extends Node

## 瓦片动态破坏与地形自动融合系统。
## 挂载到 World 或 GameManager 下，init_system() 后调用 destroy_tile_at_position()。

signal tiles_destroyed(cells_changed: Array[Vector2i], center_cell: Vector2i)

enum DestroyMode {
	REPLACE_TERRAIN, ## 将可破坏层替换为目标地形（如草地 → 泥土）
	ERASE_CELL,      ## 直接擦除瓦片，露出更底层图层
}

enum RangeShape {
	CIRCLE,
	SQUARE,
}

## 四方向 + 四对角，用于外圈邻居检测与 Terrain 融合刷新
const NEIGHBOR_OFFSETS_8: Array[Vector2i] = [
	Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1),
	Vector2i(-1, -1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(1, 1),
]

const CARDINAL_OFFSETS: Array[Vector2i] = [
	Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1),
]

## 在 Inspector 中配置后，_ready() 会自动调用 init_system()
@export var ground_layer_path: NodePath = NodePath("../TileMapLayerGround")
@export var terrain_set_id: int = 0
@export var target_terrain_id: int = 1
@export var source_terrain_id: int = 0
@export var auto_initialize: bool = true

var _layer: TileMapLayer
var _terrain_set_id: int = 0
var _target_terrain_id: int = 0
var _source_terrain_id: int = -1

var _destroy_mode: DestroyMode = DestroyMode.REPLACE_TERRAIN
var _range_shape: RangeShape = RangeShape.CIRCLE


func _ready() -> void:
	add_to_group(&"tile_destructor")
	if not auto_initialize:
		return
	var layer: TileMapLayer = get_node_or_null(ground_layer_path) as TileMapLayer
	if layer == null:
		push_warning("TileDestructor: 找不到 ground_layer_path，请在 Inspector 中配置")
		return
	init_system(layer, terrain_set_id, target_terrain_id, source_terrain_id)


## 初始化破坏系统。
## [param target_layer]  要操作的 TileMapLayer（草地/可破坏层）
## [param terrain_set_id] TileSet 中 Terrain Set 的索引
## [param terrain_id]     破坏后替换成的目标地形 ID（如泥土）
## [param source_terrain_id] 可被破坏的源地形 ID（如草地）；-1 表示任意非空瓦片
func init_system(
	target_layer: TileMapLayer,
	terrain_set_id: int,
	terrain_id: int,
	source_terrain_id: int = -1
) -> void:
	_layer = target_layer
	_terrain_set_id = terrain_set_id
	_target_terrain_id = terrain_id
	_source_terrain_id = source_terrain_id


func set_destroy_mode(mode: DestroyMode) -> void:
	_destroy_mode = mode


func set_range_shape(shape: RangeShape) -> void:
	_range_shape = shape


## 核心接口：在全局坐标 [param global_pos] 处以 [param radius] 为半径破坏瓦片。
## 返回实际被破坏的格子数量。
func destroy_tile_at_position(global_pos: Vector2, radius: float) -> int:
	if _layer == null:
		push_warning("TileDestructor: 未初始化，请先调用 init_system()")
		return 0
	if radius < 0.0:
		return 0

	var local_pos: Vector2 = _layer.to_local(global_pos)
	var center_cell: Vector2i = _layer.local_to_map(local_pos)

	return destroy_tiles_at_cell(center_cell, radius)


## 当调用方已持有网格坐标时，可直接调用此重载。
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

	# 外圈邻居：与破坏区相邻、但自身不在破坏区内的格子
	# 这些格子是 Terrain Autotile 重绘的关键——坑洞边缘的草地必须重新计算贴图
	var cells_to_update: Array[Vector2i] = _collect_outer_ring_neighbors(
		cells_to_change,
		changed_lookup
	)

	_apply_destruction(cells_to_change, cells_to_update)
	tiles_destroyed.emit(cells_to_change, center_cell)
	return cells_to_change.size()


## 全局坐标 → 瓦片网格坐标（供外部工具/调试使用）
func global_to_map(global_pos: Vector2) -> Vector2i:
	if _layer == null:
		return Vector2i.ZERO
	return _layer.local_to_map(_layer.to_local(global_pos))


## 网格坐标 → 瓦片中心点的全局坐标
func map_to_global(cell: Vector2i) -> Vector2:
	if _layer == null:
		return Vector2.ZERO
	return _layer.to_global(_layer.map_to_local(cell))


## 查询格子的地形 ID；-1 表示无瓦片或无效。
func get_cell_terrain(cell: Vector2i) -> int:
	return _get_cell_terrain(cell)


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
	# 第一步：将破坏区内瓦片统一设为目标地形（泥土），引擎自动挑选坑内融合贴图
	_layer.set_cells_terrain_connect(
		ready_cells,
		_terrain_set_id,
		_target_terrain_id,
		true
	)


## 锄地后重算边缘：泥土块融合 + 周围草地显示悬垂草叶（y=1 行）
## 锄地后重算边缘：与编辑器逻辑一致，只需让泥土图块去主动连接周围
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

	# 核心改动：我们只收集当前已经是泥土的地形格子（包括新锄的，和外圈原本就是泥土的）
	var dirt_cells: Array[Vector2i] = []
	for cell: Vector2i in safe_cells:
		if _get_cell_terrain(cell) == _target_terrain_id:
			dirt_cells.append(cell)

	# 借助你写好的扩展函数，把原本就相邻的旧耕地格子一并纳进来计算，防止旧耕地边缘不刷新
	if not dirt_cells.is_empty():
		dirt_cells = _expand_dirt_blend_cells(dirt_cells)
		
		# 唯独只对泥土调用一次连接，这样引擎就会自动算好泥土与草地的交界
		_layer.set_cells_terrain_connect(
			dirt_cells,
			_terrain_set_id,
			_target_terrain_id,
			true
		)



## 与编辑器「刷新全部地形融合」一致：相邻耕地格一并重算 autotile。
func _expand_dirt_blend_cells(dirt_cells: Array[Vector2i]) -> Array[Vector2i]:
	var lookup: Dictionary = {}
	for cell: Vector2i in dirt_cells:
		lookup[cell] = true

	var expanded: Array[Vector2i] = dirt_cells.duplicate()
	for cell: Vector2i in dirt_cells:
		for offset: Vector2i in CARDINAL_OFFSETS:
			var neighbor: Vector2i = cell + offset
			if lookup.has(neighbor):
				continue
			if _get_cell_terrain(neighbor) != _target_terrain_id:
				continue
			lookup[neighbor] = true
			expanded.append(neighbor)
	return expanded


## 旧 TileSet 换图后，格子可能仍存着无效 atlas 坐标（如 7:8），Terrain 刷新会崩溃。
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

	if _source_terrain_id >= 0:
		_layer.set_cells_terrain_connect(
			stale,
			_terrain_set_id,
			_source_terrain_id,
			false
		)
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
			var cell: Vector2i = center + Vector2i(dx, dy)
			result.append(cell)

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
	# 换 TileSet 后 atlas 坐标失效，仍视为可锄草地
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


## 收集破坏区外围一圈邻居。
## 遍历每个被破坏格子，检查 8 邻域；若邻居不在破坏区内且仍有瓦片，则纳入刷新列表。
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
