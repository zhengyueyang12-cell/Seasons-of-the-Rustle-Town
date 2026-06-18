extends Node

const _SLOT_OPS = preload("res://autoloads/item_slot_ops.gd")

signal inventory_changed()
signal slot_changed(slot_index: int)

const INVENTORY_ROWS: int = 4
const INVENTORY_COLUMNS: int = 6
const SLOT_COUNT: int = INVENTORY_ROWS * INVENTORY_COLUMNS

var slots: Array[ItemSlotData] = []


func _ready() -> void:
	_initialize_slots()


func _initialize_slots() -> void:
	slots.clear()
	for _i: int in SLOT_COUNT:
		slots.append(ItemSlotData.new())


func add_item(item: ItemResource, amount: int) -> int:
	if item == null or amount <= 0:
		return amount

	var remaining: int = amount
	remaining = _stack_into_existing(item, remaining)
	remaining = _fill_empty_slots(item, remaining)

	if remaining != amount:
		inventory_changed.emit()

	return remaining


func remove_item(item_id: StringName, amount: int) -> bool:
	if amount <= 0:
		return true

	var available: int = get_item_count(item_id)
	if available < amount:
		return false

	var remaining: int = amount
	remaining = _remove_from_slots(slots, remaining, item_id, SLOT_COUNT)
	if remaining > 0:
		remaining = _remove_from_hotbar(item_id, remaining)

	inventory_changed.emit()
	HotbarManager.hotbar_changed.emit()
	return remaining <= 0


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
	inventory_changed.emit()
	return true


func swap_slots(index_a: int, index_b: int) -> void:
	if not _is_valid_index(index_a) or not _is_valid_index(index_b):
		return
	if index_a == index_b:
		return

	_SLOT_OPS.swap_slots(slots, index_a, index_b)
	slot_changed.emit(index_a)
	slot_changed.emit(index_b)
	inventory_changed.emit()


func get_item_count(item_id: StringName) -> int:
	var total: int = 0
	for slot: ItemSlotData in slots:
		if not slot.is_empty and slot.item.id == item_id:
			total += slot.quantity
	total += HotbarManager.get_item_count(item_id)
	return total


func get_slot(index: int) -> ItemSlotData:
	if not _is_valid_index(index):
		return null
	return slots[index]


func clear_inventory() -> void:
	_initialize_slots()
	inventory_changed.emit()


func _stack_into_existing(item: ItemResource, amount: int) -> int:
	var remaining: int = amount
	for i: int in SLOT_COUNT:
		var slot: ItemSlotData = slots[i]
		if slot.is_empty or slot.item.id != item.id:
			continue

		var space: int = item.max_stack - slot.quantity
		if space <= 0:
			continue

		var added: int = mini(space, remaining)
		slot.quantity += added
		remaining -= added
		slot_changed.emit(i)

		if remaining <= 0:
			break

	return remaining


func _fill_empty_slots(item: ItemResource, amount: int) -> int:
	var remaining: int = amount
	for i: int in SLOT_COUNT:
		if remaining <= 0:
			break

		var slot: ItemSlotData = slots[i]
		if not slot.is_empty:
			continue

		var added: int = mini(item.max_stack, remaining)
		slot.item = item
		slot.quantity = added
		remaining -= added
		slot_changed.emit(i)

	return remaining


func _remove_from_slots(
	target_slots: Array,
	remaining: int,
	item_id: StringName,
	count: int
) -> int:
	for i: int in count:
		var slot: ItemSlotData = target_slots[i]
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

	return remaining


func _remove_from_hotbar(item_id: StringName, remaining: int) -> int:
	for i: int in HotbarManager.SLOT_COUNT:
		var slot: ItemSlotData = HotbarManager.get_slot(i)
		if slot == null or slot.is_empty or slot.item.id != item_id:
			continue

		var removed: int = mini(slot.quantity, remaining)
		slot.quantity -= removed
		remaining -= removed

		if slot.quantity <= 0:
			slot.item = null
			slot.quantity = 0

		HotbarManager.slot_changed.emit(i)

		if remaining <= 0:
			break

	return remaining


func _is_valid_index(index: int) -> bool:
	return index >= 0 and index < SLOT_COUNT
