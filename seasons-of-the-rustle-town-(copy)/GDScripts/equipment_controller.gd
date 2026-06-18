extends Node
class_name EquipmentController

signal hotbar_equipped(slot_index: int, item: ItemResource)

@export var weapon_manager_path: NodePath = NodePath("../WeaponManager")
@export var tool_manager_path: NodePath = NodePath("../ToolManager")

const HOTBAR_SLOT_COUNT: int = 9

var active_hotbar_index: int = -1
var is_tool_active: bool = false
var is_weapon_active: bool = false

var _weapon_manager: WeaponManager
var _tool_manager: ToolManager


func _ready() -> void:
	_weapon_manager = get_node_or_null(weapon_manager_path) as WeaponManager
	_tool_manager = get_node_or_null(tool_manager_path) as ToolManager
	InputManager.hotbar_selected.connect(_on_hotbar_selected)
	InputManager.hotbar_scroll.connect(_on_hotbar_scroll)
	HotbarManager.hotbar_changed.connect(_on_hotbar_contents_changed)


func _on_hotbar_scroll(step: int) -> void:
	var index: int = active_hotbar_index
	if index < 0:
		index = 0
	else:
		index = posmod(index + step, HOTBAR_SLOT_COUNT)
	equip_from_hotbar(index)


func equip_from_hotbar(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= HotbarManager.SLOT_COUNT:
		return

	active_hotbar_index = slot_index
	HotbarManager.set_active_slot(slot_index)
	var slot: ItemSlotData = HotbarManager.get_slot(slot_index)
	if slot == null or slot.is_empty:
		_clear_active_equipment()
		return

	var item: ItemResource = slot.item
	if item is ToolResource:
		_equip_tool(item as ToolResource)
	elif item is WeaponResource:
		_equip_weapon(item as WeaponResource)
	else:
		_equip_held_item(item)

	hotbar_equipped.emit(slot_index, item)


func _on_hotbar_selected(slot_index: int) -> void:
	equip_from_hotbar(slot_index)


func _on_hotbar_contents_changed() -> void:
	if active_hotbar_index >= 0:
		equip_from_hotbar(active_hotbar_index)


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


func _equip_held_item(item: ItemResource) -> void:
	is_tool_active = false
	is_weapon_active = false
	if _weapon_manager != null:
		_weapon_manager.hide_held_item()
	if _tool_manager != null:
		_tool_manager.clear_tool()
		_tool_manager.show_held_icon(item.icon if item != null else null)


func _clear_active_equipment() -> void:
	is_tool_active = false
	is_weapon_active = false
	if _tool_manager != null:
		_tool_manager.clear_tool()
	if _weapon_manager != null:
		_weapon_manager.hide_held_item()
