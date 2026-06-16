class_name DropSpawner
extends RefCounted

const ITEM_DROP_SCENE: PackedScene = preload("res://Scenes/items/item_drop.tscn")

## 在撞击区内沿倒下方向散落生成地面掉落物。
static func spawn_scattered(
	parent: Node,
	item: ItemResource,
	count: int,
	origin: Vector2,
	fall_direction: Vector2,
	zone_length: float = 96.0,
	zone_width: float = 64.0
) -> void:
	if parent == null or item == null or count <= 0:
		return

	var dir: Vector2 = fall_direction.normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.DOWN

	var perpendicular: Vector2 = Vector2(-dir.y, dir.x)

	for _i: int in count:
		var along: float = randf_range(0.2, 1.0) * zone_length
		var across: float = randf_range(-zone_width * 0.5, zone_width * 0.5)
		var offset: Vector2 = dir * along + perpendicular * across
		_spawn_single(parent, item, origin + offset)


## 在圆形区域内随机散落（受击即时掉落）。
static func spawn_near(
	parent: Node,
	item: ItemResource,
	count: int,
	origin: Vector2,
	radius: float = 28.0
) -> void:
	if parent == null or item == null or count <= 0:
		return

	for _i: int in count:
		var angle: float = randf() * TAU
		var dist: float = randf() * radius
		var offset: Vector2 = Vector2(cos(angle), sin(angle)) * dist
		_spawn_single(parent, item, origin + offset)


static func _spawn_single(parent: Node, item: ItemResource, global_pos: Vector2) -> void:
	var drop: Node2D = ITEM_DROP_SCENE.instantiate() as Node2D
	if drop == null:
		return

	parent.add_child(drop)
	drop.global_position = global_pos
	if drop.has_method(&"setup"):
		drop.setup(item, 1)
