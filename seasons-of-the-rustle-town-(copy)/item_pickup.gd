extends Area2D

@export var item_data: ItemResource


func _ready() -> void:
	if item_data == null or item_data.icon == null:
		return
	var sprite: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D
	if sprite != null:
		sprite.texture = item_data.icon


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group(&"player"):
		return
	if item_data == null:
		return
	InventoryManager.add_item(item_data, 1)
	queue_free()
