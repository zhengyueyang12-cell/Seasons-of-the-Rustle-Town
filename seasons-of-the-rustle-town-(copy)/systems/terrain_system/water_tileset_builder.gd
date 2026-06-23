@tool
class_name WaterTilesetBuilder
extends RefCounted

## 生成单色 16×16 水体占位 TileSet，实际外观由 water_surface.gdshader 驱动。

const OUTPUT_PATH := "res://resources/tilesets/water_surface.tres"
const TILE_SIZE := 16


static func build_tileset() -> TileSet:
	var tile_set := TileSet.new()
	var source := TileSetAtlasSource.new()
	source.texture = _make_fill_texture()
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	source.create_tile(Vector2i.ZERO)
	tile_set.add_source(source, 0)
	return tile_set


static func save_tileset() -> void:
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path("res://resources/tilesets")
	)
	var err := ResourceSaver.save(build_tileset(), OUTPUT_PATH)
	if err != OK:
		push_error("WaterTilesetBuilder: 保存失败 (%s) %s" % [err, OUTPUT_PATH])
		return
	print("WaterTilesetBuilder: 已保存 → ", OUTPUT_PATH)


static func _make_fill_texture() -> Texture2D:
	var image := Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color(1.0, 1.0, 1.0, 1.0))
	return ImageTexture.create_from_image(image)
