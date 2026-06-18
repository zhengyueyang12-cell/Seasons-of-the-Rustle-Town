extends Node

const CROPS_DIR: String = "res://resources/crops/"

var _crops: Dictionary = {}


func _ready() -> void:
	_load_crops_from_directory()


func register_crop(crop: CropResource) -> void:
	if crop == null or crop.id == &"":
		push_warning("CropRegistry: 无法注册无效作物")
		return
	_crops[crop.id] = crop


func get_crop(crop_id: StringName) -> CropResource:
	var crop: Variant = _crops.get(crop_id)
	if crop is CropResource:
		return crop as CropResource
	return null


func has_crop(crop_id: StringName) -> bool:
	return _crops.has(crop_id)


func get_all_crops() -> Array[CropResource]:
	var result: Array[CropResource] = []
	for crop: Variant in _crops.values():
		if crop is CropResource:
			result.append(crop as CropResource)
	return result


func _load_crops_from_directory() -> void:
	var dir: DirAccess = DirAccess.open(CROPS_DIR)
	if dir == null:
		return

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var resource: Resource = load(CROPS_DIR + file_name)
			if resource is CropResource:
				var crop: CropResource = resource as CropResource
				if crop.id != &"":
					register_crop(crop)
		file_name = dir.get_next()
	dir.list_dir_end()
