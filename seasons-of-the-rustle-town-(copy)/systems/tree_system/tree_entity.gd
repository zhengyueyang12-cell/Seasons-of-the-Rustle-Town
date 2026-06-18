@tool
class_name TreeEntity
extends StaticBody2D

signal tree_felled(tree: TreeEntity, fall_direction: Vector2)
signal stump_cleared(tree: TreeEntity, global_pos: Vector2, was_on_farm: bool)
signal growth_stage_changed(new_stage: TreeResource.GrowthStage)

enum TreePhase { GROWING, STANDING, FELLING, FELLED_STUMP }
enum VisualState { IDLE, FALLING }

@export_group("树木配置")
@export var tree_data: TreeResource
@export var initial_stage: TreeResource.GrowthStage = TreeResource.GrowthStage.MATURE
@export var player_planted: bool = false

@export_group("砍伐判定")
@export var use_chop_marker: bool = true
@export var chop_range: float = 72.0

var growth_stage: TreeResource.GrowthStage = TreeResource.GrowthStage.SEED
var chop_hits: int = 0
var stump_chop_hits: int = 0
var growth_stalled: bool = false

var _visual: TreeVisual
var _collision: CollisionShape2D
var _chop_marker: Marker2D
var _phase: TreePhase = TreePhase.GROWING
var _visual_state: VisualState = VisualState.IDLE


func _ready() -> void:
	add_to_group(&"tree")
	_visual = get_node_or_null("TreeVisual") as TreeVisual
	_collision = get_node_or_null("CollisionShape2D") as CollisionShape2D
	_chop_marker = get_node_or_null("ChopMarker") as Marker2D

	if tree_data == null:
		tree_data = load("res://resources/trees/oak_tree.tres") as TreeResource

	if not Engine.is_editor_hint():
		if _visual != null:
			_visual.setup(tree_data, initial_stage)
			_visual.fall_finished.connect(_on_visual_fall_finished)
		TimeManager.season_changed.connect(_on_season_changed)
		set_growth_stage(initial_stage)
		_refresh_groups()
	elif _visual != null:
		_visual.setup(tree_data, initial_stage)


func set_growth_stage(stage: Variant) -> void:
	growth_stage = TreeResource.coerce_growth_stage(stage)
	if _visual != null:
		_visual.apply_stage(growth_stage)
	_update_collision_for_stage()

	if growth_stage == TreeResource.GrowthStage.MATURE:
		_phase = TreePhase.STANDING
	else:
		_phase = TreePhase.GROWING

	growth_stage_changed.emit(growth_stage)
	_refresh_groups()


func advance_growth_if_possible() -> void:
	if growth_stage >= TreeResource.GrowthStage.MATURE:
		return
	if _is_growth_stalled():
		growth_stalled = true
		return

	growth_stalled = false
	var next_stage: int = int(growth_stage) + 1
	set_growth_stage(next_stage)


func can_be_chopped() -> bool:
	if tree_data == null or _visual_state != VisualState.IDLE:
		return false
	if _phase == TreePhase.STANDING:
		return growth_stage == TreeResource.GrowthStage.MATURE
	if _phase == TreePhase.FELLED_STUMP:
		return true
	return false


func get_chop_global_position() -> Vector2:
	if use_chop_marker and _chop_marker != null:
		return _chop_marker.global_position

	var local_offset: Vector2 = Vector2.ZERO
	if tree_data != null:
		local_offset.y += tree_data.chop_anchor_offset_y
	return global_position + local_offset


func is_in_chop_range(player_global_pos: Vector2) -> bool:
	var range_value: float = chop_range if chop_range > 0.0 else 72.0
	if tree_data != null and chop_range <= 0.0:
		range_value = tree_data.chop_range
	return get_chop_global_position().distance_to(player_global_pos) <= range_value


func take_chop_hit(player_global_pos: Vector2) -> bool:
	if not can_be_chopped() or tree_data == null:
		return false

	if _phase == TreePhase.STANDING:
		return _take_standing_chop_hit(player_global_pos)
	if _phase == TreePhase.FELLED_STUMP:
		return _take_stump_chop_hit()

	return false


func get_map_cell() -> Vector2i:
	var tile_destructor: TileDestructor = get_tree().get_first_node_in_group(
		&"tile_destructor"
	) as TileDestructor
	if tile_destructor == null:
		return Vector2i.ZERO
	return tile_destructor.global_to_map(global_position)


func _take_standing_chop_hit(player_global_pos: Vector2) -> bool:
	chop_hits += 1
	if _visual != null:
		_visual.play_hit_shake()
	_spawn_hit_wood_drop()

	if chop_hits >= tree_data.chops_required:
		var fall_dir: Vector2 = (global_position - player_global_pos).normalized()
		if fall_dir == Vector2.ZERO:
			fall_dir = Vector2.UP
		_start_fall(fall_dir)

	return true


func _take_stump_chop_hit() -> bool:
	stump_chop_hits += 1
	if _visual != null:
		_visual.play_stump_shake()

	if stump_chop_hits < tree_data.stump_chops_required:
		return true

	_clear_stump()
	return true


func _start_fall(fall_direction: Vector2) -> void:
	if _visual == null or tree_data == null:
		return

	_phase = TreePhase.FELLING
	_visual_state = VisualState.FALLING
	_refresh_groups()
	_visual.start_fall(fall_direction)


func _on_visual_fall_finished(fall_direction: Vector2) -> void:
	_spawn_fall_loot(fall_direction)

	if _visual != null:
		_visual.enter_felled_state()

	_phase = TreePhase.FELLED_STUMP
	_visual_state = VisualState.IDLE
	stump_chop_hits = 0
	_update_collision_for_stump()
	_refresh_groups()
	tree_felled.emit(self, fall_direction)


func _clear_stump() -> void:
	_spawn_stump_loot()

	if _visual != null:
		_visual.play_stump_break()

	var on_farm: bool = TreeRegenerationService.is_position_on_farm(global_position)
	stump_cleared.emit(self, global_position, on_farm)
	if not on_farm:
		TreeRegenerationService.register_cleared_stump(global_position, tree_data)

	var break_delay: float = 0.22
	await get_tree().create_timer(break_delay).timeout
	queue_free()


func _on_season_changed(_new_season: TimeManager.Season) -> void:
	if _visual != null:
		_visual.refresh_season_texture()


func _update_collision_for_stage() -> void:
	if _collision == null or tree_data == null:
		return

	if _phase == TreePhase.FELLED_STUMP:
		_update_collision_for_stump()
		return

	var index: int = int(growth_stage) - 1
	var scale_factor: float = 1.0
	if growth_stage == TreeResource.GrowthStage.MATURE:
		scale_factor = 1.0
	elif tree_data.stage_scales.size() > index:
		scale_factor = tree_data.stage_scales[index]
	_collision.scale = Vector2(scale_factor, scale_factor)


func _update_collision_for_stump() -> void:
	if _collision == null:
		return
	_collision.scale = Vector2(0.65, 0.65)


func _spawn_hit_wood_drop() -> void:
	var wood: ItemResource = ItemRegistry.get_item(&"wood")
	var drops_parent: Node = _get_drops_parent()
	if wood != null and drops_parent != null:
		DropSpawner.spawn_near(drops_parent, wood, 1, global_position, 24.0)


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


func _spawn_stump_loot() -> void:
	if tree_data == null:
		return

	var drops_parent: Node = _get_drops_parent()
	if drops_parent == null:
		return

	var bonus: int = GameState.get_foraging_drop_bonus()
	var wood_item: ItemResource = ItemRegistry.get_item(&"wood")
	var sap_item: ItemResource = ItemRegistry.get_item(&"tree_sap")

	var wood_count: int = (
		randi_range(tree_data.stump_wood_min, tree_data.stump_wood_max) + bonus
	)
	if wood_item != null:
		DropSpawner.spawn_near(drops_parent, wood_item, wood_count, global_position, 36.0)
	if sap_item != null:
		DropSpawner.spawn_near(drops_parent, sap_item, tree_data.stump_sap_count, global_position, 20.0)


func _get_drops_parent() -> Node:
	var main: Node = get_tree().current_scene
	if main == null:
		return null
	return main.get_node_or_null("World/YSort_Objects/Drops")


func _refresh_groups() -> void:
	if _phase == TreePhase.STANDING:
		add_to_group(&"choppable_tree")
		remove_from_group(&"tree_stump")
	elif _phase == TreePhase.FELLED_STUMP:
		remove_from_group(&"choppable_tree")
		add_to_group(&"tree_stump")
	else:
		remove_from_group(&"choppable_tree")
		remove_from_group(&"tree_stump")


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
