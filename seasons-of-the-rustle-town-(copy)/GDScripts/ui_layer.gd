extends CanvasLayer

var _label_time: Label
var _label_money: Label
var _progress_energy: ProgressBar
var _panel_inventory: Panel
var _inventory_grid: GridContainer
var _slots: Array = []


func _ready() -> void:
	_cache_ui_references()
	_connect_signals()
	_panel_inventory.visible = false
	# 监听背包变化
	InventoryManager.inventory_changed.connect(_on_inventory_changed)
	# 初始刷新背包显示
	refresh_inventory_display()


func _cache_ui_references() -> void:
	_label_time = get_node_or_null("Label_Time") as Label
	_label_money = get_node_or_null("Label_Money") as Label
	_progress_energy = get_node_or_null("ProgressBar_Energy") as ProgressBar
	_panel_inventory = get_node_or_null("Panel_Inventory") as Panel
	
	if _panel_inventory:
		_inventory_grid = _panel_inventory.get_node_or_null("GridContainer_Inventory") as GridContainer
		if _inventory_grid:
			_slots = _inventory_grid.get_children()
			print("找到了 ", _slots.size(), " 个格子")
		else:
			print("找不到 GridContainer_Inventory")
	else:
		print("找不到 Panel_Inventory")


func _connect_signals() -> void:
	UIManager.time_display_updated.connect(update_time_display)
	UIManager.money_display_updated.connect(update_money_display)
	UIManager.energy_display_updated.connect(update_energy_display)
	UIManager.inventory_visibility_changed.connect(_set_inventory_visible)  # 改用下划线
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


# 改名为 _set_inventory_visible，避免与基类冲突
func _set_inventory_visible(visible_state: bool) -> void:
	if _panel_inventory != null:
		_panel_inventory.visible = visible_state


func _on_inventory_toggled() -> void:
	UIManager.toggle_inventory()


func _on_inventory_changed() -> void:
	refresh_inventory_display()


func refresh_inventory_display() -> void:
	if not _inventory_grid or _slots.is_empty():
		print("背包UI: 找不到格子容器或格子为空，格子数量：", _slots.size())
		return
	
	for i in range(InventoryManager.SLOT_COUNT):
		if i >= _slots.size():
			break
		
		var slot_data = InventoryManager.get_slot(i)
		var slot_ui = _slots[i]
		
		# 检查 slot_ui 是否有效
		if slot_ui == null or not is_instance_valid(slot_ui):
			print("格子 ", i, " 无效")
			continue
		
		# 尝试获取图标和数量节点
		var icon = slot_ui.get_node_or_null("Icon")
		var quantity_label = slot_ui.get_node_or_null("Quantity")
		
		if slot_data and not slot_data.is_empty:
			if icon:
				icon.texture = slot_data.item.icon
			if quantity_label:
				quantity_label.text = str(slot_data.quantity)
		else:
			if icon:
				icon.texture = null
			if quantity_label:
				quantity_label.text = ""
