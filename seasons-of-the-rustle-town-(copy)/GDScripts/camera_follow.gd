extends Camera2D

@export var follow_target_path: NodePath = NodePath("../YSort_Objects/Player")
@export var smoothing_speed: float = 5.0
@export var use_custom_bounds: bool = true
@export var world_bounds_min: Vector2 = Vector2(-500.0, -500.0)
@export var world_bounds_max: Vector2 = Vector2(1500.0, 1500.0)

var _follow_target: Node2D


func _ready() -> void:
	position_smoothing_enabled = true
	position_smoothing_speed = smoothing_speed
	_follow_target = get_node_or_null(follow_target_path) as Node2D

	if _follow_target == null:
		push_warning("CameraFollow: 未找到跟随目标 %s" % follow_target_path)


func _physics_process(_delta: float) -> void:
	if _follow_target == null:
		return

	var target_position: Vector2 = _follow_target.global_position

	if use_custom_bounds:
		target_position = target_position.clamp(world_bounds_min, world_bounds_max)

	global_position = target_position
