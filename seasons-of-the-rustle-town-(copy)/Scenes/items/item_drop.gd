extends Area2D

## 地面掉落物，支持堆叠数量显示。

@export var item_data: ItemResource
@export var quantity: int = 1

var _sprite: Sprite2D


func _ready() -> void:
	_sprite = get_node_or_null("Sprite2D") as Sprite2D
	_apply_visual()
	body_entered.connect(_on_body_entered)


func setup(item: ItemResource, amount: int = 1) -> void:
	item_data = item
	quantity = maxi(amount, 1)
	if is_inside_tree():
		_apply_visual()


func _apply_visual() -> void:
	if _sprite == null:
		_sprite = get_node_or_null("Sprite2D") as Sprite2D
	if _sprite == null or item_data == null:
		return
	if item_data.icon != null:
		_sprite.texture = item_data.icon
	_sprite.scale = Vector2(1.8, 1.8)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group(&"player"):
		return
	if item_data == null or quantity <= 0:
		return

	var leftover: int = InventoryManager.add_item(item_data, quantity)
	if leftover < quantity:
		queue_free()
