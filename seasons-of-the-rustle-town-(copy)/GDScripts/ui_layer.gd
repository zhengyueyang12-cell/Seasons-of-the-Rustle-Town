extends CanvasLayer

var _label_time: Label
var _label_money: Label
var _progress_energy: ProgressBar
var _panel_inventory: Panel


func _ready() -> void:
	_cache_ui_references()
	_connect_signals()
	_panel_inventory.visible = false


func _cache_ui_references() -> void:
	_label_time = get_node_or_null("Label_Time") as Label
	_label_money = get_node_or_null("Label_Money") as Label
	_progress_energy = get_node_or_null("ProgressBar_Energy") as ProgressBar
	_panel_inventory = get_node_or_null("Panel_Inventory") as Panel


func _connect_signals() -> void:
	UIManager.time_display_updated.connect(update_time_display)
	UIManager.money_display_updated.connect(update_money_display)
	UIManager.energy_display_updated.connect(update_energy_display)
	UIManager.inventory_visibility_changed.connect(set_inventory_visible)
	InputManager.inventory_toggled.connect(_on_inventory_toggled)


func update_time_display(time_string: String) -> void:
	if _label_time != null:
		_label_time.text = time_string


func update_money_display(amount: int) -> void:
	if _label_money != null:
		_label_money.text = "%d G" % amount


func update_energy_display(current: int, maximum: int) -> void:
	if _progress_energy != null:
		_progress_energy.max_value = maximum
		_progress_energy.value = current


func set_inventory_visible(visible: bool) -> void:
	if _panel_inventory != null:
		_panel_inventory.visible = visible


func _on_inventory_toggled() -> void:
	UIManager.toggle_inventory()
