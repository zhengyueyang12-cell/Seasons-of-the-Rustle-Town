extends Node

enum ContainerType { INVENTORY, HOTBAR }


func transfer(
	from_type: ContainerType,
	from_index: int,
	to_type: ContainerType,
	to_index: int
) -> void:
	if from_type == to_type:
		_swap_within_container(from_type, from_index, to_index)
		return

	var from_slot: ItemSlotData = _get_slot(from_type, from_index)
	var to_slot: ItemSlotData = _get_slot(to_type, to_index)
	if from_slot == null or to_slot == null:
		return

	if (
		not from_slot.is_empty
		and not to_slot.is_empty
		and from_slot.item.id == to_slot.item.id
	):
		var max_stack: int = from_slot.item.max_stack
		var space_in_dest: int = max_stack - to_slot.quantity
		if space_in_dest > 0:
			var moved: int = mini(space_in_dest, from_slot.quantity)
			to_slot.quantity += moved
			from_slot.quantity -= moved
			if from_slot.quantity <= 0:
				from_slot.item = null
				from_slot.quantity = 0
			_emit_changes(from_type, from_index, to_type, to_index)
			return

	var temp_item: ItemResource = from_slot.item
	var temp_quantity: int = from_slot.quantity
	from_slot.item = to_slot.item
	from_slot.quantity = to_slot.quantity
	to_slot.item = temp_item
	to_slot.quantity = temp_quantity
	_emit_changes(from_type, from_index, to_type, to_index)


func _swap_within_container(
	container_type: ContainerType,
	index_a: int,
	index_b: int
) -> void:
	if container_type == ContainerType.INVENTORY:
		InventoryManager.swap_slots(index_a, index_b)
	else:
		HotbarManager.swap_slots(index_a, index_b)


func _get_slot(container_type: ContainerType, index: int) -> ItemSlotData:
	if container_type == ContainerType.INVENTORY:
		return InventoryManager.get_slot(index)
	return HotbarManager.get_slot(index)


func _emit_changes(
	from_type: ContainerType,
	from_index: int,
	to_type: ContainerType,
	to_index: int
) -> void:
	if from_type == ContainerType.INVENTORY:
		InventoryManager.slot_changed.emit(from_index)
		InventoryManager.inventory_changed.emit()
	else:
		HotbarManager.slot_changed.emit(from_index)
		HotbarManager.hotbar_changed.emit()

	if to_type == ContainerType.INVENTORY:
		InventoryManager.slot_changed.emit(to_index)
		InventoryManager.inventory_changed.emit()
	else:
		HotbarManager.slot_changed.emit(to_index)
		HotbarManager.hotbar_changed.emit()
