class_name CropResource
extends Resource

## 作物定义：生长阶段图集坐标、收获物与季节限制。

@export var id: StringName = &""
@export var display_name: String = ""
@export var stage_atlas_coords: Array[Vector2i] = []
@export var days_per_stage: int = 1
@export var harvest_item_id: StringName = &""
@export var harvest_amount: int = 1
## 留空表示四季可种
@export var valid_seasons: Array[int] = []
