extends Control
signal closed
const Settings = preload("res://scripts/game_settings.gd")
const Style = preload("res://scripts/interface_style.gd")
const Sound = preload("res://scripts/ui_sound.gd")
var navigation: Array = []
var section_note: Label
var sound: AudioStreamPlayer
var paper: ColorRect
var elapsed: float = 0.0
var settings: RefCounted
var device_slots: Array = []
var draft: Dictionary
var tabs: TabContainer
var content_panel: PanelContainer
var resolution: OptionButton
var fullscreen: CheckButton
var vsync: CheckButton
var mute: CheckButton
var sliders: Dictionary = {}
var player_select: OptionButton
var key_buttons: Array = []
var pad_buttons: Array = []
var status: Label
var save_button: Button
var capture: Dictionary = {}
var confirmation: Control
var countdown: Label
var remaining: float = 0.0
var display_snapshot: Dictionary = {}
var audio_player: AudioStreamPlayer

func setup(preferences: RefCounted) -> void:
	settings = preferences
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = Style.control_theme()
	content_panel = PanelContainer.new()
	content_panel.size = Vector2(1600, 900)
	content_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	add_child(content_panel)
	var canvas := Control.new()
	canvas.custom_minimum_size = Vector2(1600, 900)
	content_panel.add_child(canvas)
	paper = Style.paper(canvas, Rect2(0, 0, 1600, 900))
	Style.label(canvas, "M A A I", Rect2(64, 32, 400, 45), 30, true)
	Style.label(canvas, "A TU MEDIDA", Rect2(1236, 43, 300, 30), 18, false, Style.MUTED).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	Style.label(canvas, "Opciones", Rect2(64, 94, 1400, 72), 58, true)
	Style.label(canvas, "La imagen, el sonido y el gesto. Encuentra tu forma de jugar.", Rect2(67, 172, 1400, 32), 21, false, Style.MUTED)
	var rule := ColorRect.new()
	rule.color = Color("b1b4a6")
	rule.position = Vector2(389, 244)
	rule.size = Vector2(1, 468)
	canvas.add_child(rule)
	for index in range(3):
		var nav := Style.button(canvas, ["Pantalla", "Sonido", "Controles"][index], true)
		nav.position = Vector2(64, 246 + index * 78)
		nav.size = Vector2(292, 62)
		nav.pressed.connect(func(): tabs.current_tab = index)
		nav.mouse_entered.connect(nav.grab_focus)
		navigation.append(nav)
	section_note = Style.label(canvas, "", Rect2(83, 524, 252, 180), 21, true, Style.MUTED)
	section_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tabs = TabContainer.new()
	tabs.position = Vector2(430, 224)
	tabs.size = Vector2(1106, 540)
	tabs.tabs_visible = false
	canvas.add_child(tabs)
	build_display()
	build_audio()
	build_controls()
	tabs.tab_changed.connect(func(index):
		cancel_capture()
		select_section(index))
	select_section(0)
	status = Style.label(canvas, "", Rect2(448, 770, 1070, 46), 17, false, Style.MUTED)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var footer := HBoxContainer.new()
	footer.position = Vector2(64, 826)
	footer.size = Vector2(1472, 52)
	footer.add_theme_constant_override("separation", 24)
	canvas.add_child(footer)
	button("Restaurar esta sección", footer).pressed.connect(restore_section)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(spacer)
	button("Cancelar", footer).pressed.connect(cancel)
	save_button = button("Guardar y volver", footer)
	save_button.primary = true
	save_button.pressed.connect(save_requested)
	sound = Sound.new()
	add_child(sound)
	for nav in navigation:
		nav.focus_entered.connect(func(): sound.cue("move"))
		nav.pressed.connect(func(): sound.cue("confirm"))
	var targets: Array = [resolution, sliders.Master.slider, player_select]
	for index in range(3):
		navigation[index].focus_neighbor_right = navigation[index].get_path_to(targets[index])
		targets[index].focus_neighbor_left = targets[index].get_path_to(navigation[index])
	build_confirmation()
	audio_player = AudioStreamPlayer.new()
	audio_player.stream = test_tone()
	add_child(audio_player)
	hide()

func select_section(index: int) -> void:
	for i in range(navigation.size()):
		navigation[i].selected = i == index
	section_note.text = ["Un encuadre claro.\nTodo el espacio para leer el duelo.", "Cada paso, cada filo.\nEl equilibrio está en los detalles.", "Tu mano, tu ritmo.\nCada acción en el lugar que prefieras."][index]

func panel_style() -> StyleBoxFlat:
	var style := Style.box(Color("e8e3d8"), Color("b1b4a6"), 36)
	style.content_margin_top = 30
	style.content_margin_bottom = 30
	return style

func text_label(caption: String, parent: Node, font_size: int = 21) -> Label:
	var label := Label.new()
	label.text = caption
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label

func button(caption: String, parent: Node) -> Button:
	var result := Style.button(parent, caption)
	result.mouse_entered.connect(result.grab_focus)
	result.focus_entered.connect(func():
		if sound != null: sound.cue("move"))
	result.pressed.connect(func():
		if sound != null: sound.cue("confirm"))
	return result

func page(caption: String) -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.name = caption
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	tabs.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)
	return box

func build_display() -> void:
	var box := page("Pantalla")
	text_label("Resolución de la ventana", box)
	resolution = OptionButton.new()
	resolution.custom_minimum_size.y = 44
	for size in Settings.RESOLUTIONS:
		resolution.add_item("%d × %d" % [size.x, size.y])
	box.add_child(resolution)
	resolution.item_selected.connect(func(index): draft.display.resolution = Settings.RESOLUTIONS[index])
	fullscreen = CheckButton.new()
	fullscreen.text = "Pantalla completa"
	box.add_child(fullscreen)
	fullscreen.toggled.connect(func(value):
		draft.display.fullscreen = value
		resolution.disabled = value)
	vsync = CheckButton.new()
	vsync.text = "Sincronización vertical (VSync)"
	box.add_child(vsync)
	vsync.toggled.connect(func(value): draft.display.vsync = value)
	text_label("En pantalla completa se usa la resolución del monitor.\nLa imagen conserva sus proporciones.\n\nAl guardar tendrás 12 segundos para confirmar la pantalla.", box, 19)

func build_audio() -> void:
	var box := page("Sonido")
	var names := ["Volumen general", "Música", "Efectos", "Ambiente", "Narración"]
	for i in range(Settings.AUDIO_BUSES.size()):
		var bus: String = Settings.AUDIO_BUSES[i]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		box.add_child(row)
		text_label(names[i], row).custom_minimum_size.x = 200
		var slider := HSlider.new()
		slider.min_value = 0
		slider.max_value = 100
		slider.step = 1
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.custom_minimum_size.y = 44
		row.add_child(slider)
		var percentage := text_label("", row)
		percentage.custom_minimum_size.x = 65
		slider.value_changed.connect(func(value):
			draft.audio[bus] = int(value)
			percentage.text = "%d %%" % int(value)
			Settings.apply_audio(draft.audio))
		sliders[bus] = {"slider": slider, "label": percentage}
		button("Probar", row).pressed.connect(func():
			audio_player.bus = bus
			audio_player.play())
	mute = CheckButton.new()
	mute.text = "Silenciar todo"
	box.add_child(mute)
	mute.toggled.connect(func(value):
		draft.audio.mute = value
		Settings.apply_audio(draft.audio))
	text_label("Prueba los niveles con un tono breve.\nNarración controla la voz del prólogo; Ambiente, el entorno del duelo.", box, 19)

func build_controls() -> void:
	var box := page("Controles")
	player_select = OptionButton.new()
	player_select.custom_minimum_size.y = 36
	player_select.add_item("Jugador 1")
	player_select.add_item("Jugador 2")
	box.add_child(player_select)
	player_select.item_selected.connect(func(_index):
		cancel_capture()
		refresh_bindings())
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 3)
	box.add_child(grid)
	for title in ["Acción", "Teclado", "Mando"]:
		text_label(title, grid, 18)
	for i in range(Settings.ACTION_NAMES.size()):
		text_label(Settings.ACTION_NAMES[i], grid, 19).custom_minimum_size.x = 250
		var key_button := button("", grid)
		key_button.custom_minimum_size = Vector2(250, 32)
		key_button.add_theme_font_size_override("font_size", 18)
		key_button.pressed.connect(func(): begin_capture(i, true))
		key_buttons.append(key_button)
		if i < 2:
			text_label("Stick / cruceta", grid, 19)
		else:
			var pad_button := button("", grid)
			pad_button.custom_minimum_size = Vector2(300, 32)
			pad_button.add_theme_font_size_override("font_size", 18)
			pad_button.pressed.connect(func(): begin_capture(i - 2, false))
			pad_buttons.append(pad_button)
	text_label("Selecciona una casilla y pulsa la nueva tecla o botón. Esc cancela.\nMandos por orden de conexión · Start: pausa\nReservadas: Esc, Espacio, R, F1, F2, Tab y Enter.", box, 16)

func build_confirmation() -> void:
	confirmation = Control.new()
	confirmation.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(confirmation)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.85)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	confirmation.add_child(shade)
	var panel := PanelContainer.new()
	panel.position = Vector2(370, 275)
	panel.size = Vector2(860, 330)
	panel.add_theme_stylebox_override("panel", panel_style())
	confirmation.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 22)
	panel.add_child(box)
	text_label("CONFIRMAR PANTALLA", box, 17).add_theme_color_override("font_color", Style.RED)
	text_label("¿Se ve bien la pantalla?", box, 38).add_theme_font_override("font", Style.serif())
	countdown = text_label("", box)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	box.add_child(row)
	var keep := button("Conservar y guardar", row)
	keep.primary = true
	var revert := button("Revertir", row)
	keep.pressed.connect(finish_save)
	revert.pressed.connect(revert_preview)
	keep.focus_next = keep.get_path_to(revert)
	keep.focus_previous = keep.get_path_to(revert)
	revert.focus_next = revert.get_path_to(keep)
	revert.focus_previous = revert.get_path_to(keep)
	confirmation.hide()

func open() -> void:
	draft = settings.values.duplicate(true)
	capture.clear()
	remaining = 0
	confirmation.hide()
	status.text = "Los cambios se guardan al pulsar Guardar y volver."
	tabs.current_tab = 0
	refresh_fields()
	show()
	resolution.grab_focus() if not resolution.disabled else fullscreen.grab_focus()

func refresh_fields() -> void:
	resolution.select(Settings.RESOLUTIONS.find(draft.display.resolution))
	resolution.disabled = draft.display.fullscreen
	fullscreen.set_pressed_no_signal(draft.display.fullscreen)
	vsync.set_pressed_no_signal(draft.display.vsync)
	mute.set_pressed_no_signal(draft.audio.mute)
	for bus in sliders:
		sliders[bus].slider.set_value_no_signal(draft.audio[bus])
		sliders[bus].label.text = "%d %%" % draft.audio[bus]
	refresh_bindings()

func refresh_bindings() -> void:
	var player: int = player_select.selected
	for i in range(Settings.ACTION_NAMES.size()):
		key_buttons[i].text = Settings.key_name(draft.keys[player][i])
	for i in range(Settings.DEFAULT_PAD.size()):
		pad_buttons[i].text = Settings.pad_name(draft.pads[player][i])

func begin_capture(index: int, keyboard: bool) -> void:
	cancel_capture()
	capture = {"player": player_select.selected, "index": index, "keyboard": keyboard}
	status.text = "Pulsa una tecla para %s. Esc cancela." % Settings.ACTION_NAMES[index] if keyboard else "Pulsa un botón del mando del jugador %d. Esc cancela." % (player_select.selected + 1)
	var target: Button = key_buttons[index] if keyboard else pad_buttons[index]
	target.text = "Esperando…"

func cancel_capture() -> void:
	if capture.is_empty():
		return
	capture.clear()
	refresh_bindings()
	status.text = "Asignación cancelada."

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		if confirmation.visible:
			revert_preview()
		elif not capture.is_empty():
			cancel_capture()
		else:
			cancel()
		return
	if capture.is_empty() or confirmation.visible:
		return
	# Capture before GUI navigation, so arrow keys and face buttons can be rebound.
	if event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion:
		get_viewport().set_input_as_handled()
	if not event.is_pressed() or event.is_echo():
		return
	var code: int = -1
	if capture.keyboard and event is InputEventKey:
		code = event.physical_keycode if event.physical_keycode else event.keycode
		if event.alt_pressed or event.ctrl_pressed or event.meta_pressed or event.shift_pressed or not Settings.valid_key(code):
			status.text = "Tecla reservada o combinación no admitida. Elige otra tecla; Esc cancela."
			return
	elif not capture.keyboard and event is InputEventJoypadButton:
		var pads: Array = device_slots if device_slots.size() == 2 else Input.get_connected_joypads()
		if pads.size() <= capture.player or event.device != pads[capture.player]:
			status.text = "Usa el mando asignado al jugador %d." % (capture.player + 1)
			return
		code = event.button_index
		if not Settings.valid_pad(code):
			status.text = "Botón reservado para navegación. Elige otro botón; Esc cancela."
			return
	else:
		return
	var group: String = "keys" if capture.keyboard else "pads"
	var conflict: String = Settings.binding_conflict(draft[group], capture.player, capture.index, code, capture.keyboard)
	if not conflict.is_empty():
		status.text = conflict + " Elige otra entrada; Esc cancela."
		return
	draft[group][capture.player][capture.index] = code
	capture.clear()
	refresh_bindings()
	status.text = "Control asignado. Pulsa Guardar y volver para conservarlo."

func restore_section() -> void:
	cancel_capture()
	var defaults: Dictionary = Settings.defaults()
	match tabs.current_tab:
		0: draft.display = defaults.display
		1:
			draft.audio = defaults.audio
			Settings.apply_audio(draft.audio)
		2:
			draft.keys = defaults.keys
			draft.pads = defaults.pads
	refresh_fields()
	status.text = "Valores iniciales restaurados en esta sección. Guarda para conservarlos."

func save_requested() -> void:
	cancel_capture()
	if draft.display != settings.values.display:
		display_snapshot.clear()
		if DisplayServer.get_name() != "headless":
			display_snapshot = {"mode": DisplayServer.window_get_mode(), "size": DisplayServer.window_get_size(), "position": DisplayServer.window_get_position(), "vsync": DisplayServer.window_get_vsync_mode()}
		Settings.apply_display(draft.display)
		remaining = 12.0
		countdown.text = "Se recuperará la pantalla anterior en 12 s."
		confirmation.show()
		# Prevent keyboard focus from reaching controls behind the modal.
		content_panel.hide()
		confirmation.find_children("*", "Button", true, false)[0].grab_focus()
	else:
		finish_save()

func _process(delta: float) -> void:
	if visible:
		elapsed += delta
		paper.material.set_shader_parameter("breath", elapsed)
	if not visible or not confirmation.visible:
		return
	remaining -= delta
	countdown.text = "Se recuperará la pantalla anterior en %d s." % ceili(maxf(remaining, 0))
	if remaining <= 0:
		revert_preview()

func restore_display_snapshot() -> void:
	if display_snapshot.is_empty():
		return
	DisplayServer.window_set_mode(display_snapshot.mode)
	if display_snapshot.mode == DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_size(display_snapshot.size)
		DisplayServer.window_set_position(display_snapshot.position)
	DisplayServer.window_set_vsync_mode(display_snapshot.vsync)
	display_snapshot.clear()

func revert_preview() -> void:
	Settings.apply_display(settings.values.display)
	restore_display_snapshot()
	confirmation.hide()
	content_panel.show()
	draft.display = settings.values.display.duplicate(true)
	refresh_fields()
	status.text = "Pantalla anterior recuperada. Los otros cambios siguen pendientes."
	save_button.grab_focus()

func finish_save() -> void:
	var previous: Dictionary = settings.values.duplicate(true)
	settings.values = draft.duplicate(true)
	var error: Error = settings.save_settings()
	if error != OK:
		settings.values = previous
		Settings.apply_audio(previous.audio)
		if confirmation.visible:
			Settings.apply_display(previous.display)
		restore_display_snapshot()
		confirmation.hide()
		content_panel.show()
		status.text = "No se pudieron guardar las opciones (%s). Puedes reintentar." % error_string(error)
		return
	Settings.apply_audio(settings.values.audio)
	settings.apply_bindings()
	display_snapshot.clear()
	close_panel()

func cancel() -> void:
	if confirmation.visible:
		revert_preview()
	Settings.apply_audio(settings.values.audio)
	close_panel()

func close_panel() -> void:
	capture.clear()
	audio_player.stop()
	confirmation.hide()
	content_panel.show()
	hide()
	closed.emit()

func test_tone() -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var samples := PackedByteArray()
	var count: int = 6615
	samples.resize(count * 2)
	for i in range(count):
		var envelope: float = sin(PI * float(i) / count)
		var sample: int = int(sin(TAU * 440 * i / stream.mix_rate) * envelope * 5000)
		samples.encode_s16(i * 2, sample)
	stream.data = samples
	return stream
