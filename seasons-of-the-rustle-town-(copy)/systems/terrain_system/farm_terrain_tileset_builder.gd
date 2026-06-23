@tool
class_name FarmTerrainTilesetBuilder
extends RefCounted

## 三层地形 TileSet 构建器（草/土/耕地）。
## 完整配置含 alternative 瓦片，请优先运行：
##   python scripts/generate_farm_ground_tres.py

const OUTPUT_PATH := "res://resources/tilesets/farm_ground.tres"
const SPRING_SHEET := "res://art/world/TerrainFeatures/spring_outdoorsTileSheet..png"
const HOE_SHEET := "res://art/world/TerrainFeatures/hoeDirt..png"
const TILE_SIZE := 16

const TERRAIN_SET := 0
const MEADOW := 0
const SOIL := 1
const TILLED := 2


static func save_tileset() -> void:
	push_warning(
		"FarmTerrainTilesetBuilder: 请运行 python scripts/generate_farm_ground_tres.py 生成完整三层地形 TileSet"
	)
