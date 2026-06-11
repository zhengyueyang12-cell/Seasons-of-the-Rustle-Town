extends Area2D

@export var weapon_data: WeaponResource

func _ready():
	if weapon_data and weapon_data.icon:
		$Sprite2D.texture = weapon_data.icon

func _on_body_entered(body):
	print("碰到物体：", body.name)  # 添加调试
	if body.name == "Player":
		InventoryManager.add_item(weapon_data, 1)
		queue_free()
