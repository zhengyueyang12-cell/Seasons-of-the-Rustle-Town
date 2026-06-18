@tool
class_name FarmTerrainTilesetBuilder
extends RefCounted

## 草地(meadow) ↔ 泥土(dirt) 地形融合 TileSet 构建器。
## 在 Godot 编辑器中：文件 → 运行 → 选择本脚本，即可生成 farm_ground.tres

const OUTPUT_PATH := "res://resources/tilesets/farm_ground.tres"
const SPRING_SHEET := "res://art/world/TerrainFeatures/spring_outdoorsTileSheet..png"
const TILE_SIZE := 16

const TERRAIN_SET := 0
const MEADOW := 0
const DIRT := 1

## 8 方向 peering，与 Godot TileSet.CellNeighbor 一致
const _PEER := {
	"right_side": TileSet.CellNeighbor.RIGHT_SIDE,
	"bottom_right_corner": TileSet.CellNeighbor.BOTTOM_RIGHT_CORNER,
	"bottom_side": TileSet.CellNeighbor.BOTTOM_SIDE,
	"bottom_left_corner": TileSet.CellNeighbor.BOTTOM_LEFT_CORNER,
	"left_side": TileSet.CellNeighbor.LEFT_SIDE,
	"top_left_corner": TileSet.CellNeighbor.TOP_LEFT_CORNER,
	"top_side": TileSet.CellNeighbor.TOP_SIDE,
	"top_right_corner": TileSet.CellNeighbor.TOP_RIGHT_CORNER,
}

## atlas 坐标 → { terrain, peering: { bit_name: terrain_id } }
## 坐标来自 spring_outdoors 图集 16×16 网格（见 art/.../_labeled_terrain.png）
const TILE_DEFS: Dictionary = {
	# --- 纯草地 ---
	Vector2i(0, 6): {"terrain": MEADOW, "peering": _all(MEADOW)},
	Vector2i(0, 7): {"terrain": MEADOW, "peering": _all(MEADOW)},
	Vector2i(1, 6): {"terrain": MEADOW, "peering": _all(MEADOW)},
	Vector2i(2, 6): {"terrain": MEADOW, "peering": _all(MEADOW)},
	Vector2i(5, 7): {"terrain": MEADOW, "peering": _all(MEADOW)},
	# 草地下方接泥土（上草下泥过渡）
	Vector2i(4, 7): {
		"terrain": MEADOW,
		"peering": _merge(_all(MEADOW), {
			"bottom_side": DIRT, "bottom_left_corner": DIRT, "bottom_right_corner": DIRT,
		}),
	},
	Vector2i(1, 8): {
		"terrain": MEADOW,
		"peering": _merge(_all(MEADOW), {
			"bottom_side": DIRT, "bottom_left_corner": DIRT, "bottom_right_corner": DIRT,
		}),
	},
	Vector2i(3, 8): {
		"terrain": MEADOW,
		"peering": _merge(_all(MEADOW), {
			"bottom_side": DIRT, "bottom_left_corner": DIRT, "bottom_right_corner": DIRT,
		}),
	},
	Vector2i(4, 8): {
		"terrain": MEADOW,
		"peering": _merge(_all(MEADOW), {
			"bottom_side": DIRT, "bottom_left_corner": DIRT, "bottom_right_corner": DIRT,
		}),
	},
	Vector2i(5, 8): {
		"terrain": MEADOW,
		"peering": _merge(_all(MEADOW), {
			"bottom_side": DIRT, "bottom_left_corner": DIRT, "bottom_right_corner": DIRT,
		}),
	},
	# 草地左下外角（右、下为泥）
	Vector2i(0, 8): {
		"terrain": MEADOW,
		"peering": _merge(_all(MEADOW), {
			"right_side": DIRT, "bottom_side": DIRT,
		}),
	},
	# 草地右侧接泥土
	Vector2i(2, 8): {
		"terrain": MEADOW,
		"peering": _merge(_all(MEADOW), {
			"right_side": DIRT, "top_right_corner": DIRT, "bottom_right_corner": DIRT,
		}),
	},
	# 草地左下外角（右、下为泥）
	Vector2i(0, 8): {
		"terrain": MEADOW,
		"peering": _merge(_all(MEADOW), {
			"right_side": DIRT, "bottom_side": DIRT, "bottom_right_corner": DIRT,
		}),
	},
	# 草地上方接泥土
	Vector2i(6, 8): {
		"terrain": MEADOW,
		"peering": _merge(_all(MEADOW), {
			"top_side": DIRT, "top_left_corner": DIRT, "top_right_corner": DIRT,
		}),
	},
	# 草地左侧接泥土
	Vector2i(7, 8): {
		"terrain": MEADOW,
		"peering": _merge(_all(MEADOW), {
			"left_side": DIRT, "top_left_corner": DIRT, "bottom_left_corner": DIRT,
		}),
	},
	# --- 纯泥土 ---
	Vector2i(3, 6): {"terrain": DIRT, "peering": _all(DIRT)},
	Vector2i(4, 6): {"terrain": DIRT, "peering": _all(DIRT)},
	# 泥土上方接草地
	Vector2i(2, 7): {
		"terrain": DIRT,
		"peering": _merge(_all(DIRT), {
			"top_side": MEADOW, "top_left_corner": MEADOW, "top_right_corner": MEADOW,
		}),
	},
	# 泥土左上外角（上、左为草）
	Vector2i(1, 7): {
		"terrain": DIRT,
		"peering": _merge(_all(DIRT), {
			"top_side": MEADOW, "left_side": MEADOW, "top_left_corner": MEADOW,
		}),
	},
	# 泥土右下外角（右、下为草）
	Vector2i(3, 7): {
		"terrain": DIRT,
		"peering": _merge(_all(DIRT), {
			"right_side": MEADOW, "bottom_side": MEADOW, "bottom_right_corner": MEADOW,
		}),
	},
	# 泥土下方接草地
	Vector2i(5, 6): {
		"terrain": DIRT,
		"peering": _merge(_all(DIRT), {
			"bottom_side": MEADOW, "bottom_left_corner": MEADOW, "bottom_right_corner": MEADOW,
		}),
	},
	# 泥土左侧接草地
	Vector2i(6, 7): {
		"terrain": DIRT,
		"peering": _merge(_all(DIRT), {
			"left_side": MEADOW, "top_left_corner": MEADOW, "bottom_left_corner": MEADOW,
		}),
	},
	# 泥土右侧接草地
	Vector2i(8, 8): {
		"terrain": DIRT,
		"peering": _merge(_all(DIRT), {
			"right_side": MEADOW, "top_right_corner": MEADOW, "bottom_right_corner": MEADOW,
		}),
	},
}


static func build_tileset() -> TileSet:
	var tile_set := TileSet.new()
	tile_set.add_terrain_set()
	tile_set.set_terrain_set_mode(TERRAIN_SET, TileSet.TERRAIN_MODE_MATCH_SIDES)
	tile_set.add_terrain(TERRAIN_SET)
	tile_set.set_terrain_name(TERRAIN_SET, MEADOW, "meadow")
	tile_set.set_terrain_color(TERRAIN_SET, MEADOW, Color(0.14, 0.25, 0.18))
	tile_set.add_terrain(TERRAIN_SET)
	tile_set.set_terrain_name(TERRAIN_SET, DIRT, "dirt")
	tile_set.set_terrain_color(TERRAIN_SET, DIRT, Color(0.5, 0.44, 0.25))

	var source := TileSetAtlasSource.new()
	source.texture = load(SPRING_SHEET) as Texture2D
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)

	for atlas: Vector2i in TILE_DEFS.keys():
		source.create_tile(atlas)

	for atlas: Vector2i in TILE_DEFS.keys():
		var def: Dictionary = TILE_DEFS[atlas]
		var td: TileData = source.get_tile_data(atlas, 0)
		td.terrain_set = TERRAIN_SET
		td.terrain = int(def["terrain"])
		var peering: Dictionary = def["peering"]
		for bit_name: String in _PEER.keys():
			var neighbor: int = _PEER[bit_name]
			td.set_terrain_peering_bit(neighbor, int(peering[bit_name]))

	tile_set.add_source(source, 0)
	return tile_set


static func save_tileset() -> void:
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path("res://resources/tilesets")
	)
	var tile_set := build_tileset()
	var err := ResourceSaver.save(tile_set, OUTPUT_PATH)
	if err != OK:
		push_error("FarmTerrainTilesetBuilder: 保存失败 (%s) %s" % [err, OUTPUT_PATH])
		return
	print("FarmTerrainTilesetBuilder: 已保存 → ", OUTPUT_PATH)


static func _all(terrain_id: int) -> Dictionary:
	var result := {}
	for bit_name: String in _PEER.keys():
		result[bit_name] = terrain_id
	return result


static func _merge(base: Dictionary, overrides: Dictionary) -> Dictionary:
	var result := base.duplicate()
	for key: String in overrides.keys():
		result[key] = overrides[key]
	return result
