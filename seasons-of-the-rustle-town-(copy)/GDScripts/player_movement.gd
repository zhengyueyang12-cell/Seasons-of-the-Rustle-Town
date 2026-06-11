extends CharacterBody2D

signal movement_started()
signal movement_stopped()

@export var move_speed: float = 300.0

var is_moving: bool = false


func _physics_process(_delta: float) -> void:
	var direction: Vector2 = Input.get_vector(
		&"move_left", &"move_right", &"move_up", &"move_down"
	)

	if direction != Vector2.ZERO:
		direction = direction.normalized()

	velocity = direction * move_speed
	move_and_slide()

	_set_moving_state(direction != Vector2.ZERO)


func _set_moving_state(moving: bool) -> void:
	if moving == is_moving:
		return

	is_moving = moving
	if is_moving:
		movement_started.emit()
	else:
		movement_stopped.emit()
