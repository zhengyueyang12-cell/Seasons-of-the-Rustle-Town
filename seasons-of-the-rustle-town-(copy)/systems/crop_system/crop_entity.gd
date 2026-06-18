extends Node2D
class_name CropEntity

signal harvested(crop_id: StringName, cell: Vector2i)

@export var crop_id: StringName = &""

var cell: Vector2i = Vector2i.ZERO
var current_stage: int = 0

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group(&"crop")
	y_sort_enabled = true
	_refresh_sprite()


func setup(new_crop_id: StringName, map_cell: Vector2i, stage: int = 0) -> void:
	crop_id = new_crop_id
	cell = map_cell
	current_stage = stage
	if is_node_ready():
		_refresh_sprite()


func get_crop_data() -> CropResource:
	return CropRegistry.get_crop(crop_id)


func is_mature() -> bool:
	var data: CropResource = get_crop_data()
	if data == null or data.stage_atlas_coords.is_empty():
		return false
	return current_stage >= data.stage_atlas_coords.size() - 1


func advance_stage() -> bool:
	var data: CropResource = get_crop_data()
	if data == null or data.stage_atlas_coords.is_empty():
		return false
	if is_mature():
		return false
	current_stage += 1
	_refresh_sprite()
	return true


func _refresh_sprite() -> void:
	var data: CropResource = get_crop_data()
	if data == null or data.stage_atlas_coords.is_empty():
		return
	var atlas: Vector2i = data.stage_atlas_coords[mini(current_stage, data.stage_atlas_coords.size() - 1)]
	CropSpriteUtil.apply_atlas(_sprite, atlas)
