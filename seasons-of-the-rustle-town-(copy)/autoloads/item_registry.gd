extends Node

var _items: Dictionary = {}


func _ready() -> void:
	_register_default_items()


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
	pass
