class_name TreeStump
extends StaticBody2D

## 树桩：砍伐后掉落木材与树液，然后消失。

signal stump_cleared(stump: TreeStump, global_pos: Vector2, was_on_farm: bool)

@export var tree_data: TreeResource

var chop_hits: int = 0
var player_planted: bool = false

var _sprite: Sprite2D
var _base_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	add_to_group(&"tree_stump")
	_sprite = get_node_or_null("Sprite2D") as Sprite2D
	if _sprite != null:
		_base_position = _sprite.position

	if tree_data == null:
		tree_data = load("res://resources/trees/oak_tree.tres") as TreeResource


func setup_from_tree(data: TreeResource, planted: bool = false) -> void:
	tree_data = data
	player_planted = planted


func is_in_chop_range(player_global_pos: Vector2) -> bool:
	if tree_data == null:
		return false
	return global_position.distance_to(player_global_pos) <= tree_data.chop_range


func take_chop_hit(player_global_pos: Vector2) -> bool:
	if tree_data == null:
		return false

	chop_hits += 1
	_play_hit_shake()

	if chop_hits < tree_data.stump_chops_required:
		return true

	_spawn_stump_loot()
	var on_farm: bool = TreeRegenerationService.is_position_on_farm(global_position)
	stump_cleared.emit(self, global_position, on_farm)
	if not on_farm:
		TreeRegenerationService.register_cleared_stump(global_position, tree_data)
	queue_free()
	return true


func _play_hit_shake() -> void:
	if _sprite == null or tree_data == null:
		return

	var strength: float = tree_data.hit_shake_strength * 0.6
	var duration: float = tree_data.hit_shake_duration
	var original: Vector2 = _base_position

	var tween: Tween = create_tween()
	tween.tween_property(_sprite, "position", original + Vector2(strength, 0), duration * 0.3)
	tween.tween_property(_sprite, "position", original, duration * 0.7)


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
