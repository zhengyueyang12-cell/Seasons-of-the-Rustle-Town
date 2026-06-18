extends Node

const ITEMS_DIR: String = "res://resources/items/"

var _items: Dictionary = {}


func _ready() -> void:
	_register_default_items()
	_load_items_from_directory()


func register_item(item: ItemResource) -> void:
	if item == null or item.id == &"":
		push_warning("ItemRegistry: 无法注册无效物品")
		return
	_items[item.id] = item


func unregister_item(item_id: StringName) -> void:
	_items.erase(item_id)


func get_item(item_id: StringName) -> ItemResource:
	var item: Variant = _items.get(item_id)
	if item is ItemResource:
		return item as ItemResource
	return null


func get_all_items() -> Array[ItemResource]:
	var result: Array[ItemResource] = []
	for item: Variant in _items.values():
		if item is ItemResource:
			result.append(item as ItemResource)
	return result


func has_item(item_id: StringName) -> bool:
	return _items.has(item_id)


func _register_default_items() -> void:
	var potion_path: String = "res://resources/healthpotion.tres"
	if ResourceLoader.exists(potion_path):
		var potion: ItemResource = load(potion_path) as ItemResource
		if potion != null:
			register_item(potion)


func _load_items_from_directory() -> void:
	_load_items_in_dir(ITEMS_DIR)
	_load_items_in_dir(ITEMS_DIR + "seeds/")
	_load_items_in_dir(ITEMS_DIR + "produce/")


func _load_items_in_dir(dir_path: String) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var path: String = dir_path + file_name
			var resource: Resource = load(path)
			if resource is ItemResource and not (resource is ToolResource):
				var item: ItemResource = resource as ItemResource
				if item.id != &"":
					register_item(item)
		file_name = dir.get_next()
	dir.list_dir_end()

