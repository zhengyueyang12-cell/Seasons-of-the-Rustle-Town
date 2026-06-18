extends Node

const TREES_DIR: String = "res://resources/trees/"

var _trees: Dictionary = {}


func _ready() -> void:
	_load_trees_from_directory()


func register_tree(tree: TreeResource) -> void:
	if tree == null or tree.id == &"":
		push_warning("TreeRegistry: 无法注册无效树种")
		return
	_trees[tree.id] = tree


func get_tree_resource(tree_id: StringName) -> TreeResource:
	var tree: Variant = _trees.get(tree_id)
	if tree is TreeResource:
		return tree as TreeResource
	return null


func has_tree(tree_id: StringName) -> bool:
	return _trees.has(tree_id)


func get_all_trees() -> Array[TreeResource]:
	var result: Array[TreeResource] = []
	for tree: Variant in _trees.values():
		if tree is TreeResource:
			result.append(tree as TreeResource)
	return result


func get_random_tree() -> TreeResource:
	var all: Array[TreeResource] = get_all_trees()
	if all.is_empty():
		return null
	return all[randi() % all.size()]


func _load_trees_from_directory() -> void:
	var dir: DirAccess = DirAccess.open(TREES_DIR)
	if dir == null:
		return

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var resource: Resource = load(TREES_DIR + file_name)
			if resource is TreeResource:
				var tree: TreeResource = resource as TreeResource
				if tree.id != &"":
					register_tree(tree)
		file_name = dir.get_next()
	dir.list_dir_end()
