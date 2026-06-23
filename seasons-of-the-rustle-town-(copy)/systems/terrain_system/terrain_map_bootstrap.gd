@tool
class_name TerrainMapBootstrap
extends TileMapLayer

## 三层地形：草(0) ↔ 土(1) ↔ 耕地(2)
##
## 编辑器：
## 1. Terrain 画笔选 meadow 铺草
## 2. Terrain 画笔选 soil 画土路
## 3. 运行后锄地仅把土变成耕地

@export var auto_bootstrap: bool = false
@export var remigrate_stale_atlas_on_ready: bool = false
@export var terrain_set_id: int = 0
@export var meadow_terrain_id: int = 0
@export var soil_terrain_id: int = 1
@export var tilled_terrain_id: int = 2
@export var fill_empty_farm_rect: bool = false
@export var farm_rect: Rect2i = Rect2i(-18, -12, 36, 24)

@export_tool_button("重置为草地基底", "Refresh")
var _reset_meadow_btn = _editor_reset_meadow_base

@export_tool_button("刷新全部地形融合", "Reload")
var _refresh_all_btn = _editor_refresh_all_terrain


func _editor_reset_meadow_base() -> void:
	_bootstrap_meadow(true)


func _editor_refresh_all_terrain() -> void:
	_refresh_all_terrain_connect()


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if remigrate_stale_atlas_on_ready:
		_repair_stale_atlas_cells()
	if auto_bootstrap:
		call_deferred("_bootstrap_meadow", false)


func _repair_stale_atlas_cells() -> void:
	var stale: Array[Vector2i] = []
	for cell: Vector2i in get_used_cells():
		if FarmTilemapUtils.is_stale_cell(self, cell):
			stale.append(cell)
	if stale.is_empty():
		return
	for cell: Vector2i in stale:
		erase_cell(cell)
	set_cells_terrain_connect(stale, terrain_set_id, meadow_terrain_id, false)
	call_deferred("_refresh_all_terrain_connect")


func _bootstrap_meadow(full_remap: bool) -> void:
	if tile_set == null:
		push_warning("TerrainMapBootstrap: 未设置 tile_set")
		return

	var cells: Array[Vector2i] = []
	var seen: Dictionary = {}

	for cell: Vector2i in get_used_cells():
		cells.append(cell)
		seen[cell] = true

	if fill_empty_farm_rect:
		for y: int in range(farm_rect.position.y, farm_rect.position.y + farm_rect.size.y):
			for x: int in range(farm_rect.position.x, farm_rect.position.x + farm_rect.size.x):
				var cell := Vector2i(x, y)
				if not seen.has(cell):
					cells.append(cell)
					seen[cell] = true

	if cells.is_empty():
		return

	if full_remap:
		for cell: Vector2i in cells:
			erase_cell(cell)
		set_cells_terrain_connect(cells, terrain_set_id, meadow_terrain_id, false)
	else:
		var meadow_only: Array[Vector2i] = []
		for cell: Vector2i in cells:
			if FarmTilemapUtils.is_stale_cell(self, cell):
				erase_cell(cell)
				meadow_only.append(cell)
				continue
			var terrain: int = _get_cell_terrain(cell)
			if terrain < 0 or terrain == meadow_terrain_id:
				meadow_only.append(cell)
		if meadow_only.is_empty():
			return
		set_cells_terrain_connect(meadow_only, terrain_set_id, meadow_terrain_id, false)

	call_deferred("_refresh_all_terrain_connect")


func _refresh_all_terrain_connect() -> void:
	var meadow_cells: Array[Vector2i] = []
	var soil_cells: Array[Vector2i] = []
	var tilled_cells: Array[Vector2i] = []

	for cell: Vector2i in get_used_cells():
		if FarmTilemapUtils.is_stale_cell(self, cell):
			continue
		var terrain: int = _get_cell_terrain(cell)
		match terrain:
			meadow_terrain_id:
				meadow_cells.append(cell)
			soil_terrain_id:
				soil_cells.append(cell)
			tilled_terrain_id:
				tilled_cells.append(cell)

	if not meadow_cells.is_empty():
		set_cells_terrain_connect(meadow_cells, terrain_set_id, meadow_terrain_id, true)
	if not soil_cells.is_empty():
		set_cells_terrain_connect(soil_cells, terrain_set_id, soil_terrain_id, true)
	if not tilled_cells.is_empty():
		set_cells_terrain_connect(tilled_cells, terrain_set_id, tilled_terrain_id, true)


func _get_cell_terrain(cell: Vector2i) -> int:
	var tile_data: TileData = FarmTilemapUtils.get_safe_tile_data(self, cell)
	if tile_data == null:
		return -1
	if tile_data.get_terrain_set() != terrain_set_id:
		return -1
	return tile_data.get_terrain()
