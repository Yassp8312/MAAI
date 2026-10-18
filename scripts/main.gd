extends Node2D
const Simulation = preload("res://scripts/combat_sim.gd")
const LocalInput = preload("res://scripts/local_input.gd")
const FighterView = preload("res://scenes/fighter_view.tscn")
const Settings = preload("res://scripts/game_settings.gd")
const SettingsMenu = preload("res://scripts/settings_menu.gd")
const PauseMenu = preload("res://scripts/pause_menu.gd")
const FrontEnd = preload("res://scripts/front_end.gd")
const CharacterCatalog = preload("res://scripts/character_catalog.gd")
const Courtyard = preload("res://scripts/courtyard.gd")
const CombatAudio = preload("res://scripts/combat_audio.gd")
const MenuMusic = preload("res://scripts/menu_music.gd")
const BattleMusic = preload("res://scripts/battle_music.gd")
var battle_music: Node
var menu_music: Node
var training_music: Node
var combat_audio: Node2D
var arena: Node2D
var arena_button: Button
var play_intro_on_start: bool = true
var selected_characters: Array = ["tsukiyo", "tsukiyo"]
var sim = Simulation.new()
var settings = Settings.new()
var controls = LocalInput.new(settings)
var options: Control
var pause_menu: PanelContainer
var move_guide: Control
var training_menu: Control
var resume_button: Button
var options_button: Button
var pause_options_button: Button
var views: Array = []
var menu: Control
var start_button: Button
var format_button: Button
var best_of: int = 3
var playing: bool = false
var debug_boxes: bool = false
var paused: bool = false
var frame_step: bool = false
var font: Font = ThemeDB.fallback_font
var capture_frames: int = 0
var practice: bool = false
var demo: bool = false
var demo_tick: int = 0
var training = preload("res://scripts/training_dummy.gd").new()
var training_button: Button
var training_panel: PanelContainer
const DEMO_STAGES = ["Guardia", "Avance", "Retroceso", "Estocada", "Corte ascendente", "Corte bajo", "Aguja aérea", "Corte aéreo", "Descendente", "Sprint y esquiva", "Derrota"]

func _ready() -> void:
	settings.load_settings()
	settings.apply_all()
	menu_music = MenuMusic.new()
	add_child(menu_music)
	battle_music = BattleMusic.new()
	add_child(battle_music)
	training_music = preload("res://scripts/training_music.gd").new()
	add_child(training_music)
	arena = Courtyard.new()
	add_child(arena)
	combat_audio = CombatAudio.new()
	add_child(combat_audio)
	combat_audio.cue_emitted.connect(battle_music.on_combat_cue)
	combat_audio.cue_emitted.connect(training_music.on_combat_cue)
	for i in range(2):
		var view = FighterView.instantiate()
		add_child(view)
		views.append(view)
	build_menu()
	if play_intro_on_start and not "--demo" in OS.get_cmdline_user_args() and not "--capture" in OS.get_cmdline_user_args():
		menu.play_boot()
	if "--demo" in OS.get_cmdline_user_args():
		start_demo()
	if "--capture" in OS.get_cmdline_user_args():
		start_game()
		sim.phase = "fight"
		capture_frames = 4
	refresh()

func build_menu() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	menu = FrontEnd.new()
	layer.add_child(menu)
	menu.setup(self)
	start_button = menu.home_buttons[0]
	options_button = menu.home_buttons[3]
	format_button = menu.format_button
	pause_menu = PauseMenu.new()
	layer.add_child(pause_menu)
	pause_menu.setup(self)
	move_guide = preload("res://scripts/move_guide.gd").new()
	layer.add_child(move_guide)
	move_guide.setup(self)
	resume_button = pause_menu.resume_button
	pause_options_button = pause_menu.options_button
	arena_button = pause_menu.arena_button
	options = SettingsMenu.new()
	layer.add_child(options)
	options.setup(settings)
	training_menu = preload("res://scripts/training_menu.gd").new()
	layer.add_child(training_menu)
	training_menu.setup(self)
	training_panel = PanelContainer.new()
	training_panel.position = Vector2(64, 220)
	training_panel.add_theme_stylebox_override("panel", preload("res://scripts/interface_style.gd").box(Color("e8e3d8")))
	layer.add_child(training_panel)
	training_button = preload("res://scripts/interface_style.gd").button(training_panel, "Entrenamiento · F3")
	training_button.custom_minimum_size = Vector2(300, 42)
	training_button.add_theme_font_size_override("font_size", 17)
	training_button.focus_mode = Control.FOCUS_NONE
	training_button.pressed.connect(training_menu.open)
	options.closed.connect(func():
		controls.block_until_release()
		if playing:
			pause_menu.show()
			pause_options_button.grab_focus()
		else:
			menu.suspended = false
			menu.show()
			if menu.screen == "home":
				options_button.grab_focus()
		refresh())

func open_options() -> void:
	if playing:
		paused = true
	frame_step = false
	menu.suspended = true
	menu.hide()
	pause_menu.hide()
	options.open()
	options.device_slots = menu.device_slots.duplicate()
	refresh()

func open_pause() -> void:
	training_menu.hide()
	paused = true
	frame_step = false
	move_guide.hide()
	if options.visible:
		return
	pause_menu.show()
	resume_button.grab_focus()
	refresh()

func resume_game() -> void:
	training_menu.hide()
	move_guide.hide()
	pause_menu.hide()
	paused = false
	frame_step = false
	controls.block_until_release()
	release_gui_focus()
	refresh()

func return_to_menu() -> void:
	training_menu.hide()
	move_guide.hide()
	frame_step = false
	menu.show_home()

func return_to_selection() -> void:
	training_menu.hide()
	move_guide.hide()
	frame_step = false
	menu.open_selection("practice" if practice else "duel")

func toggle_arena() -> void:
	select_arena((arena.arena_index + 1) % arena.NAMES.size())

func select_arena(index: int) -> void:
	arena.set_arena(index)
	arena_button.text = "Escenario: " + arena.title()
	menu.arena_picker.select(index)
	refresh()

func release_gui_focus() -> void:
	var focused := get_viewport().gui_get_focus_owner()
	if focused != null:
		focused.release_focus()

func start_game(next_mode: String = "duel") -> void:
	training_menu.hide()
	move_guide.hide()
	menu.prologue.stop()
	controls.set_devices(menu.device_slots)
	for i in range(views.size()):
		views[i].set_character(selected_characters[i])
		sim.set_character(i, selected_characters[i])
	sim.reset_match(best_of)
	combat_audio.reset()
	playing = true
	paused = false
	practice = next_mode in ["practice", "gallery"]
	demo = next_mode == "gallery"
	training = preload("res://scripts/training_dummy.gd").new()
	if practice and not demo:
		training.mode = "idle"
		training.reset(sim)
	if not practice:
		battle_music.begin_match()
	frame_step = false
	controls.block_until_release()
	menu.hide()
	pause_menu.hide()
	release_gui_focus()
	refresh()

func select_character(player: int, id: String) -> void:
	for entry in CharacterCatalog.available():
		if entry.id == id:
			selected_characters[player] = id
			views[player].set_character(id)
			sim.set_character(player, id)
			refresh()
			return

func start_demo() -> void:
	start_game("gallery")
	demo = true
	practice = true
	demo_tick = 0
	sim.phase = "fight"

func cycle_training() -> void:
	training.cycle(sim)
	combat_audio.reset()
	controls.block_until_release()
	refresh()

func demo_inputs() -> Array:
	var stage: int = int(demo_tick / 120.0) % DEMO_STAGES.size()
	var age: int = demo_tick % 120
	if age == 0:
		sim.reset_round()
		sim.phase = "fight"
		if stage == 10:
			sim.fighters[0].state = "dead"
			sim.phase = "round_over"
	var input := {"axis": 0, "action": ""}
	if stage in [1, 2] and age >= 15 and age < 70:
		input.axis = 1 if stage == 1 else -1
	elif stage in [3, 4, 5] and age == 15:
		input.action = "attack%d" % (stage - 3)
	elif stage in [6, 7, 8]:
		if age == 10:
			input.action = "jump"
		elif age == 22:
			input.action = "attack%d" % (stage - 6)
	elif stage == 9:
		if age == 10:
			input.action = "sprint"
		elif age == 55:
			input.action = "dodge"
	demo_tick += 1
	return [input, {}]

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and playing and not menu.visible and capture_frames == 0:
		open_pause()

func _unhandled_input(event: InputEvent) -> void:
	if training_menu.visible:
		if event.is_pressed() and not event.is_echo() and ((event is InputEventKey and event.keycode == KEY_ESCAPE) or (event is InputEventJoypadButton and event.button_index == JOY_BUTTON_START)):
			training_menu.close()
			get_viewport().set_input_as_handled()
		return
	if move_guide.visible:
		if event.is_pressed() and not event.is_echo() and ((event is InputEventKey and event.keycode == KEY_ESCAPE) or (event is InputEventJoypadButton and event.button_index == JOY_BUTTON_START)):
			move_guide.close()
			get_viewport().set_input_as_handled()
		return
	if options.visible:
		return
	if not event.is_pressed() or event.is_echo():
		return
	if event is InputEventJoypadButton:
		if event.button_index == JOY_BUTTON_START and playing:
			resume_game() if pause_menu.visible else open_pause()
			get_viewport().set_input_as_handled()
		return
	if not event is InputEventKey:
		return
	if event.keycode == KEY_ESCAPE:
		if playing:
			resume_game() if pause_menu.visible else open_pause()
		get_viewport().set_input_as_handled()
	elif playing and not pause_menu.visible:
		match event.keycode:
			KEY_F1:
				debug_boxes = not debug_boxes
			KEY_SPACE:
				paused = not paused
				controls.block_until_release()
			KEY_F2:
				paused = true
				frame_step = true
			KEY_F3:
				if practice and not demo and KEY_F3 not in settings.values.keys[0] and KEY_F3 not in settings.values.keys[1]:
					training_menu.open()
			KEY_R:
				if practice and not demo:
					if training.recording: training.finish_recording()
					training.reset(sim)
					combat_audio.reset()
					controls.block_until_release()
				elif sim.phase == "match_over":
					start_game()
				else:
					sim.reset_round()
	refresh()

func _physics_process(_delta: float) -> void:
	var inputs: Array = [controls.sample(0), controls.sample(1)]
	if playing and not menu.visible and not options.visible and not pause_menu.visible and (not paused or frame_step):
		if demo:
			inputs = demo_inputs()
		if practice:
			sim.scores = [0, 0]
			if not demo:
				inputs[1] = training.sample(sim, inputs[1])
		combat_audio.before_step(sim)
		if not (practice and not demo) or training.should_step(sim): sim.step(inputs)
		combat_audio.after_step(sim)
		if practice and not demo: training.after_step(sim)
		frame_step = false
		for event in sim.events:
			if event.kind == "resolution":
				log_resolution(event.detail)
		if sim.phase == "match_over" and not demo and not practice:
			menu.show_result()
	refresh()
	if capture_frames > 0:
		capture_frames -= 1
		if capture_frames == 0:
			capture_and_quit.call_deferred()

func capture_and_quit() -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://tmp/prototype.png")
	get_tree().quit()

func log_resolution(detail: Dictionary) -> void:
	var path: String = "user://duel_log.jsonl"
	var file := FileAccess.open(path, FileAccess.READ_WRITE if FileAccess.file_exists(path) else FileAccess.WRITE)
	if file != null:
		file.seek_end()
		file.store_line(JSON.stringify(detail))

func refresh() -> void:
	training_button.visible = playing and practice and not demo and not menu.visible and not paused and not options.visible and not pause_menu.visible
	training_panel.visible = training_button.visible
	if menu.visible and menu.screen in ["intro", "studio"]:
		menu_music.silence()
		battle_music.silence()
		training_music.silence()
	else:
		menu_music.set_enabled(not playing or menu.visible)
		battle_music.set_enabled(playing and not menu.visible and not practice and not demo)
		training_music.set_enabled(playing and not menu.visible and practice and not demo)
	training_music.quiet = paused
	battle_music.quiet = paused or options.visible or pause_menu.visible
	arena.present(sim, playing and not menu.visible, not paused and not options.visible and not pause_menu.visible)
	combat_audio.present(playing and not menu.visible and not options.visible, not paused and not options.visible and not pause_menu.visible)
	for i in range(views.size()):
		views[i].visible = playing
		views[i].present(sim, i, debug_boxes)
	queue_redraw()

func label_at(pos: Vector2, caption: String, size: int = 20, color: Color = Color("deded8")) -> void:
	draw_string(font, pos, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func centered(y: float, caption: String, size: int = 20, color: Color = Color("deded8")) -> void:
	var width: float = font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	label_at(Vector2((1600 - width) * 0.5, y), caption, size, color)

func _draw() -> void:
	if not playing:
		return
	if arena != null and not arena.laboratory:
		draw_courtyard_hud()
	else:
		draw_laboratory()

func draw_courtyard_hud() -> void:
	var ink := Color("282c27")
	var muted := Color("666453")
	var accent := Color("8a4032")
	draw_rect(Rect2(64, 32, 1472, 108), Color(0.94, 0.91, 0.82, 0.86))
	draw_line(Vector2(64, 140), Vector2(1536, 140), Color(0.27, 0.26, 0.21, 0.35), 1)
	for i in range(2):
		var x: float = 90 if i == 0 else 1260
		label_at(Vector2(x, 62), "JUGADOR %d" % (i + 1), 14, accent)
		draw_string(menu.serif, Vector2(x, 104), CharacterCatalog.display_name(selected_characters[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, 32, ink)
		for round_index in range(sim.target_wins):
			var point := Vector2(405 + round_index * 25 if i == 0 else 1195 - round_index * 25, 86)
			draw_arc(point, 5, 0, TAU, 24, accent, 1, true)
			if round_index < sim.scores[i]:
				draw_circle(point, 4, accent)
	centered(69, "M A A I", 27, ink)
	centered(99, arena.title().to_upper(), 14, muted)
	var mode_text: String = "ENTRENAMIENTO" if practice else "AL MEJOR DE %d" % best_of
	if demo:
		mode_text = "GALERÍA · " + DEMO_STAGES[int(maxi(0, demo_tick - 1) / 120.0) % DEMO_STAGES.size()]
	centered(173, mode_text, 15, ink)
	if practice and not demo:
		centered(195, training.hint(sim), 16, ink)
		if training.show_info:
			draw_rect(Rect2(260, 276, 1080, 102), Color(0.94, 0.94, 0.92, 0.85))
			centered(302, "Distancia %.0f · J1 %s · J2 %s" % [absf(sim.fighters[1].pos.x - sim.fighters[0].pos.x), training.phase_name(sim, sim.fighters[0]), training.phase_name(sim, sim.fighters[1])], 18, ink)
			centered(332, "Golpes %d · Desvíos %d · Recibidos %d · Ejercicio %d" % [training.hits, training.deflections, training.losses, training.successes], 17, muted)
			centered(365, training.feedback, 17, ink)
	var message: String = ""
	if paused and not pause_menu.visible and not options.visible:
		message = "Pausa · Espacio para continuar"
	elif sim.phase == "countdown":
		message = "Mide la distancia"
	elif sim.phase == "round_over":
		message = sim.result
		if practice and not demo and not sim.last_resolution.is_empty():
			for contact in sim.last_resolution.contacts:
				if contact.get("defence_expired", false):
					message = "Demasiado pronto · El bloqueo ya había terminado"
	elif sim.tick - maxi(sim.fighters[0].parry_tick, sim.fighters[1].parry_tick) < 32:
		message = "DESVÍO · Bloqueo preciso"
	if not message.is_empty():
		var width: float = font.get_string_size(message, HORIZONTAL_ALIGNMENT_LEFT, -1, 27).x + 64
		draw_rect(Rect2((1600 - width) * 0.5, 207, width, 62), Color(0.94, 0.91, 0.82, 0.9))
		centered(249, message, 27, ink)
	if debug_boxes:
		draw_rect(Rect2(64, 284, 780, 115), Color(0.94, 0.91, 0.82, 0.94))
		for i in range(2):
			var f: Dictionary = sim.fighters[i]
			var detail: String = "J%d · %s · tick %d · cuerpo %.0f" % [i + 1, f.state, f.age, sim.body(f).size.y]
			if f.state == "attack":
				detail += " · alcance %.0f" % sim.combat_profile(f).reaches[f.attack]
			label_at(Vector2(82, 313 + i * 28), detail, 17, ink)
		label_at(Vector2(82, 375), "Distancia %.0f · invulnerable %s / %s" % [absf(sim.fighters[1].pos.x - sim.fighters[0].pos.x), sim.invulnerable(sim.fighters[0]), sim.invulnerable(sim.fighters[1])], 17, ink)
	draw_rect(Rect2(64, 790, 1472, 76), Color(0.10, 0.12, 0.10, 0.79))
	label_at(Vector2(84, 819), settings.control_hint(0), 16, Color("ece5d6"))
	label_at(Vector2(84, 849), settings.control_hint(1), 16, Color("ece5d6"))
	label_at(Vector2(1160, 819), "Esc / Start · Pausa y escenario", 16, Color("ece5d6"))
	label_at(Vector2(1160, 849), "F1 · Colisiones    R · Reiniciar", 16, Color("cec5b3"))

func draw_laboratory() -> void:
	var dim := Color("585855")
	draw_rect(Rect2(0, 0, 1600, 900), Color("080809"))
	label_at(Vector2(64, 66), "M A A I", 38)
	label_at(Vector2(65, 94), "LA DISTANCIA ENTRE LA VIDA Y LA MUERTE", 12, Color("92928d"))
	label_at(Vector2(1185, 62), "DOJO  /  PROTOTIPO 0.1", 18, Color("a0a09b"))
	draw_line(Vector2(64, 119), Vector2(1536, 119), Color("333332"), 1)
	# Quiet arena; guides stay below feet, away from weapon reading.
	draw_line(Vector2(100, 712), Vector2(1500, 712), Color("777771"), 1)
	for x in range(120, 1481, 40):
		draw_line(Vector2(x, 718), Vector2(x, 725 if x % 200 == 0 else 721), Color("333332"), 1)
	draw_line(Vector2(120, 698), Vector2(120, 730), dim)
	draw_line(Vector2(1480, 698), Vector2(1480, 730), dim)
	for i in range(2):
		var x: float = 120.0 if i == 0 else 1210.0
		label_at(Vector2(x, 165), "JUGADOR %d" % (i + 1), 22)
		label_at(Vector2(x, 190), CharacterCatalog.display_name(selected_characters[i]), 15, dim)
		for r in range(sim.target_wins):
			draw_circle(Vector2(x + 8 + r * 24, 215), 5, Color("d8d8d2") if r < sim.scores[i] else Color("333332"))
		var f: Dictionary = sim.fighters[i]
		if f.state == "dead":
			# Blood appears only after confirmed lethal simulation contact.
			for n in range(9):
				draw_circle(Vector2(f.pos.x + (n - 4) * 12, 707 + sin(n * 4.0) * 3), 3 + n % 3, Color("8e2028"))
	if playing:
		if paused:
			centered(278, "PAUSA · Espacio para continuar", 26)
		elif sim.phase == "countdown":
			centered(278, "Mide la distancia", 30)
		elif sim.phase == "round_over":
			centered(278, sim.result, 28)
		elif sim.phase == "match_over":
			centered(278, "PARTIDA · Gana el jugador %d" % (1 if sim.scores[0] > sim.scores[1] else 2), 30)
			centered(315, "R · Revancha     Esc · Pausa y opciones", 19)
		else:
			centered(166, "DEMOSTRACIÓN · " + DEMO_STAGES[int(maxi(0, demo_tick - 1) / 120.0) % DEMO_STAGES.size()] if demo else ("PRÁCTICA LIBRE" if practice else "AL MEJOR DE %d" % best_of), 16, dim)
	if debug_boxes and playing:
		for i in range(2):
			var f: Dictionary = sim.fighters[i]
			var info: String = "J%d  %s · tick de acción %d" % [i + 1, f.state, f.age]
			if f.state == "attack":
				info += " · " + sim.attack_data(f).display_name
				info += " · alcance máx. %.0f" % sim.combat_profile(f).reaches[f.attack]
			info += " · cuerpo %.0f" % sim.body(f).size.y
			label_at(Vector2(64, 330 + i * 27), info, 16, Color("a4a49d"))
		label_at(Vector2(64, 389), "Distancia %.0f px  |  simulación %d  |  invulnerable: %s / %s" % [sim.fighters[1].pos.x - sim.fighters[0].pos.x, sim.tick, sim.invulnerable(sim.fighters[0]), sim.invulnerable(sim.fighters[1])], 16, dim)
		if not sim.last_resolution.is_empty():
			label_at(Vector2(64, 416), "Último impacto: tick %d · doble KO %s" % [sim.last_resolution.tick, sim.last_resolution.double_ko], 16, dim)
	if practice and not demo:
		centered(745, training.hint(sim), 16, Color("ccc7bb"))
	if sim.phase == "fight" and sim.tick - maxi(sim.fighters[0].parry_tick, sim.fighters[1].parry_tick) < 32:
		centered(278, "DESVÍO · Bloqueo preciso", 26)
	draw_line(Vector2(64, 772), Vector2(1536, 772), Color("333332"))
	label_at(Vector2(65, 809), settings.control_hint(0), 17)
	label_at(Vector2(65, 840), settings.control_hint(1), 17)
	label_at(Vector2(1100, 809), "F1 · Colisiones     Espacio · Pausa", 16, Color("a0a09b"))
	label_at(Vector2(1100, 840), "F2 · Un tick     R · Reinicio     Esc · Opciones", 16, Color("a0a09b"))
	centered(880, "Alcances propios por arma · Esc / Start: pausa · Controles configurables en Opciones", 14, dim)
