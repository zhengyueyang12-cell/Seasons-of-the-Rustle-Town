extends Node

## 生态再生计时器：每晚处理农场扩散、野外树桩再生与树木生长。

const FARM_SEED_CHANCE: float = 0.15
const WILD_SPROUT_CHANCE: float = 0.20
const MATURE_SPREAD_RADIUS_TILES: int = 3
const TILE_SIZE: float = 32.0

var _farm_zones: Array[Area2D] = []
var _cleared_stump_spots: Array[Dictionary] = []

var _tree_scene: PackedScene = preload("res://Scenes/props/nature/tree.tscn")
var _oak_data: TreeResource = preload("res://resources/trees/oak_tree.tres")


func _ready() -> void:
	TimeManager.day_advanced.connect(_on_day_advanced)
	call_deferred(&"_cache_farm_zones")


func register_cleared_stump(global_pos: Vector2, tree_data: TreeResource) -> void:
	_cleared_stump_spots.append({
		"position": global_pos,
		"tree_data": tree_data,
	})


static func is_position_on_farm(global_pos: Vector2) -> bool:
	var service: Node = Engine.get_main_loop().root.get_node_or_null("/root/TreeRegenerationService")
	if service == null:
		return false
	return service._is_on_farm(global_pos)


func _cache_farm_zones() -> void:
	_farm_zones.clear()
	for node: Node in get_tree().get_nodes_in_group(&"farm_zone"):
		if node is Area2D:
			_farm_zones.append(node as Area2D)


func _on_day_advanced(_day: int, _season: TimeManager.Season, _year: int) -> void:
	_cache_farm_zones()
	_advance_all_tree_growth()
	_try_farm_seed_spread()
	_try_wild_sprout_regrowth()


func _advance_all_tree_growth() -> void:
	for node: Node in get_tree().get_nodes_in_group(&"tree"):
		if node is TreeEntity:
			(node as TreeEntity).advance_growth_if_possible()


func _try_farm_seed_spread() -> void:
	var tile_destructor: TileDestructor = get_tree().get_first_node_in_group(
		&"tile_destructor"
	) as TileDestructor
	if tile_destructor == null:
		return

	var trees_parent: Node2D = _get_trees_parent()
	if trees_parent == null:
		return

	for node: Node in get_tree().get_nodes_in_group(&"choppable_tree"):
		if not node is TreeEntity:
			continue
		var tree: TreeEntity = node as TreeEntity
		if not _is_on_farm(tree.global_position):
			continue

		var center_cell: Vector2i = tile_destructor.global_to_map(tree.global_position)
		for dy: int in range(-MATURE_SPREAD_RADIUS_TILES, MATURE_SPREAD_RADIUS_TILES + 1):
			for dx: int in range(-MATURE_SPREAD_RADIUS_TILES, MATURE_SPREAD_RADIUS_TILES + 1):
				if dx == 0 and dy == 0:
					continue
				if randf() > FARM_SEED_CHANCE:
					continue

				var cell: Vector2i = center_cell + Vector2i(dx, dy)
				if not _can_spawn_tree_at_cell(cell, tile_destructor):
					continue

				_spawn_tree_at_cell(
					trees_parent,
					cell,
					tile_destructor,
					TreeResource.GrowthStage.SEED,
					false
				)


func _try_wild_sprout_regrowth() -> void:
	var tile_destructor: TileDestructor = get_tree().get_first_node_in_group(
		&"tile_destructor"
	) as TileDestructor
	var trees_parent: Node2D = _get_trees_parent()
	if tile_destructor == null or trees_parent == null:
		return

	var remaining: Array[Dictionary] = []
	for spot: Dictionary in _cleared_stump_spots:
		var pos: Vector2 = spot.get("position", Vector2.ZERO)
		if _is_on_farm(pos):
			continue
		if randf() > WILD_SPROUT_CHANCE:
			remaining.append(spot)
			continue

		var cell: Vector2i = tile_destructor.global_to_map(pos)
		if not _can_spawn_tree_at_cell(cell, tile_destructor):
			remaining.append(spot)
			continue

		var data: TreeResource = spot.get("tree_data", _oak_data) as TreeResource
		_spawn_tree_at_cell(
			trees_parent,
			cell,
			tile_destructor,
			TreeResource.GrowthStage.SMALL,
			false,
			data
		)

	_cleared_stump_spots = remaining


func try_plant_seed_at(global_pos: Vector2) -> bool:
	if InventoryManager.get_item_count(&"tree_seed") <= 0:
		return false

	var tile_destructor: TileDestructor = get_tree().get_first_node_in_group(
		&"tile_destructor"
	) as TileDestructor
	var trees_parent: Node2D = _get_trees_parent()
	if tile_destructor == null or trees_parent == null:
		return false

	var cell: Vector2i = tile_destructor.global_to_map(global_pos)
	if not _is_tilled_cell(cell, tile_destructor):
		return false
	if not _can_spawn_tree_at_cell(cell, tile_destructor):
		return false

	if not InventoryManager.remove_item(&"tree_seed", 1):
		return false

	_spawn_tree_at_cell(
		trees_parent,
		cell,
		tile_destructor,
		TreeResource.GrowthStage.SEED,
		true
	)
	return true


func _spawn_tree_at_cell(
	parent: Node2D,
	cell: Vector2i,
	tile_destructor: TileDestructor,
	stage: TreeResource.GrowthStage,
	planted: bool,
	data: TreeResource = null
) -> void:
	if _tree_scene == null:
		return

	var tree: TreeEntity = _tree_scene.instantiate() as TreeEntity
	if tree == null:
		return

	parent.add_child(tree)
	tree.global_position = tile_destructor.map_to_global(cell)
	tree.tree_data = data if data != null else _oak_data
	tree.player_planted = planted
	tree.set_growth_stage(stage)


func _can_spawn_tree_at_cell(cell: Vector2i, tile_destructor: TileDestructor) -> bool:
	if _has_tree_at_cell(cell, tile_destructor):
		return false
	if not _is_grass_cell(cell, tile_destructor):
		return false
	return true


func _has_tree_at_cell(cell: Vector2i, tile_destructor: TileDestructor) -> bool:
	var world_pos: Vector2 = tile_destructor.map_to_global(cell)
	for node: Node in get_tree().get_nodes_in_group(&"tree"):
		if node is Node2D:
			var tree_pos: Vector2 = (node as Node2D).global_position
			if tree_pos.distance_to(world_pos) < TILE_SIZE * 0.6:
				return true
	for node: Node in get_tree().get_nodes_in_group(&"tree_stump"):
		if node is Node2D:
			var stump_pos: Vector2 = (node as Node2D).global_position
			if stump_pos.distance_to(world_pos) < TILE_SIZE * 0.6:
				return true
	return false


func _is_grass_cell(cell: Vector2i, tile_destructor: TileDestructor) -> bool:
	return tile_destructor.get_cell_terrain(cell) == tile_destructor.get_runtime_source_terrain_id()


func _is_tilled_cell(cell: Vector2i, tile_destructor: TileDestructor) -> bool:
	return tile_destructor.get_cell_terrain(cell) == tile_destructor.get_runtime_target_terrain_id()


func _is_on_farm(global_pos: Vector2) -> bool:
	for zone: Area2D in _farm_zones:
		if zone == null:
			continue
		var local: Vector2 = zone.to_local(global_pos)
		if _point_in_area(zone, local):
			return true
	return false


func _point_in_area(area: Area2D, local_point: Vector2) -> bool:
	for child: Node in area.get_children():
		if child is CollisionShape2D:
			var shape_node: CollisionShape2D = child as CollisionShape2D
			if shape_node.disabled or shape_node.shape == null:
				continue
			var shape: Shape2D = shape_node.shape
			var transform: Transform2D = shape_node.transform
			if shape is RectangleShape2D:
				var rect_shape: RectangleShape2D = shape as RectangleShape2D
				var half: Vector2 = rect_shape.size * 0.5
				var rect: Rect2 = Rect2(-half, rect_shape.size)
				return rect.has_point(transform * local_point)
			if shape is CircleShape2D:
				var circle: CircleShape2D = shape as CircleShape2D
				var center: Vector2 = transform * local_point
				return center.length() <= circle.radius
	return false


func _get_trees_parent() -> Node2D:
	var main: Node = get_tree().current_scene
	if main == null:
		return null
	return main.get_node_or_null("World/YSort_Objects/Trees") as Node2D
