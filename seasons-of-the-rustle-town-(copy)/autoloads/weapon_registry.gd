extends Node

const WEAPONS_DIR: String = "res://resources/weapons/"

var _weapons: Dictionary = {}


func _ready() -> void:
	_load_weapons_from_directory()


func register_weapon(weapon_id: StringName, weapon: WeaponResource) -> void:
	if weapon == null:
		push_warning("WeaponRegistry: 无法注册空武器")
		return
	weapon.id = weapon_id
	_weapons[weapon_id] = weapon
	ItemRegistry.register_item(weapon)


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


func _load_weapons_from_directory() -> void:
	var dir: DirAccess = DirAccess.open(WEAPONS_DIR)
	if dir == null:
		push_warning("WeaponRegistry: 无法打开武器目录 %s" % WEAPONS_DIR)
		return

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var path: String = WEAPONS_DIR + file_name
			var resource: Resource = load(path)
			if resource is WeaponResource:
				var weapon: WeaponResource = resource as WeaponResource
				if weapon.id == &"":
					push_warning("WeaponRegistry: %s 缺少 id" % path)
				else:
					register_weapon(weapon.id, weapon)
			else:
				push_warning("WeaponRegistry: %s 不是 WeaponResource" % path)
		file_name = dir.get_next()
	dir.list_dir_end()
