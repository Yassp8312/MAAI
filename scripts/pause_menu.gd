extends PanelContainer
const Style = preload("res://scripts/interface_style.gd")
var game
var resume_button: Button
var options_button: Button
var arena_button: Button
var duel: Label
var score: Label
var note: Label
var paper: ColorRect
var entrance: Tween

func setup(owner_game: Node) -> void:
	game = owner_game
	size = Vector2(1600, 900)
	theme = Style.control_theme()
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var canvas := Control.new()
	canvas.custom_minimum_size = size
	add_child(canvas)
	var shade := ColorRect.new()
	shade.size = size
	shade.color = Color(0.035, 0.055, 0.045, 0.78)
	canvas.add_child(shade)
	paper = Style.paper(canvas, Rect2(170, 130, 1260, 640))
	Style.label(canvas, "M A A I  /  EL DUELO", Rect2(226, 175, 540, 30), 18, false, Style.MUTED)
	Style.label(canvas, "Una pausa.\nLa distancia\npermanece.", Rect2(226, 236, 590, 240), 55, true)
	duel = Style.label(canvas, "", Rect2(230, 515, 545, 38), 29, true)
	score = Style.label(canvas, "", Rect2(230, 568, 545, 36), 22, false, Style.RED)
	note = Style.label(canvas, "", Rect2(230, 658, 545, 52), 19, false, Style.MUTED)
	var line := ColorRect.new()
	line.color = Color("b1b4a6")
	line.position = Vector2(806, 228)
	line.size = Vector2(1, 470)
	canvas.add_child(line)
	var buttons := VBoxContainer.new()
	buttons.position = Vector2(852, 238)
	buttons.size = Vector2(520, 412)
	buttons.add_theme_constant_override("separation", 16)
	canvas.add_child(buttons)
	resume_button = add_action(buttons, "Continuar el duelo", game.resume_game)
	resume_button.primary = true
	options_button = add_action(buttons, "Opciones", game.open_options)
	add_action(buttons, "Elegir personajes", game.return_to_selection)
	arena_button = add_action(buttons, "Escenario: Patio al atardecer", game.toggle_arena, false)
	add_action(buttons, "Volver al menú principal", game.return_to_menu)
	Style.label(canvas, "Esc / Start · Continuar", Rect2(870, 704, 490, 30), 17, false, Style.MUTED)
	visibility_changed.connect(refresh_context)
	hide()

func add_action(parent: Node, caption: String, action: Callable, literary: bool = true) -> Button:
	var button := Style.button(parent, caption, literary)
	button.custom_minimum_size = Vector2(510, 66)
	button.pressed.connect(action)
	button.focus_entered.connect(func(): game.menu.sound.cue("move"))
	button.mouse_entered.connect(button.grab_focus)
	button.pressed.connect(func(): game.menu.sound.cue("confirm"))
	return button

func refresh_context() -> void:
	if not visible or game == null:
		return
	duel.text = "%s  /  %s" % [game.selected_characters[0].capitalize(), game.selected_characters[1].capitalize()]
	score.text = "PRÁCTICA LIBRE" if game.practice else "%d   —   %d     ·     AL MEJOR DE %d" % [game.sim.scores[0], game.sim.scores[1], game.best_of]
	note.text = "Respira. El encuentro te espera.\nRetomarás el mismo instante."
	if entrance != null:
		entrance.kill()
	modulate.a = 0.0
	entrance = create_tween()
	entrance.tween_property(self, "modulate:a", 1.0, 0.16)
