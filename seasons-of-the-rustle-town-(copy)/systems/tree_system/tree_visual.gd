@tool
class_name TreeVisual
extends Node2D

signal fall_finished(fall_direction: Vector2)

enum Mode { GROWTH, MATURE, FALLING, FELLED }

@export_group("图集")
@export var atlas_key: String = "tree1"
@export var display_scale: float = 2.0
@export var body_region: Rect2i = Rect2i(0, 4, 48, 72)
@export var stump_stand_region: Rect2i = Rect2i(16, 144, 16, 16)
@export var body_join_overlap: int = 3
@export var stage_regions: Array[Rect2i] = [
	Rect2i(3, 131, 11, 9),
	Rect2i(5, 122, 8, 12),
	Rect2i(0, 97, 15, 29),
	Rect2i(0, 97, 15, 43),
	Rect2i(),
]
@export var leaf_regions: Array[Rect2i] = [
	Rect2i(16, 112, 5, 6),
	Rect2i(25, 114, 4, 4),
	Rect2i(18, 122, 5, 5),
	Rect2i(37, 134, 7, 6),
]

@export_group("落叶")
## 无 LeafEmitter 标记时的默认发射点（相对 TreeVisual 原点，Y 负值=树冠方向）
@export var leaf_spawn_offset: Vector2 = Vector2(0, -72)
## 发射随机散布：x=左右半宽，y=向上额外散布高度
@export var leaf_spawn_spread: Vector2 = Vector2(16, 24)

@export_group("编辑器预览")
@export var editor_preview_stage: TreeResource.GrowthStage = TreeResource.GrowthStage.MATURE:
	set(value):
		editor_preview_stage = value
		if Engine.is_editor_hint():
			_apply_editor_preview()

var _stump_sprite: Sprite2D
var _body_pivot: Node2D
var _body_sprite: Sprite2D
var _growth_sprite: Sprite2D
var _tree_data: TreeResource
var _cached_stage: TreeResource.GrowthStage = TreeResource.GrowthStage.MATURE
var _atlas: Texture2D
var _mode: Mode = Mode.GROWTH
var _fall_tween: Tween
var _shake_tween: Tween
var _root_base: Vector2 = Vector2.ZERO
var _body_pivot_base: Vector2 = Vector2.ZERO
var _stump_base: Vector2 = Vector2.ZERO


func _ready() -> void:
	_stump_sprite = get_node_or_null("StumpSprite") as Sprite2D
	_body_pivot = get_node_or_null("BodyPivot") as Node2D
	_body_sprite = get_node_or_null("BodyPivot/BodySprite") as Sprite2D
	_growth_sprite = get_node_or_null("GrowthSprite") as Sprite2D

	if Engine.is_editor_hint():
		_apply_editor_preview()


func setup(data: TreeResource, stage: TreeResource.GrowthStage) -> void:
	_tree_data = data
	_sync_from_tree_data()
	_refresh_atlas_texture()
	apply_stage(stage)


func refresh_season_texture() -> void:
	_refresh_atlas_texture()
	apply_stage(_cached_stage)


func apply_stage(stage: Variant) -> void:
	if _atlas == null and not Engine.is_editor_hint():
		return

	var growth_stage: TreeResource.GrowthStage = TreeResource.coerce_growth_stage(stage)
	_cached_stage = growth_stage

	if _tree_data != null and not Engine.is_editor_hint():
		_tree_data.growth_stage_cached = int(growth_stage)

	if growth_stage == TreeResource.GrowthStage.MATURE:
		_show_mature()
	else:
		_show_growth_stage(growth_stage)


func play_hit_shake() -> void:
	if _tree_data == null:
		return

	var strength: float = _tree_data.hit_shake_strength
	var duration: float = _tree_data.hit_shake_duration
	_shake_node(self, _root_base, strength, duration)
	_spawn_leaf_burst(3)


func play_stump_shake() -> void:
	if _tree_data == null:
		return

	var strength: float = _tree_data.hit_shake_strength * 0.6
	var duration: float = _tree_data.hit_shake_duration
	_shake_node(self, _root_base, strength, duration)


func play_stump_break() -> void:
	if _stump_sprite == null:
		return

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_stump_sprite, "scale", _stump_sprite.scale * 0.6, 0.18)
	tween.tween_property(_stump_sprite, "modulate:a", 0.0, 0.22)


func start_fall(fall_direction: Vector2) -> void:
	if _body_pivot == null or _body_sprite == null:
		fall_finished.emit(fall_direction)
		return

	_mode = Mode.FALLING
	_hide_growth()

	if _fall_tween != null and _fall_tween.is_valid():
		_fall_tween.kill()

	var fall_angle: float = fall_direction.angle() + PI * 0.5
	var duration: float = _tree_data.fall_duration if _tree_data != null else 0.55

	_fall_tween = create_tween()
	_fall_tween.tween_property(_body_pivot, "rotation", fall_angle, duration).set_ease(
		Tween.EASE_IN
	).set_trans(Tween.TRANS_QUAD)
	_fall_tween.chain().tween_callback(_on_fall_done.bind(fall_direction))
	_spawn_leaf_burst(8)


func enter_felled_state() -> void:
	_mode = Mode.FELLED
	_hide_growth()

	if _body_pivot != null:
		_body_pivot.visible = false
		_body_pivot.rotation = 0.0

	if _body_sprite != null:
		_body_sprite.visible = false
		_body_sprite.modulate.a = 1.0

	if _stump_sprite != null:
		_stump_sprite.visible = true
		_apply_sprite_region(_stump_sprite, stump_stand_region)
		_stump_sprite.position = _stump_base
		_stump_sprite.modulate.a = 1.0


func get_body_pivot_global_position() -> Vector2:
	return global_position + _body_pivot_base


func _show_mature() -> void:
	_mode = Mode.MATURE
	_hide_growth()
	_recompute_layout_positions()

	if _stump_sprite != null:
		_stump_sprite.visible = true
		_apply_sprite_region(_stump_sprite, stump_stand_region)
		_stump_sprite.position = _stump_base
		_stump_sprite.modulate.a = 1.0

	if _body_pivot != null:
		_body_pivot.visible = true
		_body_pivot.position = _body_pivot_base
		_body_pivot.rotation = 0.0

	if _body_sprite != null:
		_body_sprite.visible = true
		_apply_sprite_region(_body_sprite, body_region)
		_body_sprite.modulate.a = 1.0
		_body_sprite.position = _body_sprite_offset()


func _show_growth_stage(stage: TreeResource.GrowthStage) -> void:
	_mode = Mode.GROWTH
	if _stump_sprite != null:
		_stump_sprite.visible = false
	if _body_pivot != null:
		_body_pivot.visible = false

	var index: int = int(stage) - 1
	if _growth_sprite == null or stage_regions.size() <= index:
		return

	var region: Rect2i = stage_regions[index]
	if region.size == Vector2i.ZERO:
		_show_mature()
		return

	_growth_sprite.visible = true
	_apply_sprite_region(_growth_sprite, region)
	var stage_scale: float = display_scale
	if _tree_data != null and _tree_data.stage_scales.size() > index:
		stage_scale = display_scale * _tree_data.stage_scales[index]
	_growth_sprite.scale = Vector2.ONE * stage_scale
	_growth_sprite.position = _growth_anchor(region, stage_scale)


func _sync_from_tree_data() -> void:
	if _tree_data == null:
		return
	if atlas_key.is_empty():
		atlas_key = _tree_data.atlas_key


func _refresh_atlas_texture() -> void:
	var season: TimeManager.Season = (
		TimeManager.Season.SPRING if Engine.is_editor_hint() else TimeManager.current_season
	)
	_atlas = TreeAtlasUtil.load_season_atlas(atlas_key, season)


func _recompute_layout_positions() -> void:
	var stump_h: float = float(stump_stand_region.size.y) * display_scale
	_stump_base = Vector2(0.0, -stump_h * 0.5)
	_body_pivot_base = Vector2(0.0, -stump_h)


func _body_sprite_offset() -> Vector2:
	var body_h: float = float(body_region.size.y) * display_scale
	var overlap: float = float(body_join_overlap) * display_scale
	return Vector2(0.0, -body_h * 0.5 + overlap)


func _growth_anchor(region: Rect2i, stage_scale: float) -> Vector2:
	return Vector2(0.0, -float(region.size.y) * stage_scale * 0.5)


func _apply_sprite_region(sprite: Sprite2D, region: Rect2i) -> void:
	if sprite == null or region.size == Vector2i.ZERO:
		return
	if _atlas != null:
		sprite.texture = TreeAtlasUtil.region_texture(_atlas, region)
	sprite.scale = Vector2.ONE * display_scale


func _apply_editor_preview() -> void:
	_refresh_atlas_texture()
	apply_stage(editor_preview_stage)


func _hide_growth() -> void:
	if _growth_sprite != null:
		_growth_sprite.visible = false


func _shake_node(node: Node2D, original: Vector2, strength: float, duration: float) -> void:
	if node == null:
		return
	if node == self and _shake_tween != null and _shake_tween.is_valid():
		_shake_tween.kill()

	node.position = original
	var tween: Tween = node.create_tween()
	if node == self:
		_shake_tween = tween

	tween.tween_property(node, "position", original + Vector2(strength, 0), duration * 0.25)
	tween.tween_property(
		node, "position", original + Vector2(-strength * 0.6, strength * 0.3), duration * 0.25
	)
	tween.tween_property(node, "position", original, duration * 0.5)


func _get_leaf_spawn_position() -> Vector2:
	var emitter: Marker2D = get_parent().get_node_or_null("LeafEmitter") as Marker2D
	if emitter != null:
		return emitter.global_position
	return global_position + leaf_spawn_offset


func _spawn_leaf_burst(count: int) -> void:
	if _atlas == null or leaf_regions.is_empty():
		return

	var parent_node: Node = get_parent()
	if parent_node == null:
		return

	var spawn_origin: Vector2 = _get_leaf_spawn_position()

	for _i: int in count:
		var region: Rect2i = leaf_regions[randi() % leaf_regions.size()]
		var leaf := Sprite2D.new()
		leaf.texture = TreeAtlasUtil.region_texture(_atlas, region)
		leaf.scale = Vector2.ONE * display_scale
		leaf.z_index = 4
		parent_node.add_child(leaf)
		leaf.global_position = spawn_origin + Vector2(
			randf_range(-leaf_spawn_spread.x, leaf_spawn_spread.x),
			randf_range(-leaf_spawn_spread.y, 0.0)
		)

		var drift: Vector2 = Vector2(randf_range(-1.0, 1.0), randf_range(0.6, 1.2)).normalized()
		var tween: Tween = leaf.create_tween()
		tween.set_parallel(true)
		tween.tween_property(leaf, "global_position", leaf.global_position + drift * 28.0, 0.55)
		tween.tween_property(leaf, "modulate:a", 0.0, 0.55)
		tween.chain().tween_callback(leaf.queue_free)


func _on_fall_done(fall_direction: Vector2) -> void:
	fall_finished.emit(fall_direction)
