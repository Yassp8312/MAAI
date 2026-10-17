extends Button
## Stable hit area, animated ink underneath. Mouse, keyboard and pad share focus.
var emphasis: float = 0
var selected: bool = false
var card: bool = false
var quiet: bool = false
var primary: bool = false
var ordinal: String = ""
var entrance: float = 1
var press_depth: float = 0

func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	for state in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_disabled_color", "font_hover_pressed_color"]:
		add_theme_color_override(state, Color.TRANSPARENT)

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	var active: bool = not disabled and (is_hovered() or has_focus() or selected)
	var target: float = 1.0 if active else (0.82 if primary else 0.0)
	emphasis = lerpf(emphasis, target, 1 - exp(-delta * 13))
	press_depth = lerpf(press_depth, 1.0 if is_pressed() else 0.0, 1 - exp(-delta * 24))
	entrance = minf(1, entrance + delta * 3.5)
	queue_redraw()

func _draw() -> void:
	var ink := Color("242b28")
	var red := Color("963f35")
	var paper := Color("f3eee2")
	if card:
		draw_style_box(get_theme_stylebox("normal"), Rect2(Vector2.ZERO, size))
		draw_rect(Rect2(Vector2.ZERO, size), Color(1, 0.98, 0.92, 0.09 + emphasis * 0.22))
		draw_line(Vector2(0, size.y), Vector2(size.x, size.y), red if selected else Color("b4b1a4"), 3 if selected else 1)
		if emphasis > 0.01:
			draw_line(Vector2.ZERO, Vector2(size.x * emphasis, 0), Color(red, emphasis), 3)
		return
	var sweep: float = smoothstep(0, 1, emphasis)
	# Primary actions keep the arrow over ink even at their resting emphasis.
	var extent: float = size.x * (1.0 if primary else sweep)
	var wash := PackedVector2Array([Vector2(0, 2), Vector2(extent, 0), Vector2(extent - 5, size.y - 2), Vector2(0, size.y)])
	if extent > 5:
		draw_colored_polygon(wash, Color(ink, sweep * (0.94 if not quiet else 0.84)))
	draw_line(Vector2(0, size.y), Vector2(size.x, size.y), Color(ink, 0.20), 1)
	if emphasis > 0.01:
		draw_line(Vector2(0, 4), Vector2(0, size.y - 4), Color(red, emphasis), 3)
	var font: Font = get_theme_font("font")
	var font_size: int = get_theme_font_size("font_size")
	var baseline: float = (size.y - font.get_height(font_size)) * 0.5 + font.get_ascent(font_size) + press_depth * 2
	var color: Color = ink.lerp(paper, sweep)
	var inset: float = 18 + emphasis * 10 + (1 - entrance) * 16
	if not ordinal.is_empty():
		draw_string(ThemeDB.fallback_font, Vector2(inset, baseline - 2), ordinal, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("b5725e").lerp(paper, sweep * 0.5))
		inset += 46
	var text_width: float = size.x - inset - 48
	draw_string(font, Vector2(inset, baseline), text, HORIZONTAL_ALIGNMENT_LEFT, text_width, font_size, Color(color, entrance * (0.4 if disabled else 1.0)))
	var tip := Vector2(size.x - 25 + emphasis * 3, size.y * 0.5)
	if emphasis > 0.02:
		draw_line(tip - Vector2(18, 0), tip, Color(paper, emphasis), 1.2, true)
		draw_polyline(PackedVector2Array([tip - Vector2(5, 5), tip, tip - Vector2(5, -5)]), Color(paper, emphasis), 1.2, true)
