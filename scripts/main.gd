extends Node2D
const Simulation = preload("res://scripts/combat_sim.gd")
const LocalInput = preload("res://scripts/local_input.gd")
const FighterView = preload("res://scenes/fighter_view.tscn")
var sim = Simulation.new()
var controls = LocalInput.new()
var views: Array = []
var menu: PanelContainer
var menu_title: Label
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

func _ready() -> void:
	for i in range(2):
		var view = FighterView.instantiate()
		add_child(view)
		views.append(view)
	build_menu()
	if "--capture" in OS.get_cmdline_user_args():
		start_game()
		sim.phase = "fight"
		capture_frames = 4
	refresh()

func build_menu() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	menu = PanelContainer.new()
	menu.position = Vector2(480, 185)
	menu.size = Vector2(640, 520)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("101011")
	style.border_color = Color("555550")
	style.set_border_width_all(1)
	style.content_margin_left = 42
	style.content_margin_right = 42
	style.content_margin_top = 34
	style.content_margin_bottom = 34
	menu.add_theme_stylebox_override("panel", style)
	layer.add_child(menu)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 20)
	menu.add_child(box)
	menu_title = Label.new()
	menu_title.text = "El primer duelo"
	menu_title.add_theme_font_size_override("font_size", 36)
	box.add_child(menu_title)
	var description := Label.new()
	description.text = "Dos personas. Una distancia. Un solo golpe.\n\nPrototipo local con figuras provisionales.\nAmbos jugadores comparten las mismas técnicas."
	description.add_theme_font_size_override("font_size", 20)
	box.add_child(description)
	format_button = make_button("Partida · Mejor de 3", box)
	format_button.pressed.connect(func():
		best_of = 5 if best_of == 3 else 3
		format_button.text = "Partida · Mejor de %d" % best_of)
	start_button = make_button("Entrar al dojo", box)
	start_button.pressed.connect(start_game)
	var practice_button := make_button("Práctica libre · sin marcador", box)
	practice_button.pressed.connect(func():
		start_game()
		practice = true)
	var coffee := LinkButton.new()
	coffee.text = "Un café para Jorge ↗"
	coffee.uri = "https://jorge-coffee.onrender.com/"
	coffee.add_theme_font_size_override("font_size", 16)
	box.add_child(coffee)
	start_button.grab_focus()

func make_button(caption: String, parent: Node) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size.y = 46
	button.add_theme_font_size_override("font_size", 21)
	parent.add_child(button)
	return button

func start_game() -> void:
	sim.reset_match(best_of)
	playing = true
	paused = false
	practice = false
	menu.hide()
	refresh()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and playing and capture_frames == 0:
		paused = true

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if event.keycode == KEY_ESCAPE:
		playing = false
		menu.show()
		start_button.grab_focus()
	elif playing:
		match event.keycode:
			KEY_F1:
				debug_boxes = not debug_boxes
			KEY_SPACE:
				paused = not paused
			KEY_F2:
				paused = true
				frame_step = true
			KEY_R:
				if sim.phase == "match_over":
					start_game()
				else:
					sim.reset_round()
	refresh()

func _physics_process(_delta: float) -> void:
	var inputs: Array = [controls.sample(0), controls.sample(1)]
	if playing and (not paused or frame_step):
		if practice:
			sim.scores = [0, 0]
		sim.step(inputs)
		frame_step = false
		for event in sim.events:
			if event.kind == "resolution":
				log_resolution(event.detail)
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
	for i in range(views.size()):
		views[i].present(sim, i, debug_boxes)
	queue_redraw()

func label_at(pos: Vector2, caption: String, size: int = 20, color: Color = Color("deded8")) -> void:
	draw_string(font, pos, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func centered(y: float, caption: String, size: int = 20, color: Color = Color("deded8")) -> void:
	var width: float = font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	label_at(Vector2((1600 - width) * 0.5, y), caption, size, color)

func _draw() -> void:
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
		label_at(Vector2(x, 190), "Figura de prueba · espada", 15, dim)
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
			centered(315, "R · Revancha     Esc · Menú", 19)
		else:
			centered(166, "PRÁCTICA LIBRE" if practice else "AL MEJOR DE %d" % best_of, 16, dim)
	if debug_boxes and playing:
		for i in range(2):
			var f: Dictionary = sim.fighters[i]
			var info: String = "J%d  %s · tick de acción %d" % [i + 1, f.state, f.age]
			if f.state == "attack":
				info += " · " + sim.config.attacks[f.attack].display_name
			label_at(Vector2(64, 330 + i * 27), info, 16, Color("a4a49d"))
		label_at(Vector2(64, 389), "Distancia %.0f px  |  simulación %d  |  invulnerable: %s / %s" % [sim.fighters[1].pos.x - sim.fighters[0].pos.x, sim.tick, sim.invulnerable(sim.fighters[0]), sim.invulnerable(sim.fighters[1])], 16, dim)
		if not sim.last_resolution.is_empty():
			label_at(Vector2(64, 416), "Último impacto: tick %d · doble KO %s" % [sim.last_resolution.tick, sim.last_resolution.double_ko], 16, dim)
	draw_line(Vector2(64, 772), Vector2(1536, 772), Color("333332"))
	label_at(Vector2(65, 809), "J1   A / D mover    W salto    S sprint    Q esquiva    F / G / H ataques", 17)
	label_at(Vector2(65, 840), "J2   ← / → mover    ↑ salto    ↓ sprint    K esquiva    U / I / O ataques", 17)
	label_at(Vector2(1100, 809), "F1 · Colisiones     Espacio · Pausa", 16, Color("a0a09b"))
	label_at(Vector2(1100, 840), "F2 · Un tick     R · Reinicio     Esc · Menú", 16, Color("a0a09b"))
	centered(880, "60 Hz · Valores experimentales · Dos mandos compatibles: A salto / RB sprint / LB esquiva / X Y B ataques", 14, dim)
