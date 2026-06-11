extends Node

signal tick(minute: int, hour: int, day: int, season: Season, year: int)
signal season_changed(new_season: Season)
signal weather_changed(new_weather: Weather)
signal day_advanced(day: int, season: Season, year: int)

enum Season { SPRING, SUMMER, FALL, WINTER }
enum Weather { SUNNY, RAINY }

const DAYS_PER_SEASON: int = 28

@export var start_hour: int = 6
@export var start_day: int = 1
@export var start_season: Season = Season.SPRING
@export var start_year: int = 1
## 实际 7 秒 = 游戏内 10 分钟
@export var real_seconds_per_10_game_minutes: float = 7.0

var current_minute: int = 0
var current_hour: int = 6
var current_day: int = 1
var current_season: Season = Season.SPRING
var current_year: int = 1
var current_weather: Weather = Weather.SUNNY

var _elapsed: float = 0.0
var _is_running: bool = true


func _ready() -> void:
	reset_time()


func _process(delta: float) -> void:
	if not _is_running:
		return

	_elapsed += delta
	var seconds_per_minute: float = real_seconds_per_10_game_minutes / 10.0

	while _elapsed >= seconds_per_minute:
		_elapsed -= seconds_per_minute
		_advance_minute()


func reset_time() -> void:
	current_minute = 0
	current_hour = start_hour
	current_day = start_day
	current_season = start_season
	current_year = start_year
	current_weather = Weather.SUNNY
	_elapsed = 0.0


func pause() -> void:
	_is_running = false


func resume() -> void:
	_is_running = true


func set_weather(new_weather: Weather) -> void:
	if current_weather == new_weather:
		return
	current_weather = new_weather
	weather_changed.emit(current_weather)


func get_time_string() -> String:
	var hour_12: int = current_hour % 12
	if hour_12 == 0:
		hour_12 = 12
	var period: String = "AM" if current_hour < 12 else "PM"
	return "%d:%02d %s" % [hour_12, current_minute, period]


func get_date_string() -> String:
	var season_name: String = _season_to_string(current_season)
	return "%s %d" % [season_name, current_day]


func get_full_datetime_string() -> String:
	return "%s  %s" % [get_time_string(), get_date_string()]


func _advance_minute() -> void:
	current_minute += 1

	if current_minute >= 60:
		current_minute = 0
		current_hour += 1

		if current_hour >= 24:
			current_hour = 0
			_advance_day()

	tick.emit(current_minute, current_hour, current_day, current_season, current_year)


func _advance_day() -> void:
	current_day += 1

	if current_day > DAYS_PER_SEASON:
		current_day = 1
		_advance_season()

	_roll_weather()
	day_advanced.emit(current_day, current_season, current_year)


func _advance_season() -> void:
	match current_season:
		Season.SPRING:
			current_season = Season.SUMMER
		Season.SUMMER:
			current_season = Season.FALL
		Season.FALL:
			current_season = Season.WINTER
		Season.WINTER:
			current_season = Season.SPRING
			current_year += 1

	season_changed.emit(current_season)


func _roll_weather() -> void:
	var roll: float = randf()
	var new_weather: Weather = Weather.RAINY if roll < 0.2 else Weather.SUNNY
	set_weather(new_weather)


func _season_to_string(season: Season) -> String:
	match season:
		Season.SPRING:
			return "春"
		Season.SUMMER:
			return "夏"
		Season.FALL:
			return "秋"
		Season.WINTER:
			return "冬"
		_:
			return ""
