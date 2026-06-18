extends Button
class_name InventorySlotUI

@export var container_type: ItemTransferService.ContainerType = ItemTransferService.ContainerType.INVENTORY
@export var slot_index: int = 0

const HOTBAR_STYLE_ACTIVE := preload("res://resources/ui/hotbar_slot_active.tres")
const HOTBAR_STYLE_IDLE := preload("res://resources/ui/hotbar_slot_idle.tres")

var _icon: TextureRect
var _quantity: Label
var _selection_border: Panel
var _slot_number: Label
var _is_bound: bool = false


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	flat = true
	_cache_nodes()
	pressed.connect(_on_pressed)


func bind_slot(
	type: ItemTransferService.ContainerType,
	index: int
) -> void:
	if _is_bound:
		_disconnect_signals()

	container_type = type
	slot_index = index
	_connect_signals()
	_is_bound = true

	if _slot_number != null:
		_slot_number.visible = type == ItemTransferService.ContainerType.HOTBAR
		if type == ItemTransferService.ContainerType.HOTBAR:
			_slot_number.text = str(index + 1)

	if _selection_border != null:
		_selection_border.visible = type == ItemTransferService.ContainerType.HOTBAR
		_selection_border.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_refresh_display()
	if type == ItemTransferService.ContainerType.HOTBAR:
		_update_highlight(_get_active_hotbar_index())


func refresh_display() -> void:
	_refresh_display()


func refresh_highlight() -> void:
	if container_type == ItemTransferService.ContainerType.HOTBAR:
		_update_highlight(_get_active_hotbar_index())


func _hotbar() -> Node:
	var tree: SceneTree = get_tree()
	if tree == null:
		return null
	return tree.root.get_node_or_null("HotbarManager")


func _inventory() -> Node:
	var tree: SceneTree = get_tree()
	if tree == null:
		return null
	return tree.root.get_node_or_null("InventoryManager")


func _input_manager() -> Node:
	var tree: SceneTree = get_tree()
	if tree == null:
		return null
	return tree.root.get_node_or_null("InputManager")


func _get_active_hotbar_index() -> int:
	var hotbar: Node = _hotbar()
	if hotbar == null:
		return 0
	return int(hotbar.get("active_slot_index"))


func _cache_nodes() -> void:
	_icon = get_node_or_null("Icon") as TextureRect
	_quantity = get_node_or_null("Quantity") as Label
	_selection_border = get_node_or_null("SelectionBorder") as Panel
	_slot_number = get_node_or_null("SlotNumber") as Label


func _connect_signals() -> void:
	if container_type == ItemTransferService.ContainerType.HOTBAR:
		var hotbar: Node = _hotbar()
		if hotbar == null:
			return
		hotbar.slot_changed.connect(_on_slot_changed)
		hotbar.hotbar_changed.connect(_on_hotbar_changed)
		hotbar.active_slot_changed.connect(_on_active_slot_changed)
	else:
		var inventory: Node = _inventory()
		if inventory == null:
			return
		inventory.slot_changed.connect(_on_slot_changed)
		inventory.inventory_changed.connect(_on_inventory_changed)


func _disconnect_signals() -> void:
	var hotbar: Node = _hotbar()
	if hotbar != null:
		if hotbar.slot_changed.is_connected(_on_slot_changed):
			hotbar.slot_changed.disconnect(_on_slot_changed)
		if hotbar.hotbar_changed.is_connected(_on_hotbar_changed):
			hotbar.hotbar_changed.disconnect(_on_hotbar_changed)
		if hotbar.active_slot_changed.is_connected(_on_active_slot_changed):
			hotbar.active_slot_changed.disconnect(_on_active_slot_changed)

	var inventory: Node = _inventory()
	if inventory != null:
		if inventory.slot_changed.is_connected(_on_slot_changed):
			inventory.slot_changed.disconnect(_on_slot_changed)
		if inventory.inventory_changed.is_connected(_on_inventory_changed):
			inventory.inventory_changed.disconnect(_on_inventory_changed)


func _on_slot_changed(changed_index: int) -> void:
	if changed_index == slot_index:
		_refresh_display()


func _on_hotbar_changed() -> void:
	_refresh_display()


func _on_inventory_changed() -> void:
	_refresh_display()


func _on_active_slot_changed(active_index: int) -> void:
	_update_highlight(active_index)


func _on_pressed() -> void:
	if container_type == ItemTransferService.ContainerType.HOTBAR:
		var input_manager: Node = _input_manager()
		if input_manager != null:
			input_manager.hotbar_selected.emit(slot_index)


func _get_slot_data() -> ItemSlotData:
	if container_type == ItemTransferService.ContainerType.INVENTORY:
		var inventory: Node = _inventory()
		if inventory == null:
			return null
		return inventory.get_slot(slot_index) as ItemSlotData

	var hotbar: Node = _hotbar()
	if hotbar == null:
		return null
	return hotbar.get_slot(slot_index) as ItemSlotData


func _refresh_display() -> void:
	if not _is_bound:
		return

	var slot_data: ItemSlotData = _get_slot_data()
	if slot_data != null and not slot_data.is_empty and slot_data.item != null:
		if _icon != null:
			_icon.texture = slot_data.item.icon
			_icon.visible = slot_data.item.icon != null
		if _quantity != null:
			_quantity.text = str(slot_data.quantity) if slot_data.quantity > 1 else ""
	else:
		if _icon != null:
			_icon.texture = null
			_icon.visible = false
		if _quantity != null:
			_quantity.text = ""


func _update_highlight(active_index: int) -> void:
	if container_type != ItemTransferService.ContainerType.HOTBAR:
		return
	if _selection_border == null:
		return

	var is_active: bool = slot_index == active_index
	var slot_style: StyleBox = HOTBAR_STYLE_ACTIVE if is_active else HOTBAR_STYLE_IDLE
	_selection_border.add_theme_stylebox_override(&"panel", slot_style)
	_selection_border.visible = true
	scale = Vector2(1.06, 1.06) if is_active else Vector2.ONE

	if _slot_number != null:
		_slot_number.add_theme_color_override(
			&"font_color",
			Color(0.349, 0.671, 0.545, 0.467) if is_active else Color(0.75, 0.75, 0.82, 0.9)
		)


func _get_drag_data(_at_position: Vector2) -> Variant:
	var slot_data: ItemSlotData = _get_slot_data()
	if slot_data == null or slot_data.is_empty:
		return null

	var preview: TextureRect = TextureRect.new()
	preview.texture = slot_data.item.icon
	preview.custom_minimum_size = Vector2(40, 40)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	set_drag_preview(preview)

	return {
		"container": container_type,
		"slot_index": slot_index,
	}


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not data is Dictionary:
		return false
	return data.has("container") and data.has("slot_index")


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not data is Dictionary:
		return

	var from_container: ItemTransferService.ContainerType = data["container"]
	var from_index: int = int(data["slot_index"])
	if from_container == container_type and from_index == slot_index:
		return

	ItemTransferService.transfer(from_container, from_index, container_type, slot_index)
