extends Node2D
class_name HeldItemVisual

## 根据人物朝向调整手持武器/工具的位置与水平翻转。

@export var animation_state_machine_path: NodePath = NodePath("../AnimationStateMachine")
@export var base_offset: Vector2 = Vector2(12, -8)
@export var up_offset: Vector2 = Vector2(8, -14)
@export var down_offset: Vector2 = Vector2(12, -4)

var _animation_state_machine: AnimationStateMachine
var _held_sprite: Sprite2D
var _base_x: float = 12.0


func _ready() -> void:
	_animation_state_machine = get_node_or_null(animation_state_machine_path) as AnimationStateMachine
	_held_sprite = get_node_or_null("Sprite2D") as Sprite2D
	_base_x = absf(base_offset.x)
	if _animation_state_machine != null:
		_animation_state_machine.direction_changed.connect(_on_direction_changed)
		_apply_facing(_animation_state_machine.last_non_idle_direction)
	_connect_equip_signals()


func refresh_facing() -> void:
	if _animation_state_machine == null:
		return
	_apply_facing(_animation_state_machine.last_non_idle_direction)


func _connect_equip_signals() -> void:
	var player: Node = get_parent()
	if player == null:
		return
	var weapon_manager: WeaponManager = player.get_node_or_null("WeaponManager") as WeaponManager
	var tool_manager: ToolManager = player.get_node_or_null("ToolManager") as ToolManager
	if weapon_manager != null:
		weapon_manager.weapon_equipped.connect(_on_item_equipped)
	if tool_manager != null:
		tool_manager.tool_equipped.connect(_on_item_equipped)


func _on_item_equipped(_item: ItemResource) -> void:
	refresh_facing()


func _on_direction_changed(direction: AnimationStateMachine.Direction) -> void:
	_apply_facing(direction)


func _apply_facing(direction: AnimationStateMachine.Direction) -> void:
	if _held_sprite == null:
		return

	match direction:
		AnimationStateMachine.Direction.LEFT:
			position = Vector2(-_base_x, base_offset.y)
			_held_sprite.flip_h = true
		AnimationStateMachine.Direction.RIGHT:
			position = Vector2(_base_x, base_offset.y)
			_held_sprite.flip_h = false
		AnimationStateMachine.Direction.UP:
			position = up_offset
			_held_sprite.flip_h = false
		AnimationStateMachine.Direction.DOWN:
			position = down_offset
			_held_sprite.flip_h = false
