class_name TreeAtlasUtil
extends RefCounted

static func region_texture(atlas: Texture2D, region: Rect2i) -> AtlasTexture:
	var tex := AtlasTexture.new()
	tex.atlas = atlas
	tex.region = region
	return tex


static func region_size(region: Rect2i, scale_factor: float) -> Vector2:
	return Vector2(region.size) * scale_factor


static func season_sheet_path(tree_key: String, season: TimeManager.Season) -> String:
	var candidates: Array[String] = [
		"res://art/world/TerrainFeatures/%s_%s..png" % [tree_key, _season_to_suffix(season)],
		"res://art/world/TerrainFeatures/%s_spring..png" % tree_key,
		"res://art/world/TerrainFeatures/%s..png" % tree_key,
	]
	for path: String in candidates:
		if ResourceLoader.exists(path):
			return path
	return candidates[0]


static func load_season_atlas(tree_key: String, season: TimeManager.Season) -> Texture2D:
	var path: String = season_sheet_path(tree_key, season)
	if not ResourceLoader.exists(path):
		push_warning("TreeAtlasUtil: 找不到树木图集 '%s'" % tree_key)
		return null
	return load(path) as Texture2D


static func _season_to_suffix(season: TimeManager.Season) -> String:
	match season:
		TimeManager.Season.SUMMER:
			return "summer"
		TimeManager.Season.FALL:
			return "fall"
		TimeManager.Season.WINTER:
			return "winter"
		_:
			return "spring"
