extends Area2D

## 地面掉落物：多段弹跳散开、互相挤压、磁吸到玩家身体中心拾取。

enum PickupState { BOUNCING, IDLE, MAGNETIZED, COLLECTED }

@export_group("生成弹跳")
@export var bounce_gravity: float = 1100.0
@export var bounce_damping: float = 0.32
@export var bounce_friction: float = 0.55
@export var bounce_horizontal_kick: float = 5.0
@export var max_bounce_hops: int = 2
@export var min_bounce_velocity: float = 16.0

@export_group("互相挤压")
@export var separation_radius: float = 14.0
@export var separation_strength: float = 3.0

@export_group("磁吸拾取")
@export var magnet_range: float = 72.0
@export var magnet_speed: float = 220.0
@export var magnet_accel: float = 480.0
@export var pickup_distance: float = 12.0
@export var player_pickup_offset: Vector2 = Vector2(10, 48)

@export var item_data: ItemResource
@export var quantity: int = 1

const DISPLAY_SCALE: float = 1.8
const DROP_GROUP: StringName = &"item_drop"

var _sprite: Sprite2D
var _state: PickupState = PickupState.IDLE
var _velocity: Vector2 = Vector2.ZERO
var _floor_y: float = 0.0
var _bounce_hops: int = 0
var _player: Node2D


func _ready() -> void:
	add_to_group(DROP_GROUP)
	_sprite = get_node_or_null("Sprite2D") as Sprite2D
	_apply_visual()
	set_physics_process(false)
	set_process(false)


func setup(item: ItemResource, amount: int = 1) -> void:
	item_data = item
	quantity = maxi(amount, 1)
	if is_inside_tree():
		_apply_visual()


func play_spawn_bounce(launch_vector: Vector2 = Vector2.ZERO) -> void:
	_floor_y = global_position.y
	_bounce_hops = 0
	_state = PickupState.BOUNCING
	set_process(false)

	if launch_vector == Vector2.ZERO:
		var angle: float = randf() * TAU
		launch_vector = Vector2(cos(angle), sin(angle)) * randf_range(10.0, 20.0)
		launch_vector.y -= randf_range(8.0, 16.0)

	_velocity = launch_vector * randf_range(1.0, 1.6)
	global_position += launch_vector * 0.04

	if _sprite != null:
		_sprite.scale = Vector2(1.15, 1.15)

	set_physics_process(true)


func _physics_process(delta: float) -> void:
	match _state:
		PickupState.BOUNCING:
			_update_bounce_physics(delta)
			_apply_item_separation(delta, 0.6)
		PickupState.IDLE:
			_apply_item_separation(delta, 0.4)
		PickupState.MAGNETIZED:
			_update_magnet(delta)


func _update_bounce_physics(delta: float) -> void:
	_velocity.y += bounce_gravity * delta
	global_position += _velocity * delta

	if global_position.y < _floor_y:
		return

	if _velocity.y <= 0.0:
		return

	global_position.y = _floor_y
	_bounce_hops += 1
	_velocity.y = -absf(_velocity.y) * bounce_damping
	_velocity.x *= bounce_friction
	_velocity.x += randf_range(-bounce_horizontal_kick, bounce_horizontal_kick)

	if _sprite != null:
		var squash: float = clampf(1.0 - absf(_velocity.y) * 0.004, 0.82, 1.0)
		_sprite.scale = Vector2(DISPLAY_SCALE * squash, DISPLAY_SCALE * (2.0 - squash))

	if _bounce_hops >= max_bounce_hops or absf(_velocity.y) < min_bounce_velocity:
		_velocity = Vector2.ZERO
		_finish_bounce()


func _apply_item_separation(delta: float, strength_scale: float) -> void:
	var push: Vector2 = Vector2.ZERO
	for node: Node in get_tree().get_nodes_in_group(DROP_GROUP):
		if node == self or not node is Node2D:
			continue

		var other: Node2D = node as Node2D
		var offset: Vector2 = global_position - other.global_position
		var distance: float = offset.length()
		if distance >= separation_radius or distance <= 0.001:
			continue

		var overlap: float = separation_radius - distance
		push += offset.normalized() * overlap

	if push == Vector2.ZERO:
		return

	var impulse: Vector2 = push * separation_strength * strength_scale * delta
	global_position += impulse

	if _state == PickupState.BOUNCING:
		_velocity += impulse * 1.0


func _update_magnet(delta: float) -> void:
	_player = _find_player()
	if _player == null:
		_state = PickupState.IDLE
		set_process(true)
		return

	var target_pos: Vector2 = _get_player_pickup_position()
	var to_target: Vector2 = target_pos - global_position
	var distance: float = to_target.length()
	if distance <= pickup_distance:
		_try_collect()
		return

	var speed: float = magnet_speed + maxf(0.0, magnet_range - distance) * magnet_accel * 0.01
	global_position += to_target.normalized() * speed * delta

	if _sprite != null:
		var shrink: float = clampf(1.0 - distance / (magnet_range * 1.5), 0.65, 1.0)
		_sprite.scale = Vector2.ONE * DISPLAY_SCALE * shrink


func _finish_bounce() -> void:
	_state = PickupState.IDLE
	global_position.y = _floor_y
	if _sprite != null:
		_sprite.scale = Vector2.ONE * DISPLAY_SCALE
	set_process(true)


func _apply_visual() -> void:
	if _sprite == null:
		_sprite = get_node_or_null("Sprite2D") as Sprite2D
	if _sprite == null or item_data == null:
		return
	if item_data.icon != null:
		_sprite.texture = item_data.icon
	_sprite.scale = Vector2.ONE * DISPLAY_SCALE


func _find_player() -> Node2D:
	var players: Array[Node] = get_tree().get_nodes_in_group(&"player")
	if players.is_empty():
		return null
	return players[0] as Node2D


func _get_player_pickup_position() -> Vector2:
	if _player == null:
		return Vector2.ZERO

	var anchor: Node2D = _player.get_node_or_null("PickupAnchor") as Node2D
	if anchor != null:
		return anchor.global_position

	return _player.global_position + player_pickup_offset


func _try_collect() -> void:
	if _state == PickupState.COLLECTED:
		return
	if item_data == null or quantity <= 0:
		queue_free()
		return

	_state = PickupState.COLLECTED
	set_physics_process(false)
	set_process(false)

	var leftover: int = InventoryManager.add_item(item_data, quantity)
	if leftover < quantity:
		_play_collect_pop()
		return

	_state = PickupState.IDLE
	set_physics_process(true)
	set_process(true)


func _play_collect_pop() -> void:
	if _sprite == null:
		queue_free()
		return

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_sprite, "scale", Vector2.ZERO, 0.12)
	tween.tween_property(_sprite, "modulate:a", 0.0, 0.12)
	tween.chain().tween_callback(queue_free)


func _process(_delta: float) -> void:
	if _state != PickupState.IDLE:
		return

	_player = _find_player()
	if _player == null:
		return

	if global_position.distance_to(_get_player_pickup_position()) <= magnet_range:
		_state = PickupState.MAGNETIZED
		set_process(false)
		set_physics_process(true)
