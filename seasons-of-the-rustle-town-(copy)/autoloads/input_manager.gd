extends Node

signal movement_input(direction: Vector2)
signal interact_pressed()
signal inventory_toggled()
signal hotbar_selected(slot_index: int)
signal melee_attack_pressed()

var movement_direction: Vector2 = Vector2.ZERO


func _process(_delta: float) -> void:
	var direction: Vector2 = Input.get_vector(
		&"move_left", &"move_right", &"move_up", &"move_down"
	)
	if direction != movement_direction:
		movement_direction = direction
		movement_input.emit(movement_direction)

	if Input.is_action_just_pressed(&"open_inventory"):
		inventory_toggled.emit()
	if Input.is_action_just_pressed(&"interact"):
		interact_pressed.emit()
	if Input.is_action_just_pressed(&"melee_attack"):
		melee_attack_pressed.emit()
	if Input.is_action_just_pressed(&"hotbar1"):
		hotbar_selected.emit(0)
	if Input.is_action_just_pressed(&"hotbar2"):
		hotbar_selected.emit(1)
	if Input.is_action_just_pressed(&"hotbar3"):
		hotbar_selected.emit(2)
	if Input.is_action_just_pressed(&"hotbar4"):
		hotbar_selected.emit(3)
