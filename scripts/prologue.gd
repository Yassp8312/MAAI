extends Control
## Illustrated opening of the game, independent of rounds and combat simulation.
signal finished
const VOICE = preload("res://art/intro/prologo-es.mp3")
const MUSIC = preload("res://art/intro/prologue-music.ogg")
const LANDSCAPE = preload("res://art/intro/war-road-v01.png")
const LEAD: float = 0.8
const TAIL: float = 3.4
const CHAPTERS = [0.0, 6.6, 12.55, 18.2, 20.9, 23.1, 26.55, 35.0, 42.45]
const INK = Color("101210")
const PAPER = Color("e8e1d3")
const RED = Color("a55446")
var voice: AudioStreamPlayer
var music: AudioStreamPlayer
var serif: Font
var small_font: Font = ThemeDB.fallback_font
var portraits: Dictionary = {}
var captions: Array = []
var subtitle: Label
var skip: Button
var pause_button: Button
var subtitles_button: Button
var time: float = 0
var active: bool = false
var paused: bool = false
var manual: bool = false
var started_voice: bool = false
var subtitles_enabled: bool = true
var has_focus: bool = true
var clean_preview: bool = false
var mist: GradientTexture2D
var vignette: GradientTexture2D

func setup(typeface: Font) -> void:
	serif = typeface
	# Soft ink washes integrate the masters into the same landscape, without panels.
	mist = GradientTexture2D.new()
	mist.width = 2
	mist.height = 256
	mist.fill_from = Vector2(0, 0)
	mist.fill_to = Vector2(0, 1)
	mist.gradient = Gradient.new()
	mist.gradient.offsets = PackedFloat32Array([0, 0.54, 0.72, 0.89, 1])
	mist.gradient.colors = PackedColorArray([Color(INK, 0), Color(INK, 0), Color(INK, 0.18), Color(INK, 0.97), INK])
	vignette = GradientTexture2D.new()
	vignette.width = 256
	vignette.height = 256
	vignette.fill = GradientTexture2D.FILL_RADIAL
	vignette.fill_from = Vector2(0.5, 0.45)
	vignette.fill_to = Vector2(1, 0.95)
	vignette.gradient = Gradient.new()
	vignette.gradient.set_color(0, Color(INK, 0))
	vignette.gradient.set_color(1, Color(INK, 0.72))
	size = Vector2(1600, 900)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for id in ["ren", "daichi", "nao", "sayo", "tsukiyo"]:
		portraits[id] = load("res://art/characters/%s/v01/reference.png" % id) if id != "tsukiyo" else load("res://art/characters/tsukiyo/ui-master.png")
	captions = JSON.parse_string(FileAccess.get_file_as_string("res://art/intro/captions-es.json"))
	voice = AudioStreamPlayer.new()
	voice.bus = "IntroVO"
	voice.stream = VOICE
	voice.volume_db = -1
	add_child(voice)
	music = AudioStreamPlayer.new()
	music.bus = "Music"
	# Approved Ink Resolve A stem already includes speech ducking and the final fade.
	# Keep unity gain here; player preferences are applied separately by the Music bus.
	music.volume_db = 0
	music.stream = MUSIC
	music.stream.loop = false
	add_child(music)
	subtitle = Label.new()
	subtitle.position = Vector2(180, 757)
	subtitle.size = Vector2(1240, 83)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 27)
	subtitle.add_theme_color_override("font_color", PAPER)
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(subtitle)
	pause_button = control_button("Pausa · Espacio", Rect2(64, 852, 260, 38), toggle_pause)
	subtitles_button = control_button("Subtítulos: sí · S", Rect2(350, 852, 280, 38), toggle_subtitles)
	skip = control_button("Saltar prólogo · Esc / B", Rect2(1190, 852, 346, 38), finish)

func control_button(caption: String, rect: Rect2, action: Callable) -> Button:
	var button := Button.new()
	button.text = caption
	button.position = rect.position
	button.size = rect.size
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color("a4a398"))
	button.add_theme_color_override("font_hover_color", PAPER)
	button.add_theme_color_override("font_focus_color", PAPER)
	for state in ["normal", "hover", "pressed"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = RED
	focus.border_width_bottom = 2
	button.add_theme_stylebox_override("focus", focus)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(action)
	add_child(button)
	return button

func duration() -> float:
	return LEAD + VOICE.get_length() + TAIL

func start() -> void:
	voice.stop()
	music.stop()
	time = 0
	active = true
	paused = false
	manual = false
	started_voice = false
	has_focus = true
	voice.stream_paused = false
	music.stream_paused = false
	if music.stream != null and DisplayServer.get_name() != "headless":
		music.play()
	pause_button.text = "Pausa · Espacio"
	update_frame()

func stop() -> void:
	active = false
	voice.stop()
	music.stop()

func finish() -> void:
	if not active:
		return
	stop()
	finished.emit()

func set_paused(value: bool) -> void:
	paused = value
	voice.stream_paused = value
	music.stream_paused = value
	pause_button.text = "Continuar · Espacio" if value else "Pausa · Espacio"
	queue_redraw()

func toggle_pause() -> void:
	set_paused(not paused)

func toggle_subtitles() -> void:
	subtitles_enabled = not subtitles_enabled
	subtitles_button.text = "Subtítulos: %s · S" % ("sí" if subtitles_enabled else "no")
	update_frame()

func handle_input(event: InputEvent) -> void:
	if not active or (event is InputEventKey and event.echo):
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			finish()
		elif event.keycode == KEY_SPACE:
			toggle_pause()
		elif event.keycode == KEY_S:
			toggle_subtitles()
		elif event.keycode in [KEY_ENTER, KEY_KP_ENTER]:
			var focused := get_viewport().gui_get_focus_owner()
			if focused is Button and is_ancestor_of(focused):
				focused.pressed.emit()
		else:
			return
		get_viewport().set_input_as_handled()
	elif event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_B:
			finish()
		elif event.button_index in [JOY_BUTTON_A, JOY_BUTTON_START]:
			toggle_pause()
		elif event.button_index == JOY_BUTTON_Y:
			toggle_subtitles()
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and active and not manual:
		has_focus = false
		set_paused(true)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		has_focus = true

func _process(delta: float) -> void:
	if not active or paused or manual:
		return
	if not is_visible_in_tree():
		stop()
		return
	if voice.playing and started_voice:
		# Mixer time is authoritative; dropped rendering frames cannot desync captions.
		time = maxf(time, LEAD + voice.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency())
	else:
		time += delta
	if time >= LEAD and not started_voice:
		started_voice = true
		if DisplayServer.get_name() != "headless":
			voice.play(maxf(0, time - LEAD))
	if time >= duration():
		finish()
		return
	update_frame()

func seek_preview(seconds: float) -> void:
	manual = true
	voice.stop()
	music.stop()
	time = seconds
	update_frame()

func caption_at(seconds: float) -> String:
	for cue in captions:
		if seconds >= cue.start and seconds < cue.end:
			return cue.text
	return ""

func update_frame() -> void:
	for button in [pause_button, subtitles_button, skip]:
		button.visible = not clean_preview
	subtitle.text = caption_at(time - LEAD)
	subtitle.visible = subtitles_enabled and not subtitle.text.is_empty()
	queue_redraw()

func chapter_at(seconds: float) -> int:
	var index: int = 0
	for i in range(CHAPTERS.size()):
		if seconds >= CHAPTERS[i]:
			index = i
	return index

func write(caption: String, position: Vector2, font_size: int, color: Color = PAPER, literary: bool = true) -> void:
	draw_string(serif if literary else small_font, position, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func centered(caption: String, y: float, font_size: int, color: Color = PAPER) -> void:
	var width: float = serif.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	write(caption, Vector2((1600 - width) / 2, y), font_size, color)

func portrait(id: String, rect: Rect2, alpha: float = 1, mirror: bool = false) -> void:
	var texture: Texture2D = portraits[id]
	var scale_factor: float = minf(rect.size.x / texture.get_width(), rect.size.y / texture.get_height())
	var extent: Vector2 = texture.get_size() * scale_factor
	var target := Rect2(rect.position + (rect.size - extent) * 0.5, extent)
	if mirror:
		target.position.x += target.size.x
		target.size.x *= -1
	draw_texture_rect(texture, target, false, Color(PAPER, alpha))

func draw_chapter(index: int, seconds: float, alpha: float) -> void:
	var age: float = maxf(0, seconds - CHAPTERS[index])
	var drift: float = minf(age, 9) * 2
	# The narrator supplies the meaning. No headings, captions on cards or roster labels.
	# Ren's exile; then the landscape alone for the lord's promise (Daichi is not the lord).
	if index == 1:
		portrait("ren", Rect2(820 - drift, 120, 660, 690), alpha * 0.85)
	elif index == 3:
		portrait("ren", Rect2(760 - drift, 60, 780, 770), alpha)
	elif index == 4:
		portrait("nao", Rect2(760 - drift, 70, 780, 760), alpha)
	elif index == 5:
		# Both resist another war: Daichi protects his valley, Sayo opposes the campaign.
		portrait("daichi", Rect2(720 - drift, 90, 690, 720), alpha * 0.9)
		portrait("sayo", Rect2(245 + drift, 145, 560, 660), alpha * 0.84)
	elif index == 6:
		portrait("tsukiyo", Rect2(745 - drift, 55, 800 + drift, 770 + drift), alpha)
	elif index == 7:
		# The five paths meet before the title; one composition, without cards or labels.
		var ids := ["ren", "daichi", "tsukiyo", "nao", "sayo"]
		for i in range(ids.size()):
			var central: bool = i == 2
			var height: float = 650 if central else 555
			var top: float = 115 if central else 205
			var reveal: float = smoothstep(i * 0.09, i * 0.09 + 0.65, age)
			portrait(ids[i], Rect2(i * 310 + 15, top - drift * 0.35, 330, height), alpha * reveal)
	elif index == 8:
		for ring in range(6):
			draw_arc(Vector2(800, 399), 236 + ring * 1.5, -1.8, -1.8 + minf(5.9, age * 3), 160, Color(PAPER, alpha * 0.065), 1.8, true)
		centered("M A A I", 435, 124, Color(PAPER, alpha))
		centered("La distancia entre la vida y la muerte.", 515, 27, Color(PAPER, alpha))

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), INK)
	if serif == null:
		return
	var seconds: float = maxf(0, time - LEAD)
	var index: int = chapter_at(seconds)
	var age: float = seconds - CHAPTERS[index]
	var opening: float = smoothstep(0, 1.2, time)
	var blend: float = smoothstep(0, 1.15, age)
	var figures: float = 1.0 if index in [1, 3, 4, 5, 6, 7] else 0.0
	var previous_figures: float = 1.0 if index - 1 in [1, 3, 4, 5, 6, 7] else 0.0
	var presence: float = lerpf(previous_figures, figures, blend)
	# One uninterrupted camera move; the promise briefly draws us toward the distant castle.
	var castle: float = smoothstep(11.8, 15.4, seconds) * (1 - smoothstep(16.5, 19.7, seconds))
	var zoom: float = 1.06 + seconds * 0.0015 + castle * 0.23
	var extent := Vector2(1600, 900) * zoom
	var camera := Vector2(-castle * 95 + sin(seconds * 0.05) * 12, castle * 60)
	var closing: float = smoothstep(38, 43.2, seconds)
	var light: float = lerpf(0.88, 0.42, presence) * lerpf(1.0, 0.21, closing)
	draw_texture_rect(LANDSCAPE, Rect2((size - extent) * 0.5 + camera, extent), false, Color(1, 1, 1, opening * light))
	if index > 0 and blend < 1:
		draw_chapter(index - 1, seconds, (1 - blend) * opening)
	if index != 8:
		draw_chapter(index, seconds, (blend if index > 0 else 1.0) * opening)
	# Lower contours dissolve in an ink wash instead of sitting on a hard rectangular panel.
	draw_texture_rect(mist, Rect2(Vector2.ZERO, size), false)
	draw_texture_rect(vignette, Rect2(Vector2.ZERO, size), false)
	for i in range(25):
		var point := Vector2(fmod(i * 193.0 + seconds * (1 + i % 3), 1600), fmod(i * 79.3 - seconds * 3 + 900, 900))
		draw_circle(point, 0.6 + i % 2 * 0.4, Color(PAPER, 0.06 * opening))
	if index == 8:
		draw_chapter(index, seconds, blend * opening)
	if paused:
		centered("PRÓLOGO EN PAUSA", 103, 18, PAPER)
