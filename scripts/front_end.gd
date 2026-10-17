extends Control
const Catalog = preload("res://scripts/character_catalog.gd")
const Portrait = preload("res://scripts/ui_portrait.gd")
const Sound = preload("res://scripts/ui_sound.gd")
const InkButton = preload("res://scripts/ink_button.gd")
const Prologue = preload("res://scripts/prologue.gd")
var prologue: Control
const PAPER = Color("e8e3d8")
const INK = Color("202321")
const MUTED = Color("62665f")
const RED = Color("983e35")
const NOTES = {
	"tsukiyo": ["La calma antes del corte.", "Espada larga · distancia intermedia"],
	"ren": ["Un paso firme. Ningún gesto de más.", "Espada larga · presión frontal"],
	"daichi": ["Mantén al rival al otro lado del filo.", "Lanza yari · mayor alcance"],
	"nao": ["Acércate. Encuentra la abertura.", "Dos tantō · combate cercano"],
	"sayo": ["Cada gesto tiene una intención.", "Abanicos de guerra · alcance corto"]
}
var game
var screen: String = "title"
var mode: String = "duel"
var ready_players: Array = [false, false]
var roster: Array = []
var indices: Array = [0, 0]
var pages: Dictionary = {}
var roster_buttons: Array = [[], []]
var ready_buttons: Array = []
var portraits: Array = []
var names: Array = []
var weapons: Array = []
var descriptions: Array = []
var seals: Array = []
var hints: Array = []
var versus_portraits: Array = []
var versus_names: Array = []
var home_buttons: Array = []
var result_buttons: Array = []
var format_button: Button
var mode_label: Label
var notice: Label
var result_title: Label
var result_score: Label
var result_portrait: Control
var pulse_label: Label
var sound: AudioStreamPlayer
var serif: SystemFont
var page_tween: Tween
var elapsed: float = 0
var transition_remaining: float = 0
var device_slots: Array = [-1, -1]
var axis_latches: Dictionary = {}
var active_page: Control
var suspended: bool = false
var title_age: float = 0
const TITLE_HOLD: float = 3.6
const TITLE_FADE: float = 0.9
var title_index: int = 0
var title_clock: float = 0
var title_slides: Array = []
var paper_material: ShaderMaterial
var ambient_offset := Vector2.ZERO
var home_portrait: Control
var home_name: Label
var home_note: Label
var home_description: Label
var home_section: Label
var focus_y: float = 345
var focus_target_y: float = 345
var selection_pulse: Array = [0.0, 0.0]
const HOME_NOTES = [
	["El encuentro", "Dos personas. Un solo golpe puede decidirlo todo."],
	["La disciplina", "Explora cada arma y encuentra tu distancia."],
	["El gesto", "Observa el movimiento antes de llevarlo al duelo."],
	["A tu medida", "Ajusta imagen, sonido y controles."],
	["Hasta el próximo encuentro", "La distancia también se aprende en el silencio."]
]

func setup(owner_game: Node) -> void:
	game = owner_game
	size = Vector2(1600, 900)
	roster = Catalog.available()
	serif = SystemFont.new()
	serif.font_names = PackedStringArray(["Georgia", "Noto Serif", "DejaVu Serif", "serif"])
	var paper := ColorRect.new()
	paper.size = size
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	paper.show_behind_parent = true
	paper_material = ShaderMaterial.new()
	paper_material.shader = preload("res://art/ui/paper.gdshader")
	paper.material = paper_material
	add_child(paper)
	sound = Sound.new()
	add_child(sound)
	build_title()
	build_home()
	build_selection()
	build_versus()
	build_result()
	var intro_page := page("intro")
	prologue = Prologue.new()
	intro_page.add_child(prologue)
	prologue.setup(serif)
	prologue.finished.connect(func(): show_screen("title"))
	sync_devices()
	Input.joy_connection_changed.connect(connection_changed)
	show_screen("title")

func page(id: String) -> Control:
	var node := Control.new()
	node.size = size
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(node)
	pages[id] = node
	return node

func text(parent: Node, caption: String, rect: Rect2, font_size: int, color: Color = INK, literary: bool = false) -> Label:
	var label := Label.new()
	label.text = caption
	label.position = rect.position
	label.size = rect.size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if literary:
		label.add_theme_font_override("font", serif)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func style(background: Color, border: Color, width: int = 1) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = background
	box.border_color = border
	box.set_border_width_all(width)
	box.content_margin_left = 18
	box.content_margin_right = 18
	return box

func button(parent: Node, caption: String, rect: Rect2, callback: Callable, small: bool = false) -> Button:
	var b := InkButton.new()
	b.quiet = small
	b.text = caption
	b.position = rect.position
	b.size = rect.size
	b.add_theme_font_size_override("font_size", 20 if small else 27)
	if not small:
		b.add_theme_font_override("font", serif)
	b.pressed.connect(callback)
	b.mouse_entered.connect(func():
		if b.focus_mode != Control.FOCUS_NONE:
			b.grab_focus()
		else:
			sound.cue("move"))
	b.focus_entered.connect(func(): sound.cue("move"))
	parent.add_child(b)
	return b

func portrait(parent: Node, rect: Rect2, id: String, mirror: bool = false, head: bool = false) -> Control:
	var p := Portrait.new()
	p.position = rect.position
	p.size = rect.size
	p.head_only = head
	p.mirrored = mirror
	parent.add_child(p)
	p.set_character(id)
	return p

func heading(parent: Node, step: String, title: String, subtitle: String) -> void:
	text(parent, "M A A I", Rect2(64, 32, 300, 45), 30, INK, true)
	text(parent, step, Rect2(1080, 42, 456, 28), 18, MUTED).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	text(parent, title, Rect2(64, 100, 1200, 72), 58, INK, true)
	text(parent, subtitle, Rect2(67, 179, 1400, 32), 21, MUTED)

func build_title() -> void:
	var p := page("title")
	for i in range(2):
		var slide := Control.new()
		slide.size = Vector2(690, 850)
		slide.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(slide)
		var drawing := portrait(slide, Rect2(0, 25, 690, 735), roster[i % roster.size()].id)
		var caption := text(slide, "", Rect2(0, 765, 690, 44), 36, INK, true)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var weapon := text(slide, "", Rect2(0, 812, 690, 26), 18, MUTED)
		weapon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_slides.append({"node": slide, "drawing": drawing, "caption": caption, "weapon": weapon})
	refresh_title_slides()
	advance_title(0)
	text(p, "E L  A R T E  D E  L A  D I S T A N C I A", Rect2(112, 160, 650, 35), 18, MUTED)
	text(p, "M A A I", Rect2(100, 235, 800, 180), 132, INK, true)
	text(p, "La distancia entre la vida\ny la muerte.", Rect2(112, 440, 650, 96), 31, INK, true)
	var enter := button(p, "Comenzar", Rect2(110, 630, 510, 76), func(): show_home())
	enter.ordinal = "01"
	enter.primary = true
	enter.add_theme_font_size_override("font_size", 33)
	pulse_label = text(p, "Pulsa una tecla o un botón", Rect2(128, 725, 580, 32), 19, MUTED)
	text(p, "ACERO  /  SILENCIO  /  UN INSTANTE", Rect2(112, 835, 600, 30), 16, MUTED)

func refresh_title_slides() -> void:
	for i in range(title_slides.size()):
		var entry: Dictionary = roster[(title_index + i) % roster.size()]
		var slide: Dictionary = title_slides[i]
		slide.drawing.set_character(entry.id)
		# Both layers are ready before fading; the carousel owns their opacity.
		slide.drawing.reveal = 1
		slide.caption.text = entry.name
		slide.weapon.text = entry.weapon

func advance_title(delta: float) -> void:
	title_clock += delta
	var duration: float = TITLE_HOLD + TITLE_FADE
	if title_clock >= duration:
		var steps: int = int(title_clock / duration)
		title_clock = fmod(title_clock, duration)
		title_index = (title_index + steps) % roster.size()
		# Reuse the incoming layer so its gentle breathing stays continuous.
		if steps % 2 == 1:
			title_slides.reverse()
		refresh_title_slides()
	var blend: float = smoothstep(TITLE_HOLD, duration, title_clock)
	for i in range(title_slides.size()):
		var slide: Control = title_slides[i].node
		slide.modulate.a = 1 - blend if i == 0 else blend
		slide.position = Vector2(760 + (-36 * blend if i == 0 else 36 * (1 - blend)), 0) + ambient_offset
		slide.visible = slide.modulate.a > 0

func build_home() -> void:
	var p := page("home")
	home_portrait = portrait(p, Rect2(810, 75, 660, 675), "tsukiyo")
	home_name = text(p, "Tsukiyo", Rect2(810, 765, 660, 45), 36, INK, true)
	home_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	home_note = text(p, NOTES.tsukiyo[0], Rect2(785, 816, 710, 28), 20, MUTED, true)
	home_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text(p, "EL ARTE DE LA DISTANCIA", Rect2(108, 80, 650, 30), 17, MUTED)
	text(p, "M A A I", Rect2(100, 125, 720, 120), 92, INK, true)
	text(p, "Antes del golpe, la distancia.", Rect2(108, 255, 650, 44), 28, MUTED, true)
	var captions = ["Duelo local", "Práctica libre", "Galería de movimientos", "Opciones", "Salir"]
	var actions = [func(): open_selection("duel"), func(): open_selection("practice"), func(): open_selection("gallery"), func(): game.open_options(), func(): get_tree().quit()]
	for i in range(captions.size()):
		var b := button(p, captions[i], Rect2(108, 345 + i * 73, 565, 64), actions[i])
		b.ordinal = "%02d" % (i + 1)
		b.focus_entered.connect(func(): describe_home(i))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		home_buttons.append(b)
	home_section = text(p, "", Rect2(110, 735, 610, 28), 17, RED)
	home_description = text(p, "", Rect2(110, 774, 610, 50), 20, MUTED)
	home_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var coffee := LinkButton.new()
	coffee.text = "Un café para Jorge ↗"
	coffee.uri = "https://jorge-coffee.onrender.com/"
	coffee.position = Vector2(108, 835)
	coffee.add_theme_color_override("font_color", MUTED)
	coffee.add_theme_font_size_override("font_size", 18)
	p.add_child(coffee)
	button(p, "Presentación", Rect2(1340, 852, 210, 38), func(): show_screen("title"), true)
	button(p, "Volver a ver el prólogo", Rect2(790, 852, 340, 38), play_prologue, true)

func play_prologue() -> void:
	game.playing = false
	show_screen("intro")
	prologue.start()
	game.refresh()

func describe_home(index: int) -> void:
	focus_target_y = 345 + index * 73
	if home_description != null:
		home_section.text = HOME_NOTES[index][0].to_upper()
		home_description.text = HOME_NOTES[index][1]

func build_selection() -> void:
	var p := page("select")
	heading(p, "01 / ELEGIR COMBATIENTES", "Elige tu distancia.", "Dos voluntades frente a frente. Cada arma exige una distancia distinta.")
	for player in range(2):
		var x: float = 64 + player * 758
		seals.append(text(p, "JUGADOR %d / ELIGIENDO" % (player + 1), Rect2(x + 24, 245, 350, 30), 19, RED))
		names.append(text(p, "", Rect2(x + 24, 298, 340, 76), 52, INK, true))
		weapons.append(text(p, "", Rect2(x + 27, 382, 330, 32), 21, RED))
		var desc := text(p, "", Rect2(x + 27, 432, 300, 82), 23, MUTED, true)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		descriptions.append(desc)
		portraits.append(portrait(p, Rect2(x + 350, 225, 340, 325), "tsukiyo", player == 1))
		for index in range(roster.size()):
			var entry: Dictionary = roster[index]
			var b := button(p, "", Rect2(x + 24 + index * 134, 554, 124, 110), func(): choose(player, index), true)
			b.card = true
			b.focus_mode = Control.FOCUS_NONE
			portrait(b, Rect2(4, 1, 116, 78), entry.id, player == 1, true)
			text(b, entry.name, Rect2(0, 80, 124, 28), 19).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			roster_buttons[player].append(b)
		var ready_button := button(p, "Confirmar", Rect2(x + 24, 683, 360, 54), func(): confirm_player(player))
		ready_button.focus_mode = Control.FOCUS_NONE
		ready_buttons.append(ready_button)
		hints.append(text(p, "", Rect2(x + 24, 751, 690, 28), 18, MUTED))
	mode_label = text(p, "", Rect2(1040, 125, 496, 35), 20, RED)
	mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	format_button = button(p, "Mejor de 3", Rect2(1210, 824, 326, 46), toggle_format, true)
	format_button.focus_mode = Control.FOCUS_NONE
	button(p, "← Volver al menú", Rect2(64, 824, 285, 46), show_home, true).focus_mode = Control.FOCUS_NONE
	notice = text(p, "", Rect2(390, 830, 780, 40), 18, RED)
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func build_versus() -> void:
	var p := page("versus")
	heading(p, "02 / EL ENCUENTRO", "La distancia lo decide todo.", "")
	for player in range(2):
		var x: float = 100 + 850 * player
		versus_portraits.append(portrait(p, Rect2(x, 235, 550, 480), "tsukiyo", player == 1))
		versus_names.append(text(p, "", Rect2(x, 735, 550, 70), 48, INK, true))
		versus_names[player].horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text(p, "対", Rect2(715, 380, 170, 130), 90, RED, true).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text(p, "FRENTE A FRENTE", Rect2(640, 525, 320, 35), 20, MUTED).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text(p, "Esc / B · volver a elegir", Rect2(590, 840, 420, 28), 18, MUTED).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func build_result() -> void:
	var p := page("result")
	heading(p, "03 / DESPUÉS DEL SILENCIO", "El duelo ha terminado.", "")
	result_portrait = portrait(p, Rect2(850, 200, 600, 610), "tsukiyo")
	result_title = text(p, "", Rect2(100, 290, 750, 90), 55, INK, true)
	result_score = text(p, "", Rect2(108, 405, 650, 56), 29, RED)
	result_buttons.append(button(p, "Revancha", Rect2(108, 520, 530, 60), rematch))
	result_buttons.append(button(p, "Elegir otros personajes", Rect2(108, 598, 530, 60), func(): open_selection("duel")))
	result_buttons.append(button(p, "Volver al menú", Rect2(108, 676, 530, 60), show_home))

func show_screen(id: String) -> void:
	if prologue != null and id != "intro":
		prologue.stop()
	if page_tween != null:
		page_tween.kill()
	screen = id
	suspended = false
	show()
	for key in pages:
		pages[key].visible = key == id
	active_page = pages[id]
	active_page.modulate.a = 0
	active_page.position = Vector2(0, 10)
	page_tween = create_tween().set_parallel(true)
	page_tween.tween_property(active_page, "modulate:a", 1.0, 0.22)
	page_tween.tween_property(active_page, "position:y", 0.0, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if id == "title":
		var order: int = 0
		for child in active_page.get_children():
			if child is Label or child is InkButton:
				child.modulate.a = 0
				page_tween.tween_property(child, "modulate:a", 1.0, 0.55).set_delay(0.08 * order)
				order += 1
	game.release_gui_focus()
	for child in active_page.get_children():
		if child is InkButton:
			child.entrance = 0
	if id == "home":
		home_buttons[0].grab_focus()
	elif id == "result":
		result_buttons[0].grab_focus()
	elif id == "title":
		title_age = 0
	queue_redraw()

func show_home() -> void:
	var featured: Dictionary = roster[title_index]
	home_portrait.set_character(featured.id)
	home_name.text = featured.name
	home_note.text = NOTES[featured.id][0]
	game.playing = false
	game.demo = false
	game.paused = false
	game.pause_menu.hide()
	transition_remaining = 0
	sound.cue("back" if screen != "title" else "confirm")
	show_screen("home")
	game.refresh()

func open_selection(next_mode: String = "duel") -> void:
	game.playing = false
	game.demo = false
	game.paused = false
	game.pause_menu.hide()
	mode = next_mode
	ready_players = [false, false]
	transition_remaining = 0
	notice.text = "Mando: ← / → elegir · A listo · B cancelar"
	sync_devices()
	for player in range(2):
		for index in range(roster.size()):
			if roster[index].id == game.selected_characters[player]:
				indices[player] = index
		update_player(player)
	mode_label.text = {"duel": "DUELO LOCAL", "practice": "PRÁCTICA LIBRE", "gallery": "GALERÍA DE MOVIMIENTOS"}[mode]
	format_button.visible = mode == "duel"
	format_button.text = "Mejor de %d · Tab / Y" % game.best_of
	sound.cue("confirm")
	show_screen("select")
	game.refresh()

func choose(player: int, index: int) -> void:
	if screen != "select" or ready_players[player]:
		return
	indices[player] = posmod(index, roster.size())
	selection_pulse[player] = 1.0
	game.select_character(player, roster[indices[player]].id)
	update_player(player)
	sound.cue("move")

func update_player(player: int) -> void:
	var entry: Dictionary = roster[indices[player]]
	names[player].text = entry.name
	weapons[player].text = entry.weapon.to_upper()
	descriptions[player].text = NOTES[entry.id][0]
	portraits[player].set_character(entry.id)
	seals[player].text = "JUGADOR %d / %s" % [player + 1, "LISTO" if ready_players[player] else "ELIGIENDO"]
	ready_buttons[player].text = "Listo ✓ · cancelar" if ready_players[player] else "Confirmar personaje"
	ready_buttons[player].selected = ready_players[player]
	var keys: Array = game.settings.values.keys[player]
	hints[player].text = "%s / %s elegir   ·   %s confirmar   ·   %s cancelar" % [game.settings.key_name(keys[0]), game.settings.key_name(keys[1]), game.settings.key_name(keys[5]), game.settings.key_name(keys[4])]
	for i in range(roster_buttons[player].size()):
		var b: Button = roster_buttons[player][i]
		b.selected = i == indices[player]
		b.add_theme_stylebox_override("normal", style(Color("f7f2e8") if i == indices[player] else Color(1, 1, 1, 0.05), RED if i == indices[player] else Color("b8b7ac"), 2 if i == indices[player] else 1))
	queue_redraw()

func confirm_player(player: int) -> void:
	if screen != "select":
		return
	ready_players[player] = not ready_players[player]
	selection_pulse[player] = 1.0
	update_player(player)
	sound.cue("confirm" if ready_players[player] else "back")
	if ready_players[0] and ready_players[1]:
		for i in range(2):
			versus_portraits[i].set_character(game.selected_characters[i])
			versus_names[i].text = Catalog.display_name(game.selected_characters[i])
		transition_remaining = 1.8
		show_screen("versus")
		sound.cue("begin")

func cancel_player(player: int) -> void:
	if screen == "versus":
		transition_remaining = 0
		ready_players[player] = false
		update_player(player)
		show_screen("select")
	elif screen == "select":
		if ready_players[player]:
			ready_players[player] = false
			update_player(player)
		else:
			show_home()
	sound.cue("back")

func toggle_format() -> void:
	if screen != "select" or mode != "duel":
		return
	game.best_of = 5 if game.best_of == 3 else 3
	format_button.text = "Mejor de %d · Tab / Y" % game.best_of
	ready_players = [false, false]
	for player in range(2):
		update_player(player)
	sound.cue("move")

func launch() -> void:
	transition_remaining = 0
	hide()
	if mode == "gallery":
		game.start_demo()
	else:
		game.start_game()
		game.practice = mode == "practice"

func show_result() -> void:
	var winner: int = 0 if game.sim.scores[0] > game.sim.scores[1] else 1
	result_title.text = "%s vence." % Catalog.display_name(game.selected_characters[winner])
	result_score.text = "JUGADOR %d    ·    %d — %d" % [winner + 1, game.sim.scores[0], game.sim.scores[1]]
	result_portrait.set_character(game.selected_characters[winner])
	show_screen("result")
	sound.cue("begin")

func rematch() -> void:
	sound.cue("confirm")
	game.start_game()

func sync_devices() -> void:
	var connected: Array = Input.get_connected_joypads()
	for i in range(2):
		if device_slots[i] not in connected:
			device_slots[i] = -1
	for device in connected:
		if device not in device_slots and -1 in device_slots:
			device_slots[device_slots.find(-1)] = device
	axis_latches.clear()

func connection_changed(device: int, connected: bool) -> void:
	var player: int = device_slots.find(device)
	if not connected and player >= 0 and game.playing and not visible:
		game.open_pause()
		game.controls.block_until_release()
	if not connected and player >= 0 and not game.playing and screen in ["select", "versus"]:
		ready_players[player] = false
		transition_remaining = 0
		update_player(player)
		if is_visible_in_tree():
			show_screen("select")
		else:
			screen = "select"
		notice.text = "Mando J%d desconectado. Puedes continuar con el teclado." % (player + 1)
	sync_devices()
	game.controls.set_devices(device_slots)
	if game.options != null:
		game.options.device_slots = device_slots.duplicate()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and game != null and game.capture_frames == 0 and visible and screen == "versus":
		cancel_player(0)

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or suspended or game.options.visible:
		return
	if event is InputEventKey and event.echo:
		return
	if screen == "intro":
		prologue.handle_input(event)
		return
	if screen == "title":
		if title_age > 0.25 and event.is_pressed() and (event is InputEventKey or event is InputEventJoypadButton):
			show_home()
			get_viewport().set_input_as_handled()
		return
	if screen in ["select", "versus"]:
		if handle_selection_input(event):
			get_viewport().set_input_as_handled()
		return
	# Shared menus use one focus owner; selection above has independent cursors.
	var direction: int = 0
	var accept: bool = false
	var back: bool = false
	if event is InputEventKey and event.pressed:
		direction = -1 if event.keycode in [KEY_UP, KEY_W] else (1 if event.keycode in [KEY_DOWN, KEY_S] else 0)
		accept = event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]
		back = event.keycode == KEY_ESCAPE
	elif event is InputEventJoypadButton and event.pressed:
		direction = -1 if event.button_index == JOY_BUTTON_DPAD_UP else (1 if event.button_index == JOY_BUTTON_DPAD_DOWN else 0)
		accept = event.button_index == JOY_BUTTON_A
		back = event.button_index == JOY_BUTTON_B
	elif event is InputEventJoypadMotion and event.axis == JOY_AXIS_LEFT_Y:
		direction = stick_step(event)
	var choices: Array = home_buttons if screen == "home" else result_buttons
	if direction != 0:
		var index: int = choices.find(get_viewport().gui_get_focus_owner())
		choices[posmod(index + direction, choices.size())].grab_focus()
	elif accept:
		var focused := get_viewport().gui_get_focus_owner()
		if focused is LinkButton:
			return # Let the native link activation open its URI.
		if focused is Button:
			focused.pressed.emit()
	elif back:
		show_screen("title") if screen == "home" else show_home()
	if direction != 0 or accept or back:
		get_viewport().set_input_as_handled()

func stick_step(event: InputEventJoypadMotion) -> int:
	var key: String = "%d:%d" % [event.device, event.axis]
	if absf(event.axis_value) < 0.25:
		axis_latches[key] = false
	if absf(event.axis_value) > 0.55 and not axis_latches.get(key, false):
		axis_latches[key] = true
		return 1 if event.axis_value > 0 else -1
	return 0

func handle_selection_input(event: InputEvent) -> bool:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_TAB and screen == "select":
			toggle_format()
			return true
		if event.keycode == KEY_ESCAPE:
			if screen == "versus":
				cancel_player(0)
			else:
				show_home()
			return true
		for player in range(2):
			var keys: Array = game.settings.values.keys[player]
			var code: int = event.physical_keycode if event.physical_keycode else event.keycode
			if code == keys[4]:
				cancel_player(player)
				return true
			if screen == "select":
				if code in [keys[0], keys[1]]:
					choose(player, indices[player] + (1 if code == keys[1] else -1))
					return true
				if code == keys[5]:
					confirm_player(player)
					return true
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
		var player: int = device_slots.find(event.device)
		if player < 0:
			return false
		if event is InputEventJoypadButton and event.pressed:
			if event.button_index == JOY_BUTTON_Y and screen == "select":
				toggle_format()
				return true
			if event.button_index == JOY_BUTTON_B:
				cancel_player(player)
				return true
			if screen == "select":
				if event.button_index == JOY_BUTTON_A:
					confirm_player(player)
					return true
				if event.button_index in [JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT]:
					choose(player, indices[player] + (1 if event.button_index == JOY_BUTTON_DPAD_RIGHT else -1))
					return true
		elif event is InputEventJoypadMotion and event.axis == JOY_AXIS_LEFT_X:
			var step: int = stick_step(event)
			if screen == "select" and step != 0:
				choose(player, indices[player] + step)
			return true
	return false

func _process(delta: float) -> void:
	if not is_visible_in_tree() or suspended:
		return
	elapsed += delta
	paper_material.set_shader_parameter("breath", elapsed)
	var pointer: Vector2 = (get_local_mouse_position() - size * 0.5) / (size * 0.5)
	pointer = pointer.clamp(Vector2(-1, -1), Vector2(1, 1))
	ambient_offset = ambient_offset.lerp(pointer * 5, 1 - exp(-delta * 2))
	focus_y = lerpf(focus_y, focus_target_y, 1 - exp(-delta * 12))
	for player in range(2):
		selection_pulse[player] = maxf(0, selection_pulse[player] - delta * 1.6)
	if screen == "home":
		home_portrait.position = Vector2(810, 75) + ambient_offset
	title_age += delta
	if screen == "title":
		advance_title(delta)
	pulse_label.modulate.a = 0.72 + sin(elapsed * 2) * 0.18
	if screen == "versus" and transition_remaining > 0:
		transition_remaining -= delta
		if transition_remaining <= 0:
			launch()
	queue_redraw()

func _draw() -> void:
	if screen == "intro":
		return
	# Low-contrast ink washes anchor the composition; text stays on clear paper.
	for layer in range(3):
		var wash := PackedVector2Array([Vector2(0, 900)])
		for i in range(65):
			var x: float = i * 25
			var height: float = 864 + layer * 10 + sin(i * 0.17 + layer * 2) * 14 + sin(i * 0.43) * 4
			wash.append(Vector2(x, minf(height, 896)))
		wash.append(Vector2(1600, 900))
		draw_colored_polygon(wash, Color(0.24, 0.29, 0.26, 0.026))
	# Air carries a handful of ink flecks; slow enough to leave reading undisturbed.
	for i in range(74):
		var x: float = fmod(i * 187.7 + sin(elapsed * 0.12 + i) * 9, 1600)
		var y: float = fmod(i * 79.3 + elapsed * (1 + i % 3), 900)
		draw_circle(Vector2(x, y), 0.65 + i % 2, Color(0.2, 0.22, 0.2, 0.10))
	if screen in ["home", "title", "result"]:
		draw_enso(Vector2(1130, 435) + ambient_offset * 0.5, 316, 0.19)
		for mote in range(5):
			var travel: float = fmod(elapsed * (9 + mote) + mote * 245, 1100)
			var point := Vector2(660 + travel * 0.8, 760 - travel * 0.61 + sin(elapsed * 0.3 + mote) * 24)
			var angle: float = sin(elapsed * 0.5 + mote) * 0.8
			var leaf := PackedVector2Array()
			for offset in [Vector2(-6, 0), Vector2(0, -2), Vector2(6, 0), Vector2(0, 2)]:
				leaf.append(point + offset.rotated(angle))
			draw_colored_polygon(leaf, Color(INK, 0.12))
		# A short vermilion stroke gives the title a single, deliberate accent.
		if screen == "title":
			draw_line(Vector2(113, 130), Vector2(169, 130), RED, 4)
			draw_line(Vector2(113, 577), Vector2(166, 577), Color(RED, 0.7), 1.5)
			draw_line(Vector2(177, 577), Vector2(620, 577), Color(INK, 0.16), 1)
		if screen == "home":
			var cursor := Vector2(84, focus_y + 32)
			draw_colored_polygon(PackedVector2Array([cursor + Vector2(0, -6), cursor + Vector2(4, 0), cursor + Vector2(0, 6), cursor - Vector2(4, 0)]), RED)
	if screen == "select":
		for player in range(2):
			var rect := Rect2(64 + player * 758, 227, 714, 566)
			draw_rect(rect, Color(1, 1, 1, 0.16))
			draw_enso(Vector2(rect.position.x + 520, 390), 142 + selection_pulse[player] * 5, 0.19 if ready_players[player] else 0.10)
			draw_line(rect.position, rect.position + Vector2(714, 0), Color(INK, 0.26), 1)
			draw_line(rect.position, rect.position + Vector2(100 if ready_players[player] else 36, 0), RED, 4)
			draw_line(rect.end - Vector2(714, 0), rect.end, Color(INK, 0.15), 1)
			if ready_players[player]:
				var seal := Vector2(rect.position.x + 650, 260)
				draw_circle(seal, 15, Color(RED, 0.9))
				draw_polyline(PackedVector2Array([seal + Vector2(-7, 0), seal + Vector2(-2, 5), seal + Vector2(8, -6)]), PAPER, 2, true)
		draw_line(Vector2(64, 91), Vector2(1536, 91), Color("b5b6aa"))
	if screen == "versus":
		draw_enso(Vector2(375, 475), 235, 0.13)
		draw_enso(Vector2(1225, 475), 235, 0.13)
		draw_line(Vector2(720, 610), Vector2(880, 610), Color("b5b6aa"), 1)
		draw_line(Vector2(720, 610), Vector2(720 + 160 * (1 - clampf(transition_remaining / 1.8, 0, 1)), 610), RED, 3)

func draw_enso(center: Vector2, radius: float, opacity: float) -> void:
	# Layered, tapered dry-brush strands. Fixed irregularity, slow breathing only.
	var breath: float = sin(elapsed * 0.65) * 1.8
	for strand in range(11):
		var stroke := PackedVector2Array()
		for segment in range(181):
			var t: float = float(segment) / 180
			var angle: float = -1.9 + strand * 0.018 + t * (5.97 - strand * 0.045)
			var taper: float = pow(sin(t * PI), 0.6)
			var irregularity: float = sin(angle * 7 + strand * 0.4) * 0.8 + sin(angle * 19) * 0.35
			var r: float = radius + (strand - 5) * taper * 1.1 + irregularity + breath
			stroke.append(center + Vector2(cos(angle), sin(angle)) * r)
		draw_polyline(stroke, Color(INK, opacity * (0.38 + strand % 3 * 0.12)), 0.8 + strand % 2 * 0.35, true)
