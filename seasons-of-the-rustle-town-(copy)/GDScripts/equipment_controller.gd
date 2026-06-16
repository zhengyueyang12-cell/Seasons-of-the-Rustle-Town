extends Node
class_name EquipmentController

signal hotbar_equipped(slot_index: int, item: ItemResource)

@export var weapon_manager_path: NodePath = NodePath("../WeaponManager")
@export var tool_manager_path: NodePath = NodePath("../ToolManager")

var active_hotbar_index: int = -1
var is_tool_active: bool = false
var is_weapon_active: bool = false

var _weapon_manager: WeaponManager
var _tool_manager: ToolManager


func _ready() -> void:
	_weapon_manager = get_node_or_null(weapon_manager_path) as WeaponManager
	_tool_manager = get_node_or_null(tool_manager_path) as ToolManager
	InputManager.hotbar_selected.connect(_on_hotbar_selected)


func equip_from_hotbar(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= InventoryManager.SLOT_COUNT:
		return

	active_hotbar_index = slot_index
	var slot: InventoryManager.SlotData = InventoryManager.get_slot(slot_index)
	if slot == null or slot.is_empty:
		_clear_active_equipment()
		return

	var item: ItemResource = slot.item
	if item is ToolResource:
		_equip_tool(item as ToolResource)
	elif item is WeaponResource:
		_equip_weapon(item as WeaponResource)
	else:
		_clear_active_equipment()

	hotbar_equipped.emit(slot_index, item)


func _on_hotbar_selected(slot_index: int) -> void:
	equip_from_hotbar(slot_index)


func _equip_tool(tool: ToolResource) -> void:
	is_tool_active = true
	is_weapon_active = false
	if _weapon_manager != null:
		_weapon_manager.hide_held_item()
	if _tool_manager != null:
		_tool_manager.equip_tool(tool.id)


func _equip_weapon(weapon: WeaponResource) -> void:
	is_tool_active = false
	is_weapon_active = true
	if _tool_manager != null:
		_tool_manager.clear_tool()
	if _weapon_manager != null:
		_weapon_manager.equip_weapon(weapon.id)


func _clear_active_equipment() -> void:
	is_tool_active = false
	is_weapon_active = false
	if _tool_manager != null:
		_tool_manager.clear_tool()
	if _weapon_manager != null:
		_weapon_manager.hide_held_item()
