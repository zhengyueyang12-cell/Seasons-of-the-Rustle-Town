extends Node2D

signal game_paused()
signal game_resumed()

var is_paused: bool = false


func _ready() -> void:
	_connect_signals()
	call_deferred(&"_initialize_systems")


func _initialize_systems() -> void:
	UIManager.refresh_all_displays()


func _connect_signals() -> void:
	TimeManager.tick.connect(_on_time_tick)
	TimeManager.season_changed.connect(_on_season_changed)
	GameState.gold_changed.connect(_on_gold_changed)
	GameState.energy_changed.connect(_on_energy_changed)


func pause_game() -> void:
	if is_paused:
		return

	is_paused = true
	get_tree().paused = true
	TimeManager.pause()
	game_paused.emit()


func resume_game() -> void:
	if not is_paused:
		return

	is_paused = false
	get_tree().paused = false
	TimeManager.resume()
	game_resumed.emit()


func toggle_pause() -> void:
	if is_paused:
		resume_game()
	else:
		pause_game()


func _on_time_tick(
	_minute: int, _hour: int, _day: int, _season: TimeManager.Season, _year: int
) -> void:
	UIManager.refresh_time_display()


func _on_season_changed(_new_season: TimeManager.Season) -> void:
	UIManager.refresh_time_display()


func _on_gold_changed(_new_amount: int) -> void:
	UIManager.refresh_money_display()


func _on_energy_changed(_current: int, _maximum: int) -> void:
	UIManager.refresh_energy_display()
