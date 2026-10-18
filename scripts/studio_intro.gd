extends Control
signal finished
const STUDIO = "Yassper Design"
var age: float = 0
var active: bool = false
var content: Control
var serif: Font
var signature: Label
var presenter: Label
var skip: Label

func setup() -> void:
	size = Vector2(1600, 900)
	serif = preload("res://scripts/interface_style.gd").serif()
	var shade := ColorRect.new()
	shade.size = size
	shade.color = Color("111111")
	shade.show_behind_parent = true
	var backdrop := Shader.new()
	backdrop.code = """shader_type canvas_item;
void fragment() {
	vec2 p = UV - vec2(0.5, 0.46);
	float light = exp(-dot(p * vec2(1.1, 1.8), p * vec2(1.1, 1.8)) * 5.0);
	float grain = fract(sin(dot(floor(UV * vec2(1600.0, 900.0)), vec2(12.9898, 78.233))) * 43758.5453);
	float shade = 0.025 + light * 0.048 + grain * 0.009;
	COLOR = vec4(vec3(shade), 1.0);
}"""
	var material := ShaderMaterial.new()
	material.shader = backdrop
	shade.material = material
	add_child(shade)
	content = Control.new()
	content.size = size
	content.pivot_offset = Vector2(800, 425)
	add_child(content)
	var label := Label.new()
	label.text = "YASSPER"
	label.position = Vector2(200, 322)
	label.size = Vector2(1200, 145)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", serif)
	label.add_theme_font_size_override("font_size", 108)
	label.add_theme_constant_override("outline_size", 0)
	label.add_theme_color_override("font_color", Color("eae7df"))
	content.add_child(label)
	signature = Label.new()
	signature.text = "D  E  S  I  G  N"
	signature.position = Vector2(300, 475)
	signature.size = Vector2(1000, 40)
	signature.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	signature.add_theme_font_size_override("font_size", 24)
	signature.add_theme_color_override("font_color", Color("b8b5ae"))
	content.add_child(signature)
	presenter = Label.new()
	presenter.text = "P R E S E N T A"
	presenter.position = Vector2(300, 610)
	presenter.size = Vector2(1000, 30)
	presenter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	presenter.add_theme_font_size_override("font_size", 15)
	presenter.add_theme_color_override("font_color", Color("8c8a84"))
	content.add_child(presenter)
	skip = Label.new()
	skip.text = "Enter / A · Continuar"
	skip.position = Vector2(1190, 833)
	skip.add_theme_font_size_override("font_size", 17)
	skip.add_theme_color_override("font_color", Color("93918c"))
	add_child(skip)
	hide()

func start() -> void:
	age = 0
	active = true
	show()
	content.modulate.a = 0
	skip.modulate.a = 0

func finish() -> void:
	if not active: return
	active = false
	hide()
	finished.emit()

func handle_input(event: InputEvent) -> void:
	if age < 0.35 or not event.is_pressed() or event.is_echo(): return
	if (event is InputEventKey and event.keycode in [KEY_ENTER, KEY_SPACE, KEY_ESCAPE]) or (event is InputEventJoypadButton and event.button_index in [JOY_BUTTON_A, JOY_BUTTON_B, JOY_BUTTON_START]) or event is InputEventMouseButton:
		get_viewport().set_input_as_handled()
		finish()

func _process(delta: float) -> void:
	if not active or not is_visible_in_tree(): return
	age += delta
	var fade_out: float = 1.0 - smoothstep(3.7, 4.6, age)
	content.modulate.a = smoothstep(0.2, 1.3, age) * fade_out
	content.scale = Vector2.ONE * lerpf(1.018, 1.0, smoothstep(0.2, 3.5, age))
	signature.modulate.a = smoothstep(0.8, 1.8, age)
	presenter.modulate.a = smoothstep(1.6, 2.5, age)
	skip.modulate.a = smoothstep(2.0, 2.6, age) * fade_out * 0.6
	if age >= 4.6: finish()
