extends Button
const Inventory = preload("inventory.gd")
signal selected(model, index: int)
signal notice(message: String)
var model
var index: int = 0
var icon_palette: String = "sage"
var image: TextureRect
var amount: Label

func _ready() -> void:
	custom_minimum_size = Vector2(70, 76)
	theme_type_variation = "LisiereSlot"
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	image = TextureRect.new()
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image.offset_left = 9
	image.offset_right = -9
	image.offset_top = 6
	image.offset_bottom = -18
	add_child(image)
	amount = Label.new()
	amount.mouse_filter = Control.MOUSE_FILTER_IGNORE
	amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	amount.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	amount.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	amount.offset_right = -8
	amount.offset_bottom = -4
	amount.add_theme_font_size_override("font_size", 13)
	add_child(amount)
	pressed.connect(func(): selected.emit(model, index))
	focus_entered.connect(func(): selected.emit(model, index))
	refresh()

func refresh() -> void:
	if image == null or model == null: return
	var item: Dictionary = model.slot(index)
	if item.is_empty():
		image.texture = null
		amount.text = ""
		tooltip_text = "Empty slot %d" % (index + 1)
	else:
		var definition: Dictionary = model.definition(item.id)
		var asset: String = "res://lisiere/icons/%s/%s.svg" % [icon_palette, definition.get("icon", "")]
		image.texture = load(asset) if ResourceLoader.exists(asset) else null
		amount.text = str(item.quantity)
		tooltip_text = "%s × %d\n%s" % [definition.get("name", item.id), item.quantity, definition.get("description", "")]
	accessibility_name = tooltip_text

func _get_drag_data(_position: Vector2) -> Variant:
	var item: Dictionary = model.slot(index)
	if item.is_empty(): return null
	selected.emit(model, index)
	var preview := TextureRect.new()
	preview.texture = image.texture
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.custom_minimum_size = Vector2(56, 56)
	preview.modulate.a = 0.85
	set_drag_preview(preview)
	# Dragging never removes an item. A valid drop commits the change once.
	return {"source": model, "index": index, "revision": model.revision}

func _can_drop_data(_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("source") is Inventory and data.get("index") is int and data.get("revision") == data.source.revision

func _drop_data(_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(_position, data): return
	var result: Dictionary = data.source.transfer_to(model, data.index, index)
	notice.emit(result.reason)
	selected.emit(model, index)
