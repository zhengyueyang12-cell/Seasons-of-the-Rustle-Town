extends Node2D

## 地图固定雨效（GPUParticles2D）
##
## 【作用】
## - 雨丝：从 rain..png 第 1 帧裁切，大范围均匀发射，落在地图世界坐标
## - 水花：第 2–4 帧三帧动画，作为雨丝 sub-emitter，雨滴结束时触发
##
## 【操作】挂于 World/RainEffect；force_rain_in_game=false 时接 TimeManager 天气
## 【扩展】调 rain_amount / emission_half_size / rain_wind_x；或监听 weather_changed 换场景

const RAIN_SHEET: Texture2D = preload("res://art/items/TileSheets/rain..png")
const SHEET_H_FRAMES: int = 4
const SPLASH_H_FRAMES: int = 3

@export_group("范围")
@export var emission_half_size: Vector2 = Vector2(1100, 750)

@export_group("雨量")
@export var rain_amount: int = 3200
@export var sub_emitter_amount_at_end: int = 1
@export var rain_lifetime: float = 0.65
@export var splash_lifetime: float = 0.2
## 雨丝贴图本身向左下倾斜，运动矢量需与贴图一致（负值=向左飘）
@export_range(-0.6, 0.6, 0.01) var rain_wind_x: float = -0.2

@export_group("调试")
@export var force_rain_in_editor: bool = false
@export var force_rain_in_game: bool = true

var _rain: GPUParticles2D
var _splash: GPUParticles2D


func _ready() -> void:
	z_index = 200
	_splash = _create_splash_particles()
	_rain = _create_rain_particles()
	add_child(_rain)
	add_child(_splash)
	_rain.sub_emitter = _rain.get_path_to(_splash)
	_update_emission_area()
	_set_raining(false)

	if Engine.is_editor_hint():
		if force_rain_in_editor:
			_set_raining(true)
		return

	if force_rain_in_game:
		_set_raining(true)
	else:
		TimeManager.weather_changed.connect(_on_weather_changed)
		_on_weather_changed(TimeManager.current_weather)


func _on_weather_changed(weather: TimeManager.Weather) -> void:
	_set_raining(weather == TimeManager.Weather.RAINY)


func _set_raining(active: bool) -> void:
	if _rain != null:
		_rain.emitting = active
	if _splash != null:
		_splash.emitting = active


func _frame_size() -> Vector2i:
	var frame_w: int = maxi(RAIN_SHEET.get_width() / SHEET_H_FRAMES, 1)
	var frame_h: int = maxi(RAIN_SHEET.get_height(), 1)
	return Vector2i(frame_w, frame_h)


func _atlas_frame(frame_index: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = RAIN_SHEET
	var frame_size: Vector2i = _frame_size()
	atlas.region = Rect2i(frame_index * frame_size.x, 0, frame_size.x, frame_size.y)
	atlas.filter_clip = true
	return atlas


func _splash_atlas() -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = RAIN_SHEET
	var frame_size: Vector2i = _frame_size()
	atlas.region = Rect2i(frame_size.x, 0, frame_size.x * SPLASH_H_FRAMES, frame_size.y)
	atlas.filter_clip = true
	return atlas


func _update_emission_area() -> void:
	var half: Vector2 = emission_half_size
	var box := Vector3(half.x, half.y, 0.0)
	var rect := Rect2(-half, half * 2.0)
	if _rain != null:
		_rain.visibility_rect = rect
		var rain_mat := _rain.process_material as ParticleProcessMaterial
		if rain_mat != null:
			rain_mat.emission_box_extents = box
	if _splash != null:
		_splash.visibility_rect = rect


func _pixel_scale(frame_h: int, target_px: float, min_s: float, max_s: float) -> float:
	return clampf(target_px / float(maxi(frame_h, 1)), min_s, max_s)


func _rain_fall_direction() -> Vector3:
	return Vector3(rain_wind_x, 1.0, 0.0).normalized()


func _create_rain_particles() -> GPUParticles2D:
	var particles := GPUParticles2D.new()
	particles.name = &"RainParticles"
	particles.local_coords = false
	particles.texture = _atlas_frame(0)
	particles.amount = rain_amount
	particles.lifetime = rain_lifetime
	particles.preprocess = rain_lifetime * 1.5
	particles.randomness = 0.32
	particles.fixed_fps = 0
	particles.interpolate = true

	var mat := ParticleProcessMaterial.new()
	# 贴图已带倾斜，不再按速度旋转，避免与运动方向打架
	mat.set_particle_flag(ParticleProcessMaterial.PARTICLE_FLAG_ALIGN_Y_TO_VELOCITY, false)
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(emission_half_size.x, emission_half_size.y, 0.0)
	var fall_dir: Vector3 = _rain_fall_direction()
	mat.direction = fall_dir
	mat.spread = 5.0
	mat.gravity = fall_dir * 300.0
	mat.initial_velocity_min = 90.0
	mat.initial_velocity_max = 140.0
	mat.damping_min = 0.0
	mat.damping_max = 0.0
	mat.angle_min = 0.0
	mat.angle_max = 0.0
	var frame_h: int = _frame_size().y
	var rain_scale: float = _pixel_scale(frame_h, 7.0, 0.45, 0.95)
	mat.scale_min = rain_scale
	mat.scale_max = rain_scale * 1.1
	mat.color = Color(0.82, 0.9, 1.0, 0.38)
	mat.sub_emitter_mode = ParticleProcessMaterial.SUB_EMITTER_AT_END
	mat.sub_emitter_amount_at_end = sub_emitter_amount_at_end
	mat.sub_emitter_keep_velocity = false
	particles.process_material = mat
	return particles


func _create_splash_particles() -> GPUParticles2D:
	var particles := GPUParticles2D.new()
	particles.name = &"SplashParticles"
	particles.local_coords = false
	particles.texture = _splash_atlas()
	particles.amount = maxi(rain_amount * sub_emitter_amount_at_end, 64)
	particles.lifetime = splash_lifetime
	particles.randomness = 0.4
	particles.fixed_fps = 0
	particles.interpolate = true

	var canvas_mat := CanvasItemMaterial.new()
	canvas_mat.particles_animation = true
	canvas_mat.particles_anim_h_frames = SPLASH_H_FRAMES
	canvas_mat.particles_anim_v_frames = 1
	canvas_mat.particles_anim_loop = false
	particles.material = canvas_mat

	var mat := ParticleProcessMaterial.new()
	mat.set_particle_flag(ParticleProcessMaterial.PARTICLE_FLAG_ALIGN_Y_TO_VELOCITY, false)
	mat.direction = Vector3(0.0, -1.0, 0.0)
	mat.spread = 32.0
	mat.gravity = Vector3(0.0, 30.0, 0.0)
	mat.initial_velocity_min = 1.0
	mat.initial_velocity_max = 8.0
	var frame_h: int = _frame_size().y
	var splash_scale: float = _pixel_scale(frame_h, 5.5, 0.35, 0.75)
	mat.scale_min = splash_scale
	mat.scale_max = splash_scale * 1.15
	mat.color = Color(0.78, 0.86, 0.98, 0.5)
	var splash_fps: float = float(SPLASH_H_FRAMES) / splash_lifetime
	mat.anim_speed_min = splash_fps
	mat.anim_speed_max = splash_fps
	mat.anim_offset_min = 0.0
	mat.anim_offset_max = 0.0
	particles.process_material = mat
	return particles
