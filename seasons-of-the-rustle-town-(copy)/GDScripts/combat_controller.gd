extends Node
class_name CombatController

@export var weapon_manager_path: NodePath = NodePath("../WeaponManager")
@export var equipment_controller_path: NodePath = NodePath("../EquipmentController")
@export var animation_state_machine_path: NodePath = NodePath("../AnimationStateMachine")

var _weapon_manager: WeaponManager
var _equipment_controller: EquipmentController
var _animation_state_machine: AnimationStateMachine
var _attack_cooldown_timer: float = 0.0


func _ready() -> void:
	_weapon_manager = get_node_or_null(weapon_manager_path) as WeaponManager
	_equipment_controller = get_node_or_null(equipment_controller_path) as EquipmentController
	_animation_state_machine = get_node_or_null(animation_state_machine_path) as AnimationStateMachine
	InputManager.melee_attack_pressed.connect(_on_melee_attack_pressed)


func _physics_process(delta: float) -> void:
	if _attack_cooldown_timer > 0.0:
		_attack_cooldown_timer -= delta


func _on_melee_attack_pressed() -> void:
	if _equipment_controller != null and _equipment_controller.is_tool_active:
		return
	if _weapon_manager == null or _animation_state_machine == null:
		return
	if _weapon_manager.get_current_weapon() == null:
		return
	if _attack_cooldown_timer > 0.0:
		return

	var cooldown: float = _weapon_manager.get_cooldown()
	var attack_speed: float = _weapon_manager.get_attack_speed()
	_attack_cooldown_timer = cooldown / maxf(attack_speed, 0.01)

	_animation_state_machine.attack(_weapon_manager.get_swing_duration())
