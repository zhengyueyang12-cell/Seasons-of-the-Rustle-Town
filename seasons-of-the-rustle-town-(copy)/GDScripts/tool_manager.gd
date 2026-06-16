extends Node
class_name ToolManager

signal tool_equipped(tool: ToolResource)

@export var held_sprite_path: NodePath = NodePath("../Weapon/Sprite2D")
@export var held_item_root_path: NodePath = NodePath("../Weapon")

var current_tool_id: StringName = &""

var _held_sprite: Sprite2D
var _held_item_root: Node2D
var _current_tool: ToolResource


func _ready() -> void:
	tool_equipped.connect(_on_tool_equipped_sync)
	call_deferred(&"_initialize")


func _initialize() -> void:
	_held_sprite = get_node_or_null(held_sprite_path) as Sprite2D
	_held_item_root = get_node_or_null(held_item_root_path) as Node2D
	if _held_sprite == null and get_parent() != null:
		_held_sprite = get_parent().get_node_or_null("Weapon/Sprite2D") as Sprite2D
	if _held_item_root == null and get_parent() != null:
		_held_item_root = get_parent().get_node_or_null("Weapon") as Node2D
	_restore_equipped_tool()


func equip_tool(tool_id: StringName) -> void:
	var tool: ToolResource = ToolRegistry.get_tool(tool_id)
	if tool == null:
		push_warning("ToolManager: 未找到工具 %s" % tool_id)
		return

	current_tool_id = tool_id
	_current_tool = tool
	_apply_tool_visual(tool)
	tool_equipped.emit(tool)


func clear_tool() -> void:
	current_tool_id = &""
	_current_tool = null
	_hide_held_item()
	GameState.set_equipped_tool(&"")


func get_current_tool() -> ToolResource:
	return _current_tool


func has_tool() -> bool:
	return _current_tool != null


func get_use_range() -> float:
	return _current_tool.use_range if _current_tool else 0.0


func get_effect_radius() -> float:
	return _current_tool.effect_radius if _current_tool else 0.0


func get_energy_cost() -> int:
	return _current_tool.energy_cost if _current_tool else 0


func get_use_cooldown() -> float:
	return _current_tool.use_cooldown if _current_tool else 0.5


func get_tool_type() -> ToolResource.ToolType:
	return _current_tool.tool_type if _current_tool else ToolResource.ToolType.HOE


func _on_tool_equipped_sync(tool: ToolResource) -> void:
	GameState.set_equipped_tool(tool.id)


func _restore_equipped_tool() -> void:
	var saved_id: StringName = GameState.current_tool_id
	if saved_id != &"" and ToolRegistry.has_tool(saved_id):
		equip_tool(saved_id)


func _apply_tool_visual(tool: ToolResource) -> void:
	if _held_sprite == null:
		return
	if _held_item_root != null:
		_held_item_root.visible = true
	if tool.held_sprite != null:
		_held_sprite.texture = tool.held_sprite
		_held_sprite.visible = true
	else:
		_held_sprite.texture = tool.icon
		_held_sprite.visible = tool.icon != null


func _hide_held_item() -> void:
	if _held_sprite != null:
		_held_sprite.texture = null
		_held_sprite.visible = false
