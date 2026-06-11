extends Node

signal inventory_changed()
signal slot_changed(slot_index: int)

const INVENTORY_ROWS: int = 4
const INVENTORY_COLUMNS: int = 6
const SLOT_COUNT: int = INVENTORY_ROWS * INVENTORY_COLUMNS

class SlotData:
	var item: ItemResource = null
	var quantity: int = 0

	var is_empty: bool:
		get:
			return item == null or quantity <= 0


var slots: Array[SlotData] = []


func _ready() -> void:
	_initialize_slots()


func _initialize_slots() -> void:
	slots.clear()
	for _i: int in SLOT_COUNT:
		slots.append(SlotData.new())


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
	for i: int in SLOT_COUNT:
		var slot: SlotData = slots[i]
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

	inventory_changed.emit()
	return true


func swap_slots(index_a: int, index_b: int) -> void:
	if not _is_valid_index(index_a) or not _is_valid_index(index_b):
		return
	if index_a == index_b:
		return

	var slot_a: SlotData = slots[index_a]
	var slot_b: SlotData = slots[index_b]

	if (
		not slot_a.is_empty
		and not slot_b.is_empty
		and slot_a.item.id == slot_b.item.id
	):
		var max_stack: int = slot_a.item.max_stack
		var space_in_b: int = max_stack - slot_b.quantity
		if space_in_b > 0:
			var moved: int = mini(space_in_b, slot_a.quantity)
			slot_b.quantity += moved
			slot_a.quantity -= moved
			if slot_a.quantity <= 0:
				slot_a.item = null
				slot_a.quantity = 0
			slot_changed.emit(index_a)
			slot_changed.emit(index_b)
			inventory_changed.emit()
			return

	var temp_item: ItemResource = slot_a.item
	var temp_quantity: int = slot_a.quantity
	slot_a.item = slot_b.item
	slot_a.quantity = slot_b.quantity
	slot_b.item = temp_item
	slot_b.quantity = temp_quantity

	slot_changed.emit(index_a)
	slot_changed.emit(index_b)
	inventory_changed.emit()


func get_item_count(item_id: StringName) -> int:
	var total: int = 0
	for slot: SlotData in slots:
		if not slot.is_empty and slot.item.id == item_id:
			total += slot.quantity
	return total


func get_slot(index: int) -> SlotData:
	if not _is_valid_index(index):
		return null
	return slots[index]


func clear_inventory() -> void:
	_initialize_slots()
	inventory_changed.emit()


func _stack_into_existing(item: ItemResource, amount: int) -> int:
	var remaining: int = amount
	for i: int in SLOT_COUNT:
		var slot: SlotData = slots[i]
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

		var slot: SlotData = slots[i]
		if not slot.is_empty:
			continue

		var added: int = mini(item.max_stack, remaining)
		slot.item = item
		slot.quantity = added
		remaining -= added
		slot_changed.emit(i)

	return remaining


func _is_valid_index(index: int) -> bool:
	return index >= 0 and index < SLOT_COUNT
