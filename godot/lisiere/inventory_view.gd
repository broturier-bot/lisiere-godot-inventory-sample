extends PanelContainer
## Reusable view. Call bind_inventory(model) before adding to the scene tree.
const Slot = preload("slot_button.gd")
signal selected(model, index: int)
signal notice(message: String)
@export var heading: String = "Inventory"
@export_range(2, 8) var columns: int = 4
var model
var icon_palette: String = "sage"
var _buttons: Array = []
var _capacity_label: Label

func bind_inventory(value) -> void:
	if model != null and model.changed.is_connected(refresh): model.changed.disconnect(refresh)
	model = value
	if model != null: model.changed.connect(refresh)
	if is_inside_tree(): _build()

func _ready() -> void:
	custom_minimum_size.x = 348
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_build()

func _build() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_buttons.clear()
	var stack := VBoxContainer.new()
	add_child(stack)
	var title := Label.new()
	title.text = heading
	title.add_theme_font_size_override("font_size", 25)
	stack.add_child(title)
	_capacity_label = Label.new()
	_capacity_label.add_theme_font_size_override("font_size", 13)
	stack.add_child(_capacity_label)
	if model == null:
		_capacity_label.text = "Bind an inventory model to display its items."
		return
	var grid := GridContainer.new()
	grid.columns = columns
	stack.add_child(grid)
	for i in range(model.capacity()):
		var button := Slot.new()
		button.model = model
		button.index = i
		button.icon_palette = icon_palette
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.selected.connect(func(value, slot_index): selected.emit(value, slot_index))
		button.notice.connect(func(message): notice.emit(message))
		grid.add_child(button)
		_buttons.append(button)
	refresh()

func refresh() -> void:
	if _capacity_label == null or model == null: return
	_capacity_label.text = "%d / %d slots in use" % [model.occupied(), model.capacity()]
	for button in _buttons:
		button.icon_palette = icon_palette
		button.refresh()

func mark_selection(selected_model, selected_index: int) -> void:
	for button in _buttons:
		button.theme_type_variation = "LisiereSelected" if model == selected_model and button.index == selected_index else "LisiereSlot"
