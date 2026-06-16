class_name TreeResource
extends Resource

## 树木数据：五阶段贴图、砍伐阈值与掉落配置。

enum GrowthStage {
	SEED = 1,
	SPROUT = 2,
	SMALL = 3,
	MEDIUM = 4,
	MATURE = 5,
}

@export var id: StringName = &"oak"
@export var display_name: String = "橡树"
## 索引 0~4 对应阶段 1~5
@export var stage_textures: Array[Texture2D] = []
@export var stage_scales: Array[float] = [0.25, 0.45, 0.65, 0.85, 1.0]
@export var chops_required: int = 5
@export var chop_range: float = 72.0
@export var interaction_radius: float = 40.0

## 大树倒下额外掉落（每次受击已掉 1 木材）
@export var fall_wood_min: int = 12
@export var fall_wood_max: int = 16
@export var fall_sap_count: int = 5
@export var fall_seed_min: int = 0
@export var fall_seed_max: int = 2

## 树桩砍伐掉落
@export var stump_wood_min: int = 4
@export var stump_wood_max: int = 9
@export var stump_sap_count: int = 1
@export var stump_chops_required: int = 2

## 倒下动画
@export var fall_duration: float = 0.55
@export var hit_shake_strength: float = 6.0
@export var hit_shake_duration: float = 0.12
