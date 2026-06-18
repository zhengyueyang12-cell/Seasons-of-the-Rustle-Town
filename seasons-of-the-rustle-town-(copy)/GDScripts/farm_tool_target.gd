class_name FarmToolTarget
extends RefCounted

## 将鼠标位置限制在玩家周围可交互范围内。

static func get_clamped_world_position(player: Node2D, max_range: float) -> Vector2:
	if player == null:
		return Vector2.ZERO

	var camera: Camera2D = player.get_viewport().get_camera_2d()
	if camera == null:
		return player.global_position

	var mouse_global: Vector2 = camera.get_global_mouse_position()
	var offset: Vector2 = mouse_global - player.global_position
	if offset.length_squared() <= max_range * max_range:
		return mouse_global
	if offset == Vector2.ZERO:
		return player.global_position + Vector2.DOWN * max_range
	return player.global_position + offset.normalized() * max_range
