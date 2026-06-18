class_name TreeResource
extends Resource

## 树木数据：图集拼接、五阶段生长、砍伐阈值与掉落配置。

enum GrowthStage {
	SEED = 1,
	SPROUT = 2,
	SMALL = 3,
	MEDIUM = 4,
	MATURE = 5,
}

@export var id: StringName = &"oak"
@export var display_name: String = "橡树"
## 对应 TerrainFeatures 图集前缀：tree1 / tree2 / tree3 / tree_palm
@export var atlas_key: String = "tree1"
@export var display_scale: float = 2.0
@export var stage_scales: Array[float] = [0.55, 0.7, 0.85, 1.0, 1.0]
@export var chops_required: int = 5
@export var chop_range: float = 72.0
## 砍伐判定点额外上移（负值=更高），在自动计算的树干位置基础上微调
@export var chop_anchor_offset_y: float = 0.0
@export var interaction_radius: float = 40.0

@export var fall_wood_min: int = 12
@export var fall_wood_max: int = 16
@export var fall_sap_count: int = 5
@export var fall_seed_min: int = 0
@export var fall_seed_max: int = 2

@export var stump_wood_min: int = 4
@export var stump_wood_max: int = 9
@export var stump_sap_count: int = 1
@export var stump_chops_required: int = 2

@export var fall_duration: float = 0.55
@export var hit_shake_strength: float = 6.0
@export var hit_shake_duration: float = 0.12

## 运行时缓存的生长阶段（以 int 存储，兼容 Godot 4.7 枚举序列化）。
var growth_stage_cached: int = GrowthStage.MATURE


static func coerce_growth_stage(value: Variant) -> GrowthStage:
	if value is GrowthStage:
		return value
	return clampi(int(value), GrowthStage.SEED, GrowthStage.MATURE) as GrowthStage


func get_cached_growth_stage() -> GrowthStage:
	return coerce_growth_stage(growth_stage_cached)


func cache_growth_stage(stage: Variant) -> void:
	growth_stage_cached = int(coerce_growth_stage(stage))
