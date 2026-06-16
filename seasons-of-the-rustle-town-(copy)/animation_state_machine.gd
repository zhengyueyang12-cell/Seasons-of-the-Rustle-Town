extends Node
class_name AnimationStateMachine

enum State {
	IDLE,
	WALKING,
	ATTACKING  # 预留攻击状态
}

enum Direction {
	DOWN,
	UP,
	LEFT,
	RIGHT
}

signal direction_changed(new_direction: Direction)

@export var player: CharacterBody2D  # 拖入 Player 节点
@export var animated_sprite: AnimatedSprite2D  # 拖入 AnimatedSprite2D

var current_state: State = State.IDLE
var current_direction: Direction = Direction.DOWN
var last_non_idle_direction: Direction = Direction.DOWN

func _ready():
	if not animated_sprite:
		animated_sprite = player.get_node("AnimatedSprite2D")
	play_animation()

func update_state(velocity: Vector2) -> void:
	var new_state: State = State.WALKING if velocity != Vector2.ZERO else State.IDLE
	var new_direction: Direction = get_direction_from_velocity(velocity)
	var previous_facing: Direction = last_non_idle_direction

	if new_state == State.WALKING:
		current_direction = new_direction
		last_non_idle_direction = current_direction
	elif new_state == State.IDLE:
		current_direction = last_non_idle_direction

	if last_non_idle_direction != previous_facing:
		direction_changed.emit(last_non_idle_direction)

	if new_state != current_state or new_direction != current_direction:
		current_state = new_state
		play_animation()

func get_direction_from_velocity(velocity: Vector2) -> Direction:
	if velocity == Vector2.ZERO:
		return current_direction
	
	if abs(velocity.x) > abs(velocity.y):
		return Direction.RIGHT if velocity.x > 0 else Direction.LEFT
	else:
		return Direction.DOWN if velocity.y > 0 else Direction.UP

func play_animation():
	var anim_name = get_animation_name()
	
	if animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.play(anim_name)
		
		# 如果是空闲状态且播放的是行走动画，暂停在第一帧
		if current_state == State.IDLE and anim_name.begins_with("walk"):
			animated_sprite.stop()
			animated_sprite.frame = 0

func get_animation_name() -> String:
	match current_state:
		State.WALKING:
			match current_direction:
				Direction.DOWN:
					return "walkdown"
				Direction.UP:
					return "walkup"
				Direction.LEFT:
					return "walkleft"
				Direction.RIGHT:
					return "walkright"
		State.IDLE:
			# 使用 default 或根据方向使用不同 idle
			return "default"
		State.ATTACKING:
			return "attack_" + get_direction_string(current_direction)
	
	return "default"

func get_direction_string(dir: Direction) -> String:
	match dir:
		Direction.DOWN: return "down"
		Direction.UP: return "up"
		Direction.LEFT: return "left"
		Direction.RIGHT: return "right"
	return "down"

# 供外部调用的方法
func attack(fallback_duration: float = 0.2) -> void:
	if current_state == State.ATTACKING:
		return

	var previous_state: State = current_state
	current_state = State.ATTACKING
	var anim_name: String = get_animation_name()

	if animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.play(anim_name)
		await animated_sprite.animation_finished
	else:
		await get_tree().create_timer(fallback_duration).timeout

	current_state = previous_state
	play_animation()

func set_flip_h(flip: bool):
	animated_sprite.flip_h = flip
