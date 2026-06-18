class_name FarmTilemapUtils
extends RefCounted

## 换 TileSet 后，旧格子可能仍保存无效 atlas 坐标。
## 此时调用 get_cell_tile_data() 会触发引擎错误，应先用本工具检测。


static func is_stale_cell(layer: TileMapLayer, cell: Vector2i) -> bool:
	if layer == null:
		return false

	var source_id: int = layer.get_cell_source_id(cell)
	if source_id == -1:
		return false

	var tile_set: TileSet = layer.tile_set
	if tile_set == null:
		return true

	var source: TileSetSource = tile_set.get_source(source_id)
	if source == null:
		return true
	if source is TileSetAtlasSource:
		var atlas: Vector2i = layer.get_cell_atlas_coords(cell)
		return not (source as TileSetAtlasSource).has_tile(atlas)
	return false


static func get_safe_tile_data(layer: TileMapLayer, cell: Vector2i) -> TileData:
	if is_stale_cell(layer, cell):
		return null
	return layer.get_cell_tile_data(cell)
