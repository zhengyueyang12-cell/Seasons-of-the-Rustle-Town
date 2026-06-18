extends Node

const _SLOT_OPS = preload("res://autoloads/item_slot_ops.gd")

signal hotbar_changed()
signal slot_changed(slot_index: int)
signal active_slot_changed(slot_index: int)

const SLOT_COUNT: int = 9

var slots: Array[ItemSlotData] = []
var active_slot_index: int = 0


func _ready() -> void:
	_initialize_slots()


func _initialize_slots() -> void:
	slots.clear()
	for _i: int in SLOT_COUNT:
		slots.append(ItemSlotData.new())


func get_slot(index: int) -> ItemSlotData:
	if not _is_valid_index(index):
		return null
	return slots[index]


func set_active_slot(index: int, force: bool = false) -> void:
	if not _is_valid_index(index):
		return
	if active_slot_index == index and not force:
		return
	active_slot_index = index
	active_slot_changed.emit(index)


func swap_slots(index_a: int, index_b: int) -> void:
	if not _is_valid_index(index_a) or not _is_valid_index(index_b):
		return
	if index_a == index_b:
		return

	_SLOT_OPS.swap_slots(slots, index_a, index_b)
	slot_changed.emit(index_a)
	slot_changed.emit(index_b)
	hotbar_changed.emit()


func remove_from_slot(slot_index: int, amount: int) -> bool:
	if amount <= 0:
		return true
	if not _is_valid_index(slot_index):
		return false

	var slot: ItemSlotData = slots[slot_index]
	if slot.is_empty or slot.quantity < amount:
		return false

	slot.quantity -= amount
	if slot.quantity <= 0:
		slot.item = null
		slot.quantity = 0

	slot_changed.emit(slot_index)
	hotbar_changed.emit()
	return true


func add_item_to_slot(slot_index: int, item: ItemResource, amount: int) -> int:
	if item == null or amount <= 0 or not _is_valid_index(slot_index):
		return amount

	var slot: ItemSlotData = slots[slot_index]
	if slot.is_empty:
		var added: int = mini(item.max_stack, amount)
		slot.item = item
		slot.quantity = added
		slot_changed.emit(slot_index)
		hotbar_changed.emit()
		return amount - added

	if slot.item.id != item.id:
		return amount

	var space: int = item.max_stack - slot.quantity
	if space <= 0:
		return amount

	var stacked: int = mini(space, amount)
	slot.quantity += stacked
	slot_changed.emit(slot_index)
	hotbar_changed.emit()
	return amount - stacked


func get_item_count(item_id: StringName) -> int:
	var total: int = 0
	for slot: ItemSlotData in slots:
		if not slot.is_empty and slot.item.id == item_id:
			total += slot.quantity
	return total


func remove_item(item_id: StringName, amount: int) -> bool:
	if amount <= 0:
		return true

	var available: int = get_item_count(item_id)
	if available < amount:
		return false

	var remaining: int = amount
	for i: int in SLOT_COUNT:
		var slot: ItemSlotData = slots[i]
		if slot.is_empty or slot.item.id != item_id:
			continue

		var removed: int = mini(slot.quantity, remaining)
		slot.quantity -= removed
		remaining -= removed

		if slot.quantity <= 0:
			slot.item = null
			slot.quantity = 0

		slot_changed.emit(i)

		if remaining <= 0:
			break

	hotbar_changed.emit()
	return true


func _is_valid_index(index: int) -> bool:
	return index >= 0 and index < SLOT_COUNT
