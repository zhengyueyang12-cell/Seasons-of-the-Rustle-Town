extends Node
class_name ToolController

@export var tool_manager_path: NodePath = NodePath("../ToolManager")
@export var equipment_controller_path: NodePath = NodePath("../EquipmentController")
@export var animation_state_machine_path: NodePath = NodePath("../AnimationStateMachine")
@export var plant_use_range: float = 96.0

var _tool_manager: ToolManager
var _equipment_controller: EquipmentController
var _animation_state_machine: AnimationStateMachine
var _tile_destructor: TileDestructor
var _use_cooldown_timer: float = 0.0


func _ready() -> void:
	_tool_manager = get_node_or_null(tool_manager_path) as ToolManager
	_equipment_controller = get_node_or_null(equipment_controller_path) as EquipmentController
	_animation_state_machine = get_node_or_null(animation_state_machine_path) as AnimationStateMachine
	_tile_destructor = get_tree().get_first_node_in_group(&"tile_destructor") as TileDestructor
	InputManager.interact_pressed.connect(_on_interact_pressed)
	InputManager.melee_attack_pressed.connect(_on_melee_attack_pressed)


func _physics_process(delta: float) -> void:
	if _use_cooldown_timer > 0.0:
		_use_cooldown_timer -= delta


func _on_interact_pressed() -> void:
	if _use_cooldown_timer > 0.0:
		return

	var target_pos: Vector2 = _get_interact_target_position()

	if CropService.try_harvest_at(target_pos):
		_use_cooldown_timer = 0.25
		return

	if _equipment_controller != null and not _equipment_controller.is_tool_active:
		return
	if _tool_manager == null or not _tool_manager.has_tool():
		return

	var tool: ToolResource = _tool_manager.get_current_tool()
	if tool == null:
		return

	if _try_plant_tree_seed():
		return


func _on_melee_attack_pressed() -> void:
	if _use_cooldown_timer > 0.0:
		return

	var seed: SeedResource = _get_seed_from_active_hotbar()
	if seed != null:
		if _equipment_controller == null:
			return
		if CropService.try_plant_at(
			_get_plant_target_position(),
			seed,
			_equipment_controller.active_hotbar_index
		):
			_use_cooldown_timer = 0.35
		return

	if _equipment_controller == null or not _equipment_controller.is_tool_active:
		return
	if _tool_manager == null or not _tool_manager.has_tool():
		return

	var tool: ToolResource = _tool_manager.get_current_tool()
	if tool == null:
		return

	match tool.tool_type:
		ToolResource.ToolType.HOE, ToolResource.ToolType.PICKAXE:
			_use_tool_at_mouse(tool)
		ToolResource.ToolType.AXE:
			if not GameState.use_energy(tool.energy_cost):
				return
			_use_cooldown_timer = tool.use_cooldown
			_try_chop_tree(tool)


func _use_tool_at_mouse(tool: ToolResource) -> void:
	if _tile_destructor == null:
		push_warning("ToolController: 场景中未找到 tile_destructor 组节点")
		return
	if not GameState.use_energy(tool.energy_cost):
		return

	var player: Node2D = get_parent() as Node2D
	if player == null:
		return

	var target_pos: Vector2 = FarmToolTarget.get_clamped_world_position(player, tool.use_range)
	_tile_destructor.destroy_tile_at_position(target_pos, tool.effect_radius)
	_use_cooldown_timer = tool.use_cooldown


func _try_chop_tree(tool: ToolResource) -> void:
	var player: Node2D = get_parent() as Node2D
	if player == null:
		return

	var facing: Vector2 = _get_facing_direction()
	var target: Node = TreeChopDetector.find_chop_target(player, facing, tool.use_range)
	if target == null:
		return

	if target.has_method(&"take_chop_hit"):
		target.take_chop_hit(player.global_position)


func _try_plant_tree_seed() -> bool:
	if InventoryManager.get_item_count(&"tree_seed") <= 0:
		return false

	var player: Node2D = get_parent() as Node2D
	if player == null or _tool_manager == null:
		return false

	var tool: ToolResource = _tool_manager.get_current_tool()
	if tool == null:
		return false

	var plant_pos: Vector2 = FarmToolTarget.get_clamped_world_position(player, tool.use_range)
	return TreeRegenerationService.try_plant_seed_at(plant_pos)


func _get_seed_from_active_hotbar() -> SeedResource:
	if _equipment_controller == null:
		return null
	if _equipment_controller.active_hotbar_index < 0:
		return null

	var slot: ItemSlotData = HotbarManager.get_slot(
		_equipment_controller.active_hotbar_index
	)
	if slot == null or slot.is_empty:
		return null
	if slot.item is SeedResource:
		return slot.item as SeedResource
	return null


func _get_interact_target_position() -> Vector2:
	var player: Node2D = get_parent() as Node2D
	if player == null:
		return Vector2.ZERO

	var use_range: float = 48.0
	if _tool_manager != null and _tool_manager.has_tool():
		var tool: ToolResource = _tool_manager.get_current_tool()
		if tool != null:
			use_range = tool.use_range
	return FarmToolTarget.get_clamped_world_position(player, use_range)


func _get_plant_target_position() -> Vector2:
	var player: Node2D = get_parent() as Node2D
	if player == null:
		return Vector2.ZERO
	return FarmToolTarget.get_clamped_world_position(player, plant_use_range)


func _get_facing_direction() -> Vector2:
	if _animation_state_machine == null:
		return Vector2.DOWN

	match _animation_state_machine.last_non_idle_direction:
		AnimationStateMachine.Direction.LEFT:
			return Vector2.LEFT
		AnimationStateMachine.Direction.RIGHT:
			return Vector2.RIGHT
		AnimationStateMachine.Direction.UP:
			return Vector2.UP
		_:
			return Vector2.DOWN
