extends CharacterBody2D

signal movement_started()
signal movement_stopped()

@export var move_speed: float = 300.0

var is_moving: bool = false

# 获取状态机节点
@onready var animation_state_machine = $AnimationStateMachine


func _physics_process(_delta: float) -> void:
	var direction: Vector2 = Input.get_vector(
		&"move_left", &"move_right", &"move_up", &"move_down"
	)

	if direction != Vector2.ZERO:
		direction = direction.normalized()

	velocity = direction * move_speed
	move_and_slide()

	var moving = direction != Vector2.ZERO
	_set_moving_state(moving)
	
	# 更新动画状态机（传递速度向量，而不是布尔值）
	animation_state_machine.update_state(velocity)


func _set_moving_state(moving: bool) -> void:
	if moving == is_moving:
		return

	is_moving = moving
	if is_moving:
		movement_started.emit()
	else:
		movement_stopped.emit()
