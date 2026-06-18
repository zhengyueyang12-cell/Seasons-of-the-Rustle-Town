extends CanvasLayer

var _label_time: Label
var _label_money: Label
var _progress_energy: ProgressBar
var _panel_inventory: Panel
var _inventory_grid: GridContainer
var _hotbar_container: HBoxContainer


func _ready() -> void:
	_cache_ui_references()
	_connect_signals()
	_panel_inventory.visible = false
	call_deferred(&"_configure_slot_indices")


func _cache_ui_references() -> void:
	_label_time = get_node_or_null("Label_Time") as Label
	_label_money = get_node_or_null("Label_Money") as Label
	_progress_energy = get_node_or_null("ProgressBar_Energy") as ProgressBar
	_panel_inventory = get_node_or_null("Panel_Inventory") as Panel
	_hotbar_container = get_node_or_null("Panel_Hotbar/HBoxContainer_Hotbar") as HBoxContainer

	if _panel_inventory:
		_inventory_grid = _panel_inventory.get_node_or_null("GridContainer_Inventory") as GridContainer


func _configure_slot_indices() -> void:
	if _inventory_grid:
		var children: Array[Node] = _inventory_grid.get_children()
		for i: int in children.size():
			var slot_ui: InventorySlotUI = children[i] as InventorySlotUI
			if slot_ui == null:
				continue
			slot_ui.bind_slot(ItemTransferService.ContainerType.INVENTORY, i)

	if _hotbar_container:
		var hotbar_children: Array[Node] = _hotbar_container.get_children()
		for i: int in hotbar_children.size():
			var slot_ui: InventorySlotUI = hotbar_children[i] as InventorySlotUI
			if slot_ui == null:
				continue
			slot_ui.bind_slot(ItemTransferService.ContainerType.HOTBAR, i)

	HotbarManager.set_active_slot(HotbarManager.active_slot_index, true)


func refresh_all_slots() -> void:
	if _inventory_grid:
		for child: Node in _inventory_grid.get_children():
			var slot_ui: InventorySlotUI = child as InventorySlotUI
			if slot_ui != null:
				slot_ui.refresh_display()

	if _hotbar_container:
		for child: Node in _hotbar_container.get_children():
			var slot_ui: InventorySlotUI = child as InventorySlotUI
			if slot_ui != null:
				slot_ui.refresh_display()
				slot_ui.refresh_highlight()


func _connect_signals() -> void:
	UIManager.time_display_updated.connect(update_time_display)
	UIManager.money_display_updated.connect(update_money_display)
	UIManager.energy_display_updated.connect(update_energy_display)
	UIManager.inventory_visibility_changed.connect(_set_inventory_visible)
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


func _set_inventory_visible(visible_state: bool) -> void:
	if _panel_inventory != null:
		_panel_inventory.visible = visible_state


func _on_inventory_toggled() -> void:
	UIManager.toggle_inventory()
