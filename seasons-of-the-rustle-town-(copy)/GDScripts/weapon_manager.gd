extends Node

signal weapon_equipped(weapon: WeaponResource)

@export var weapon_sprite_path: NodePath = ^"../Weapon/Sprite2D"
@export var default_weapon_id: StringName = &"rapier"

var current_weapon_id: StringName = &""
var damage_bonus: int = 0
var damage_multiplier: float = 1.0

var attack_speed: float = 1.0
var crit_rate: float = 0.05
var crit_damage: float = 1.5
var knockback: float = 50.0
var attack_range: float = 0.0
var swing_angle: float = 90.0
var swing_duration: float = 0.2
var cooldown: float = 0.5

var _weapon_sprite: Sprite2D
var _current_weapon: WeaponResource


func _ready() -> void:
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
	GameState.set_equipped_weapon(weapon_id)
	_apply_weapon_visual(weapon)
	_apply_weapon_stats(weapon)
	weapon_equipped.emit(weapon)


func get_current_weapon() -> WeaponResource:
	return _current_weapon


func get_current_damage() -> int:
	if _current_weapon == null:
		return 0
	var total: float = (_current_weapon.damage + damage_bonus) * damage_multiplier
	return maxi(int(round(total)), 0)


func _restore_equipped_weapon() -> void:
	var saved_id: StringName = GameState.current_weapon_id
	if saved_id != &"" and WeaponRegistry.has_weapon(saved_id):
		equip_weapon(saved_id)
	elif WeaponRegistry.has_weapon(default_weapon_id):
		equip_weapon(default_weapon_id)


func _apply_weapon_visual(weapon: WeaponResource) -> void:
	if _weapon_sprite == null:
		return

	if weapon.weapon_sprite != null:
		_weapon_sprite.texture = weapon.weapon_sprite
		_weapon_sprite.visible = true
	else:
		_weapon_sprite.texture = null
		_weapon_sprite.visible = false


func _apply_weapon_stats(weapon: WeaponResource) -> void:
	attack_speed = weapon.attack_speed
	crit_rate = weapon.crit_rate
	crit_damage = weapon.crit_damage
	knockback = weapon.knockback
	attack_range = weapon.range
	swing_angle = weapon.swing_angle
	swing_duration = weapon.swing_duration
	cooldown = weapon.cooldown
