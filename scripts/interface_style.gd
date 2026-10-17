extends RefCounted
## Shared paper, typography and control materials for the in-game overlays.
const InkButton = preload("res://scripts/ink_button.gd")
const INK = Color("242b28")
const MUTED = Color("62665f")
const RED = Color("983e35")

static func serif() -> SystemFont:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Georgia", "Noto Serif", "DejaVu Serif", "serif"])
	return font

static func box(fill: Color, border: Color = Color.TRANSPARENT, margins: float = 12) -> StyleBoxFlat:
	var result := StyleBoxFlat.new()
	result.bg_color = fill
	result.border_color = border
	result.set_border_width_all(1)
	result.content_margin_left = margins
	result.content_margin_right = margins
	result.content_margin_top = 6
	result.content_margin_bottom = 6
	return result

static func svg(source: String) -> Texture2D:
	var image := Image.new()
	image.load_svg_from_string(source)
	return ImageTexture.create_from_image(image)

static func control_theme() -> Theme:
	var result := Theme.new()
	result.default_font_size = 21
	result.set_color("font_color", "Label", INK)
	for type in ["Button", "OptionButton", "CheckButton", "PopupMenu"]:
		for color in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			result.set_color(color, type, INK)
		result.set_color("font_disabled_color", type, Color("92948b"))
		result.set_color("font_hover_color", "PopupMenu", Color("f3eee2"))
		for state in ["normal", "hover", "pressed", "disabled", "hover_pressed"]:
			result.set_stylebox(state, type, box(Color("eeeadf") if state == "normal" else Color("dcd9cb"), Color("b5b6a6")))
		result.set_stylebox("focus", type, box(Color.TRANSPARENT, RED))
	result.set_stylebox("panel", "PopupMenu", box(Color("eeeadd"), Color("a7a99b"), 16))
	result.set_stylebox("hover", "PopupMenu", box(INK))
	result.set_stylebox("panel", "TabContainer", box(Color(1, 1, 1, 0.19), Color.TRANSPARENT, 0))
	result.set_icon("arrow", "OptionButton", svg('<svg xmlns="http://www.w3.org/2000/svg" width="16" height="12"><path d="M2 3 L8 9 L14 3" fill="none" stroke="#983e35" stroke-width="2"/></svg>'))
	for checked in [false, true]:
		var icon := svg('<svg xmlns="http://www.w3.org/2000/svg" width="48" height="28"><rect x="1" y="2" width="46" height="24" rx="12" fill="%s"/><circle cx="%d" cy="14" r="8" fill="#f3eee2"/></svg>' % ["#983e35" if checked else "#858b80", 34 if checked else 14])
		result.set_icon("checked" if checked else "unchecked", "CheckButton", icon)
		result.set_icon("checked_disabled" if checked else "unchecked_disabled", "CheckButton", icon)
	result.set_constant("h_separation", "CheckButton", 16)
	for state in ["normal", "hover", "pressed", "hover_pressed"]:
		result.set_stylebox(state, "CheckButton", box(Color(1, 1, 1, 0.12) if state == "normal" else Color(1, 1, 1, 0.3), Color.TRANSPARENT))
	var rail := box(Color("babdad"), Color.TRANSPARENT, 0)
	rail.content_margin_top = 2
	rail.content_margin_bottom = 2
	result.set_stylebox("slider", "HSlider", rail)
	var fill: StyleBoxFlat = rail.duplicate()
	fill.bg_color = RED
	result.set_stylebox("grabber_area", "HSlider", fill)
	result.set_stylebox("grabber_area_highlight", "HSlider", fill)
	for icon in ["grabber", "grabber_highlight", "grabber_disabled"]:
		result.set_icon(icon, "HSlider", svg('<svg xmlns="http://www.w3.org/2000/svg" width="22" height="26"><circle cx="11" cy="13" r="8" fill="#983e35"/><circle cx="11" cy="13" r="3" fill="#f3eee2"/></svg>'))
	result.set_stylebox("focus", "HSlider", box(Color.TRANSPARENT, RED, 0))
	return result

static func paper(parent: Control, rect: Rect2) -> ColorRect:
	var node := ColorRect.new()
	node.position = rect.position
	node.size = rect.size
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = preload("res://art/ui/paper.gdshader")
	node.material = material
	parent.add_child(node)
	return node

static func label(parent: Node, caption: String, rect: Rect2, font_size: int = 21, literary: bool = false, color: Color = INK) -> Label:
	var node := Label.new()
	node.text = caption
	node.position = rect.position
	node.size = rect.size
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	if literary:
		node.add_theme_font_override("font", serif())
	parent.add_child(node)
	return node

static func button(parent: Node, caption: String, literary: bool = false) -> Button:
	var node := InkButton.new()
	node.text = caption
	node.quiet = not literary
	node.add_theme_font_size_override("font_size", 26 if literary else 20)
	if literary:
		node.add_theme_font_override("font", serif())
	node.custom_minimum_size = Vector2(ThemeDB.fallback_font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x + 88, 48)
	parent.add_child(node)
	return node
