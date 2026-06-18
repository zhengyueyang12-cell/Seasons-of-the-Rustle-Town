class_name CropSpriteUtil
extends RefCounted

const CROPS_TEXTURE_PATH := "res://art/items/TileSheets/crops..png"
const TILE_SIZE := 16
const WORLD_SCALE := Vector2(2.0, 2.0)


static func apply_atlas(sprite: Sprite2D, atlas: Vector2i) -> void:
	var texture: Texture2D = load(CROPS_TEXTURE_PATH) as Texture2D
	if texture == null:
		return
	sprite.texture = texture
	sprite.region_enabled = true
	sprite.region_rect = Rect2(
		atlas.x * TILE_SIZE,
		atlas.y * TILE_SIZE,
		TILE_SIZE,
		TILE_SIZE
	)
	sprite.centered = true
	sprite.scale = WORLD_SCALE
