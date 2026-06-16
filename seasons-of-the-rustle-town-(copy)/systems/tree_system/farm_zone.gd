extends Area2D

## 标记农场可种植/可扩散区域。在编辑器中调整 CollisionShape2D 覆盖农田。

func _ready() -> void:
	add_to_group(&"farm_zone")
