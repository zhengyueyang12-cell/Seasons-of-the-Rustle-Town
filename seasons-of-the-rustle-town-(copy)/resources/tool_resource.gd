class_name ToolResource
extends ItemResource

enum ToolType { HOE, PICKAXE, AXE, WATERING_CAN }

@export var tool_type: ToolType = ToolType.HOE
@export var tier: int = 1
@export var energy_cost: int = 2
@export var use_range: float = 48.0
@export var effect_radius: float = 0.5
@export var use_cooldown: float = 0.35
@export var held_sprite: Texture2D
