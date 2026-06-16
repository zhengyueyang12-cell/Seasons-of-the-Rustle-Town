extends Node

const TOOLS_DIR: String = "res://resources/tools/"

var _tools: Dictionary = {}


func _ready() -> void:
	_load_tools_from_directory()


func register_tool(tool_id: StringName, tool: ToolResource) -> void:
	if tool == null:
		push_warning("ToolRegistry: 无法注册空工具")
		return
	tool.id = tool_id
	_tools[tool_id] = tool
	ItemRegistry.register_item(tool)


func get_tool(tool_id: StringName) -> ToolResource:
	var tool: Variant = _tools.get(tool_id)
	if tool is ToolResource:
		return tool as ToolResource
	return null


func get_all_tools() -> Array[ToolResource]:
	var result: Array[ToolResource] = []
	for tool: Variant in _tools.values():
		if tool is ToolResource:
			result.append(tool as ToolResource)
	return result


func get_tools_by_type(type: ToolResource.ToolType) -> Array[ToolResource]:
	var result: Array[ToolResource] = []
	for tool: ToolResource in get_all_tools():
		if tool.tool_type == type:
			result.append(tool)
	return result


func has_tool(tool_id: StringName) -> bool:
	return _tools.has(tool_id)


func _load_tools_from_directory() -> void:
	var dir: DirAccess = DirAccess.open(TOOLS_DIR)
	if dir == null:
		push_warning("ToolRegistry: 无法打开工具目录 %s" % TOOLS_DIR)
		return

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var path: String = TOOLS_DIR + file_name
			var resource: Resource = load(path)
			if resource is ToolResource:
				var tool: ToolResource = resource as ToolResource
				if tool.id == &"":
					push_warning("ToolRegistry: %s 缺少 id" % path)
				else:
					register_tool(tool.id, tool)
			else:
				push_warning("ToolRegistry: %s 不是 ToolResource" % path)
		file_name = dir.get_next()
	dir.list_dir_end()
