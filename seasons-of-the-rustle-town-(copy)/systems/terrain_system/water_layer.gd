@tool
extends TileMapLayer

## 水体层：占位瓦片 + 柏林噪声水面 Shader。
## 在编辑器中用画笔在 TileMapLayerWater 上铺白色占位格即可显示动态河水。

const WATER_TILESET_PATH := "res://resources/tilesets/water_surface.tres"
const WATER_SHADER_PATH := "res://shaders/water_surface.gdshader"

@export_group("Shader")
@export var scroll_speed: Vector2 = Vector2(0.06, 0.1)
@export var wave_scale: float = 7.0
@export var water_alpha: float = 0.9


func _enter_tree() -> void:
	_ensure_tileset()
	_apply_water_material()


func _ensure_tileset() -> void:
	if tile_set != null:
		return
	if ResourceLoader.exists(WATER_TILESET_PATH):
		tile_set = load(WATER_TILESET_PATH) as TileSet
	else:
		tile_set = WaterTilesetBuilder.build_tileset()


func _apply_water_material() -> void:
	var shader := load(WATER_SHADER_PATH) as Shader
	if shader == null:
		push_warning("WaterLayer: 找不到 %s" % WATER_SHADER_PATH)
		return

	var mat := material as ShaderMaterial
	if mat == null or mat.shader != shader:
		mat = ShaderMaterial.new()
		mat.shader = shader
		material = mat

	mat.set_shader_parameter("scroll_speed", scroll_speed)
	mat.set_shader_parameter("wave_scale", wave_scale)
	mat.set_shader_parameter("alpha", water_alpha)


func _set(property: StringName, value: Variant) -> bool:
	match property:
		&"scroll_speed":
			scroll_speed = value
			_apply_water_material()
			return true
		&"wave_scale":
			wave_scale = value
			_apply_water_material()
			return true
		&"water_alpha":
			water_alpha = value
			_apply_water_material()
			return true
	return false
