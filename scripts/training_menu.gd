extends Control
const Style = preload("res://scripts/interface_style.gd")
const Dummy = preload("res://scripts/training_dummy.gd")
var game
var behavior: OptionButton
var attack: OptionButton
var gap: OptionButton
var pace: OptionButton
var reset_check: CheckButton
var info_check: CheckButton
var sequence_controls: Array = []
var feedback: Label
var resume: Button
var replay: Button
const GAPS = [110, 220, 335, 440]
const PACES = [60, 100, 160]

func setup(owner_game: Node) -> void:
	game = owner_game
	size = Vector2(1600, 900)
	theme = Style.control_theme()
	var shade := ColorRect.new()
	shade.size = size
	shade.color = Color(0.035, 0.035, 0.035, 0.88)
	add_child(shade)
	Style.paper(self, Rect2(64, 54, 1472, 792))
	Style.label(self, "El espacio para aprender.", Rect2(105, 84, 1300, 65), 44, true)
	Style.label(self, "Entrena con las mismas reglas del duelo. Reinicia con R cuando quieras.", Rect2(108, 156, 1300, 30), 20, false, Style.MUTED)
	Style.label(self, "EL RIVAL · JUGADOR 2", Rect2(108, 218, 620, 30), 18, false, Style.RED)
	behavior = option("Conducta", 270, Dummy.NAMES)
	attack = option("Ataque", 330, ["1 · Punta", "2 · Ascendente", "3 · Corte bajo"])
	gap = option("Distancia inicial", 390, ["Cerca · 110", "Media · 220", "Fuera de alcance · 335", "Lejos · 440"])
	pace = option("Intervalo", 450, ["1 segundo", "1,7 segundos", "2,7 segundos"])
	Style.label(self, "Secuencia", Rect2(108, 518, 250, 36), 21)
	for i in range(3):
		var picker := OptionButton.new()
		picker.position = Vector2(360 + i * 125, 510)
		picker.size = Vector2(115, 44)
		for n in range(3): picker.add_item("Ataque %d" % (n + 1))
		picker.add_theme_font_size_override("font_size", 17)
		add_child(picker)
		sequence_controls.append(picker)
	reset_check = CheckButton.new()
	reset_check.text = "Repetir después del KO"
	reset_check.position = Vector2(108, 580)
	add_child(reset_check)
	info_check = CheckButton.new()
	info_check.text = "Mostrar distancia, fases y resultados"
	info_check.position = Vector2(108, 634)
	add_child(info_check)
	Style.label(self, "APRENDER UN INTERCAMBIO", Rect2(835, 218, 620, 30), 18, false, Style.RED)
	action("Castigar el fallo · Nao / Daichi", Vector2(835, 264), func(): exercise("punish"))
	paragraph("Provoca la estocada desde fuera de alcance. Acércate y entra antes de que Daichi recoja la lanza.", 320)
	action("Practicar el parry", Vector2(835, 402), func(): exercise("parry"))
	paragraph("Con tus personajes elegidos: espera el ataque y pulsa defensa al recibir. Mantener no protege.", 458)
	action("Grabar J2 · hasta 5 segundos", Vector2(835, 550), record)
	replay = action("Reproducir la grabación", Vector2(835, 612), play_recording)
	feedback = Style.label(self, "", Rect2(108, 710, 1350, 40), 19, false, Style.MUTED)
	resume = action("Aplicar y entrenar", Vector2(1090, 780), apply_and_resume, 380)
	action("Volver sin cambios", Vector2(108, 780), close, 340)
	hide()

func paragraph(text: String, y: float) -> void:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.position = Vector2(839, y)
	label.size = Vector2(610, 66)
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Style.MUTED)
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)

func action(text: String, pos: Vector2, callback: Callable, width: float = 610) -> Button:
	var button := Style.button(self, text)
	button.position = pos
	button.size = Vector2(width, 48)
	button.pressed.connect(callback)
	return button

func option(text: String, y: float, items: Array) -> OptionButton:
	Style.label(self, text, Rect2(108, y + 6, 245, 36), 21)
	var control := OptionButton.new()
	control.position = Vector2(360, y)
	control.size = Vector2(375, 46)
	for item in items: control.add_item(item)
	add_child(control)
	return control

func open() -> void:
	if not game.practice or game.demo: return
	game.paused = true
	game.frame_step = false
	game.pause_menu.hide()
	if game.training.recording: game.training.finish_recording()
	var t = game.training
	behavior.select(Dummy.MODES.find(t.mode))
	attack.select(maxi(0, t.move))
	gap.select(maxi(0, GAPS.find(int(t.distance))))
	pace.select(PACES.find(t.interval))
	reset_check.button_pressed = t.auto_reset
	info_check.button_pressed = t.show_info
	for i in range(3): sequence_controls[i].select(t.sequence[i])
	replay.disabled = not t.can_replay(game.sim)
	feedback.text = t.feedback
	show()
	resume.grab_focus()
	game.refresh()

func apply_values() -> bool:
	var t = game.training
	if Dummy.MODES[behavior.selected] == "replay" and not t.can_replay(game.sim):
		feedback.text = "Graba primero una secuencia con estos personajes."
		return false
	t.mode = Dummy.MODES[behavior.selected]
	t.move = attack.selected if t.mode in ["repeat", "sequence"] else -1
	t.distance = GAPS[gap.selected]
	t.interval = PACES[pace.selected]
	t.auto_reset = reset_check.button_pressed
	t.show_info = info_check.button_pressed
	t.sequence = [sequence_controls[0].selected, sequence_controls[1].selected, sequence_controls[2].selected]
	t.exercise = "free"
	return true

func apply_and_resume() -> void:
	if not apply_values(): return
	game.training.reset(game.sim)
	game.combat_audio.reset()
	hide()
	game.resume_game()

func close() -> void:
	hide()
	game.open_pause()

func exercise(id: String) -> void:
	var t = game.training
	t.recording = false
	t.mode = "repeat"
	t.move = 0
	t.exercise = id
	t.auto_reset = true
	t.show_info = true
	t.interval = 100
	if id == "punish":
		game.select_character(0, "nao")
		game.select_character(1, "daichi")
		t.distance = 335
	else:
		t.distance = clampf(game.sim.combat_profile(game.sim.fighters[1]).reaches[0] - 30, 95, 180)
	t.clear_stats()
	t.reset(game.sim)
	game.combat_audio.reset()
	hide()
	game.resume_game()

func record() -> void:
	if not apply_values(): return
	game.training.start_recording(game.sim)
	game.combat_audio.reset()
	hide()
	game.resume_game()

func play_recording() -> void:
	if not game.training.can_replay(game.sim): return
	game.training.mode = "replay"
	game.training.move = -1
	game.training.exercise = "free"
	game.training.reset(game.sim)
	game.combat_audio.reset()
	hide()
	game.resume_game()
