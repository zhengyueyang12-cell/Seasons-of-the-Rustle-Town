extends Node
class_name WeaponManager

signal weapon_equipped(weapon: WeaponResource)

@export var weapon_sprite_path: NodePath = NodePath("../Weapon/Sprite2D")
@export var default_weapon_id: StringName = &"rapier"

var current_weapon_id: StringName = &""
var damage_bonus: int = 0
var damage_multiplier: float = 1.0

var _weapon_sprite: Sprite2D
var _current_weapon: WeaponResource


func _ready() -> void:
	weapon_equipped.connect(_on_weapon_equipped_sync)
	call_deferred(&"_initialize")


func _initialize() -> void:
	_weapon_sprite = get_node_or_null(weapon_sprite_path) as Sprite2D
	if _weapon_sprite == null and get_parent() != null:
		_weapon_sprite = get_parent().get_node_or_null("Weapon/Sprite2D") as Sprite2D
	_restore_equipped_weapon()


func equip_weapon(weapon_id: StringName) -> void:
	var weapon: WeaponResource = WeaponRegistry.get_weapon(weapon_id)
	if weapon == null:
		push_warning("WeaponManager: 未找到武器 %s" % weapon_id)
		return

	current_weapon_id = weapon_id
	_current_weapon = weapon
	_apply_weapon_visual(weapon)
	weapon_equipped.emit(weapon)


func get_current_weapon() -> WeaponResource:
	return _current_weapon


func get_current_damage() -> int:
	if _current_weapon == null:
		return 0
	var total: float = (_current_weapon.damage + damage_bonus) * damage_multiplier
	return maxi(int(round(total)), 0)


func get_attack_speed() -> float:
	return _current_weapon.attack_speed if _current_weapon else 1.0


func get_crit_rate() -> float:
	return _current_weapon.crit_rate if _current_weapon else 0.05


func get_crit_damage() -> float:
	return _current_weapon.crit_damage if _current_weapon else 1.5


func get_knockback() -> float:
	return _current_weapon.knockback if _current_weapon else 50.0


func get_attack_range() -> float:
	return _current_weapon.range if _current_weapon else 0.0


func get_swing_angle() -> float:
	return _current_weapon.swing_angle if _current_weapon else 90.0


func get_swing_duration() -> float:
	return _current_weapon.swing_duration if _current_weapon else 0.2


func get_cooldown() -> float:
	return _current_weapon.cooldown if _current_weapon else 0.5


func hide_held_item() -> void:
	if _weapon_sprite != null:
		_weapon_sprite.texture = null
		_weapon_sprite.visible = false
	var weapon_root: Node2D = get_parent().get_node_or_null("Weapon") as Node2D
	if weapon_root != null:
		weapon_root.visible = false


func _on_weapon_equipped_sync(weapon: WeaponResource) -> void:
	GameState.set_equipped_weapon(weapon.id)


func _restore_equipped_weapon() -> void:
	var saved_id: StringName = GameState.current_weapon_id
	if saved_id != &"" and WeaponRegistry.has_weapon(saved_id):
		equip_weapon(saved_id)
	elif WeaponRegistry.has_weapon(default_weapon_id):
		equip_weapon(default_weapon_id)


func _apply_weapon_visual(weapon: WeaponResource) -> void:
	if _weapon_sprite == null:
		return

	var weapon_root: Node2D = get_parent().get_node_or_null("Weapon") as Node2D
	if weapon_root != null:
		weapon_root.visible = true

	if weapon.weapon_sprite != null:
		_weapon_sprite.texture = weapon.weapon_sprite
		_weapon_sprite.visible = true
	else:
		_weapon_sprite.texture = null
		_weapon_sprite.visible = false
