class_name ItemSlotOps
extends RefCounted

static func swap_slots(slots: Array, index_a: int, index_b: int) -> void:
	if not _is_valid_index(slots, index_a) or not _is_valid_index(slots, index_b):
		return
	if index_a == index_b:
		return

	var slot_a: ItemSlotData = slots[index_a]
	var slot_b: ItemSlotData = slots[index_b]

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
			return

	var temp_item: ItemResource = slot_a.item
	var temp_quantity: int = slot_a.quantity
	slot_a.item = slot_b.item
	slot_a.quantity = slot_b.quantity
	slot_b.item = temp_item
	slot_b.quantity = temp_quantity


static func _is_valid_index(slots: Array, index: int) -> bool:
	return index >= 0 and index < slots.size()
