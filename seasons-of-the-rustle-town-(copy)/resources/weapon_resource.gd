class_name WeaponResource
extends ItemResource

enum WeaponType { MELEE, RANGED, MAGIC }

@export var weapon_type: WeaponType = WeaponType.MELEE
@export var damage: int = 10
@export var attack_speed: float = 1.0
@export var crit_rate: float = 0.05
@export var crit_damage: float = 1.5
@export var knockback: float = 50.0
@export var range: float = 0.0
@export var swing_angle: float = 90.0
@export var swing_duration: float = 0.2
@export var cooldown: float = 0.5
@export var weapon_sprite: Texture2D
