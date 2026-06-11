extends Area2D

@export var item_data: ItemResource

func _ready():
	$Sprite2D.texture = item_data.icon

func _on_body_entered(body):
	if body.name == "Player":
		InventoryManager.add_item(item_data, 1)  # 加上数量参数
		queue_free()
