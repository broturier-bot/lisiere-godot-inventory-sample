extends RefCounted
## Native Godot styles: all control text stays editable and scales with the UI.
static func colors(name: String = "sage") -> Dictionary:
	match name:
		_: return {"paper":Color("f5f2e7"),"surface":Color("e2e8d6"),"ink":Color("263c33"),"line":Color("72966d"),"accent":Color("985936")}

static func box(fill: Color, line: Color, width: int = 1, radius: int = 12, margin: int = 14) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = line
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = margin
	style.content_margin_right = margin
	style.content_margin_top = margin
	style.content_margin_bottom = margin
	return style

static func make(name: String = "sage") -> Theme:
	var p: Dictionary = colors(name)
	var result := Theme.new()
	result.default_font_size = 16
	for type in ["Label", "Button", "OptionButton", "RichTextLabel", "CheckButton"]:
		result.set_color("font_color", type, p.ink)
		result.set_color("font_hover_color", type, p.ink)
		result.set_color("font_focus_color", type, p.ink)
		result.set_color("font_pressed_color", type, p.ink)
	result.set_stylebox("panel", "PanelContainer", box(p.paper, p.line, 1, 16, 22))
	result.set_stylebox("normal", "Button", box(p.surface, p.line))
	result.set_stylebox("hover", "Button", box(p.paper, p.ink, 2))
	result.set_stylebox("pressed", "Button", box(p.surface, p.ink, 2))
	result.set_stylebox("disabled", "Button", box(p.paper, p.line))
	result.set_color("font_disabled_color", "Button", p.ink.lerp(p.paper, 0.4))
	var focus := box(Color.TRANSPARENT, p.accent, 3, 12, 0)
	focus.draw_center = false
	result.set_stylebox("focus", "Button", focus)
	result.set_type_variation("LisierePrimary", "Button")
	for state in ["normal", "hover", "pressed"]:
		result.set_stylebox(state, "LisierePrimary", box(p.ink, p.ink, 1))
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		result.set_color(state, "LisierePrimary", p.paper)
	result.set_type_variation("LisiereSlot", "Button")
	result.set_type_variation("LisiereSelected", "LisiereSlot")
	for state in ["normal", "hover", "pressed"]:
		result.set_stylebox(state, "LisiereSlot", box(p.surface if state == "normal" else p.paper, p.line, 1, 12, 3))
		result.set_stylebox(state, "LisiereSelected", box(p.paper, p.ink, 3, 12, 3))
	result.set_stylebox("panel", "TooltipPanel", box(p.ink, p.ink, 1, 8, 12))
	result.set_color("font_color", "TooltipLabel", p.paper)
	result.set_constant("separation", "VBoxContainer", 14)
	result.set_constant("separation", "HBoxContainer", 12)
	result.set_constant("h_separation", "GridContainer", 8)
	result.set_constant("v_separation", "GridContainer", 8)
	return result
