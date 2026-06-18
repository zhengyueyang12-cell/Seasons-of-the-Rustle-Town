class_name ItemSlotData
extends RefCounted

var item: ItemResource = null
var quantity: int = 0

var is_empty: bool:
	get:
		return item == null or quantity <= 0
