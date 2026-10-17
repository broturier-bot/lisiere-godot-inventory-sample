extends Control
const Inventory = preload("res://lisiere/inventory.gd")
const View = preload("res://lisiere/inventory_view.gd")
const Style = preload("res://lisiere/theme.gd")
var bag
var status: Label
func _ready() -> void:
	theme = Style.make("sage")
	var bg := ColorRect.new()
	bg.color = Style.colors().surface
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 28)
	add_child(margin)
	var page := VBoxContainer.new()
	margin.add_child(page)
	_label(page, "LISIÈRE  /  FREE GODOT SAMPLE", 14)
	_label(page, "Try a little inventory.", 32)
	_label(page, "Drag to move, merge or swap. Tab + Enter select items.\nThree item types · six slots · Sage palette", 16)
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://lisiere/items.json"))
	bag = Inventory.new(catalog, 6)
	var view = View.new()
	view.heading = "Your satchel"
	view.columns = 3
	view.bind_inventory(bag)
	page.add_child(view)
	view.notice.connect(func(message): status.text = message)
	view.selected.connect(func(model, index):
		var item: Dictionary = model.slot(index)
		status.text = "An empty slot." if item.is_empty() else "%s × %d — %s" % [model.definition(item.id).name, item.quantity, model.definition(item.id).description])
	var buttons := HBoxContainer.new()
	page.add_child(buttons)
	var gather := Button.new()
	gather.text = "Gather 3 apples"
	gather.pressed.connect(func(): status.text = "Added %d of 3 apples." % bag.add_item("apple", 3))
	buttons.add_child(gather)
	var reset := Button.new()
	reset.text = "Reset sample"
	reset.pressed.connect(_reset)
	buttons.add_child(reset)
	status = _label(page, "", 16)
	status.custom_minimum_size.y = 55
	_label(page, "Created with generative AI: artwork, code and documentation.\nFree source sample for commercial finished projects under LICENSE.txt.\nThe paid starter adds a chest demo, move buttons, local save/load, three palettes and the complete art collection.", 13)
	_reset()
func _label(parent: Node, text: String, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	parent.add_child(label)
	return label
func _reset() -> void:
	var data: Dictionary = bag.snapshot()
	data.slots.fill({})
	bag.restore(data)
	bag.add_item("apple", 16)
	bag.add_item("mushroom", 7)
	bag.add_item("seed", 24)
	status.text = "Drop apples onto apples to merge up to 20. Overflow stays in its original slot."
