extends Node

var _weapons: Dictionary = {}


func _ready() -> void:
	_register_default_weapons()


func register_weapon(weapon_id: StringName, weapon: WeaponResource) -> void:
	if weapon == null:
		push_warning("WeaponRegistry: 无法注册空武器")
		return
	weapon.id = weapon_id
	_weapons[weapon_id] = weapon


func get_weapon(weapon_id: StringName) -> WeaponResource:
	var weapon: Variant = _weapons.get(weapon_id)
	if weapon is WeaponResource:
		return weapon as WeaponResource
	return null


func get_all_weapons() -> Array[WeaponResource]:
	var result: Array[WeaponResource] = []
	for weapon: Variant in _weapons.values():
		if weapon is WeaponResource:
			result.append(weapon as WeaponResource)
	return result


func get_weapons_by_type(type: WeaponResource.WeaponType) -> Array[WeaponResource]:
	var result: Array[WeaponResource] = []
	for weapon: WeaponResource in get_all_weapons():
		if weapon.weapon_type == type:
			result.append(weapon)
	return result


func has_weapon(weapon_id: StringName) -> bool:
	return _weapons.has(weapon_id)


func _register_default_weapons() -> void:
	register_weapon(&"wooden_sword", _create_weapon(
		&"木剑",
		WeaponResource.WeaponType.MELEE,
		8,
		1.2,
		0.05
	))
	register_weapon(&"iron_sword", _create_weapon(
		&"铁剑",
		WeaponResource.WeaponType.MELEE,
		15,
		1.0,
		0.10
	))
	register_weapon(&"rapier", _create_rapier())
	register_weapon(&"greatsword", _create_greatsword())


func _create_weapon(
	display_name: String,
	weapon_type: WeaponResource.WeaponType,
	damage: int,
	attack_speed: float,
	crit_rate: float,
	crit_damage: float = 1.5,
	knockback: float = 50.0
) -> WeaponResource:
	var weapon: WeaponResource = WeaponResource.new()
	weapon.display_name = display_name
	weapon.weapon_type = weapon_type
	weapon.damage = damage
	weapon.attack_speed = attack_speed
	weapon.crit_rate = crit_rate
	weapon.crit_damage = crit_damage
	weapon.knockback = knockback
	weapon.max_stack = 1
	return weapon


func _create_rapier() -> WeaponResource:
	var weapon: WeaponResource = _create_weapon(
		&"细剑",
		WeaponResource.WeaponType.MELEE,
		12,
		1.5,
		0.15,
		1.8
	)
	var sprite_path: String = "res://sprites/runright-rapier.png"
	if ResourceLoader.exists(sprite_path):
		weapon.weapon_sprite = load(sprite_path) as Texture2D
		weapon.icon = weapon.weapon_sprite
	return weapon


func _create_greatsword() -> WeaponResource:
	return _create_weapon(
		&"巨剑",
		WeaponResource.WeaponType.MELEE,
		25,
		0.6,
		0.05,
		1.5,
		100.0
	)
