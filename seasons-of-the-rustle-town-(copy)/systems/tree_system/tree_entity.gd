class_name TreeEntity
extends StaticBody2D

## 树木实体：五阶段生长、受击震动、倒下动画与树桩生成。

signal tree_felled(tree: TreeEntity, fall_direction: Vector2)
signal growth_stage_changed(new_stage: TreeResource.GrowthStage)

enum VisualState { IDLE, HIT_SHAKE, FALLING }

@export var tree_data: TreeResource
@export var initial_stage: TreeResource.GrowthStage = TreeResource.GrowthStage.MATURE
@export var player_planted: bool = false

var growth_stage: TreeResource.GrowthStage = TreeResource.GrowthStage.SEED
var chop_hits: int = 0
var growth_stalled: bool = false

var _sprite: Sprite2D
var _collision: CollisionShape2D
var _visual_state: VisualState = VisualState.IDLE
var _base_sprite_position: Vector2 = Vector2.ZERO
var _shake_tween: Tween
var _fall_tween: Tween


func _ready() -> void:
	add_to_group(&"tree")
	_sprite = get_node_or_null("Sprite2D") as Sprite2D
	_collision = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if _sprite != null:
		_base_sprite_position = _sprite.position

	if tree_data == null:
		tree_data = load("res://resources/trees/oak_tree.tres") as TreeResource

	set_growth_stage(initial_stage)
	_refresh_choppable_group()


func set_growth_stage(stage: TreeResource.GrowthStage) -> void:
	growth_stage = stage
	_update_sprite_for_stage()
	growth_stage_changed.emit(growth_stage)
	_refresh_choppable_group()


func advance_growth_if_possible() -> void:
	if growth_stage >= TreeResource.GrowthStage.MATURE:
		return
	if _is_growth_stalled():
		growth_stalled = true
		return

	growth_stalled = false
	var next_stage: int = int(growth_stage) + 1
	set_growth_stage(next_stage as TreeResource.GrowthStage)


func can_be_chopped() -> bool:
	return growth_stage == TreeResource.GrowthStage.MATURE and _visual_state == VisualState.IDLE


func is_in_chop_range(player_global_pos: Vector2) -> bool:
	if tree_data == null:
		return false
	return global_position.distance_to(player_global_pos) <= tree_data.chop_range


func take_chop_hit(player_global_pos: Vector2) -> bool:
	if not can_be_chopped() or tree_data == null:
		return false
	if _visual_state != VisualState.IDLE:
		return false

	chop_hits += 1
	_play_hit_shake()
	_spawn_hit_wood_drop()

	if chop_hits >= tree_data.chops_required:
		var fall_dir: Vector2 = (global_position - player_global_pos).normalized()
		if fall_dir == Vector2.ZERO:
			fall_dir = Vector2.UP
		_start_fall(fall_dir)
	else:
		return true

	return true


func get_map_cell() -> Vector2i:
	var tile_destructor: TileDestructor = get_tree().get_first_node_in_group(
		&"tile_destructor"
	) as TileDestructor
	if tile_destructor == null:
		return Vector2i.ZERO
	return tile_destructor.global_to_map(global_position)


func _update_sprite_for_stage() -> void:
	if _sprite == null or tree_data == null:
		return

	var index: int = int(growth_stage) - 1
	if tree_data.stage_textures.size() > index:
		_sprite.texture = tree_data.stage_textures[index]
	elif tree_data.stage_textures.size() > 0:
		_sprite.texture = tree_data.stage_textures[0]

	if tree_data.stage_scales.size() > index:
		_sprite.scale = Vector2.ONE * tree_data.stage_scales[index]
	elif tree_data.stage_scales.size() > 0:
		_sprite.scale = Vector2.ONE * tree_data.stage_scales[0]

	# 碰撞随阶段缩放
	if _collision != null and tree_data.stage_scales.size() > index:
		var scale_factor: float = tree_data.stage_scales[index]
		_collision.scale = Vector2(scale_factor, scale_factor)


func _play_hit_shake() -> void:
	if _sprite == null or tree_data == null:
		return

	_visual_state = VisualState.HIT_SHAKE
	if _shake_tween != null and _shake_tween.is_valid():
		_shake_tween.kill()

	var strength: float = tree_data.hit_shake_strength
	var duration: float = tree_data.hit_shake_duration
	var original: Vector2 = _base_sprite_position

	_shake_tween = create_tween()
	_shake_tween.tween_property(
		_sprite, "position", original + Vector2(strength, 0), duration * 0.25
	)
	_shake_tween.tween_property(
		_sprite, "position", original + Vector2(-strength, strength * 0.5), duration * 0.25
	)
	_shake_tween.tween_property(_sprite, "position", original, duration * 0.5)
	_shake_tween.finished.connect(_on_hit_shake_finished, CONNECT_ONE_SHOT)


func _on_hit_shake_finished() -> void:
	if _visual_state == VisualState.HIT_SHAKE:
		_visual_state = VisualState.IDLE


func _spawn_hit_wood_drop() -> void:
	var wood: ItemResource = ItemRegistry.get_item(&"wood")
	var drops_parent: Node = _get_drops_parent()
	if wood != null and drops_parent != null:
		DropSpawner.spawn_near(drops_parent, wood, 1, global_position, 24.0)


func _start_fall(fall_direction: Vector2) -> void:
	if _sprite == null or tree_data == null:
		return

	_visual_state = VisualState.FALLING
	remove_from_group(&"choppable_tree")

	if _fall_tween != null and _fall_tween.is_valid():
		_fall_tween.kill()

	var fall_angle: float = fall_direction.angle() + PI * 0.5
	var duration: float = tree_data.fall_duration

	_fall_tween = create_tween()
	_fall_tween.set_parallel(true)
	_fall_tween.tween_property(_sprite, "rotation", fall_angle, duration).set_ease(
		Tween.EASE_IN
	)
	_fall_tween.tween_property(
		_sprite, "modulate:a", 0.0, duration * 0.35
	).set_delay(duration * 0.65)
	_fall_tween.chain().tween_callback(_on_fall_finished.bind(fall_direction))


func _on_fall_finished(fall_direction: Vector2) -> void:
	_spawn_fall_loot(fall_direction)
	_spawn_stump()
	tree_felled.emit(self, fall_direction)
	queue_free()


func _spawn_fall_loot(fall_direction: Vector2) -> void:
	if tree_data == null:
		return

	var drops_parent: Node = _get_drops_parent()
	if drops_parent == null:
		return

	var bonus: int = GameState.get_foraging_drop_bonus()
	var wood_item: ItemResource = ItemRegistry.get_item(&"wood")
	var sap_item: ItemResource = ItemRegistry.get_item(&"tree_sap")
	var seed_item: ItemResource = ItemRegistry.get_item(&"tree_seed")

	var wood_count: int = randi_range(tree_data.fall_wood_min, tree_data.fall_wood_max) + bonus
	var sap_count: int = tree_data.fall_sap_count
	var seed_count: int = randi_range(tree_data.fall_seed_min, tree_data.fall_seed_max)
	if GameState.roll_luck_bonus():
		seed_count += 1

	if wood_item != null:
		DropSpawner.spawn_scattered(
			drops_parent, wood_item, wood_count, global_position, fall_direction
		)
	if sap_item != null:
		DropSpawner.spawn_scattered(
			drops_parent, sap_item, sap_count, global_position, fall_direction, 72.0, 48.0
		)
	if seed_item != null and seed_count > 0:
		DropSpawner.spawn_scattered(
			drops_parent, seed_item, seed_count, global_position, fall_direction, 56.0, 40.0
		)


func _spawn_stump() -> void:
	var stump_scene: PackedScene = load("res://Scenes/props/nature/tree_stump.tscn") as PackedScene
	if stump_scene == null:
		return

	var parent_node: Node = get_parent()
	if parent_node == null:
		return

	var stump: Node2D = stump_scene.instantiate() as Node2D
	parent_node.add_child(stump)
	stump.global_position = global_position
	if stump.has_method(&"setup_from_tree"):
		stump.setup_from_tree(tree_data, player_planted)


func _get_drops_parent() -> Node:
	var main: Node = get_tree().current_scene
	if main == null:
		return null
	return main.get_node_or_null("World/YSort_Objects/Drops")


func _refresh_choppable_group() -> void:
	if growth_stage == TreeResource.GrowthStage.MATURE:
		add_to_group(&"choppable_tree")
	else:
		remove_from_group(&"choppable_tree")


func _is_growth_stalled() -> bool:
	var mature_radius: float = 8.0 * 32.0
	for node: Node in get_tree().get_nodes_in_group(&"choppable_tree"):
		if node == self:
			continue
		if node is Node2D:
			var other: Node2D = node as Node2D
			if global_position.distance_to(other.global_position) <= mature_radius:
				return true
	return false
