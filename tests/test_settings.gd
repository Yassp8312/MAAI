extends SceneTree
const Settings = preload("res://scripts/game_settings.gd")
const LocalInput = preload("res://scripts/local_input.gd")
var checks: int = 0
var failures: int = 0
var path: String = "user://settings-test-%d.cfg" % OS.get_process_id()
var visual: bool = "--visual" in OS.get_cmdline_user_args()

func _initialize() -> void:
	run.call_deferred()

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)

func key_event(code: int, pressed: bool = true) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	return event

func screenshot(filename: String) -> void:
	if not visual:
		return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tmp/" + filename + ".png")

func run() -> void:
	Input.use_accumulated_input = false
	var settings := Settings.new()
	settings.storage_path = path
	settings.load_settings()
	check(settings.values == Settings.defaults(), "Missing file uses playable defaults")
	settings.values.keys[0][0] = KEY_Z
	settings.values.pads[1][0] = JOY_BUTTON_LEFT_STICK
	settings.values.audio.Music = 21
	settings.values.audio.mute = true
	check(settings.save_settings() == OK, "Preferences saved")
	var loaded := Settings.new()
	loaded.load_settings(path)
	check(loaded.values == settings.values, "Display, sound and both players' mappings survive reload")
	loaded.apply_all()
	check(AudioServer.is_bus_mute(0), "Master mute reaches the audio server")
	check(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))), 0.21), "Music bus receives persisted volume")
	var adapter := LocalInput.new(loaded)
	adapter.sample(0)
	Input.parse_input_event(key_event(KEY_A))
	check(adapter.sample(0).axis == 0, "Old keyboard binding no longer moves player")
	Input.parse_input_event(key_event(KEY_A, false))
	Input.parse_input_event(key_event(KEY_Z))
	check(adapter.sample(0).axis == -1, "New physical key moves player")
	adapter.block_until_release()
	check(adapter.sample(0).axis == 0, "Held menu key cannot leak into resumed duel")
	Input.parse_input_event(key_event(KEY_Z, false))
	adapter.sample(0)
	Input.parse_input_event(key_event(KEY_Z))
	check(adapter.sample(0).axis == -1, "Release then press restores gameplay input")
	Input.parse_input_event(key_event(KEY_Z, false))
	var corrupt := ConfigFile.new()
	corrupt.set_value("display", "resolution", Vector2i(-1, 0))
	corrupt.set_value("audio", "Music", "invalid")
	corrupt.set_value("audio", "SFX", 999)
	corrupt.set_value("controls", "keys", [[KEY_Z], null])
	corrupt.set_value("controls", "pads", [[0, 0, 0, 0, 0, 0], [0, 1, 2, 3, 4, 5]])
	corrupt.save(path)
	loaded.load_settings(path)
	check(loaded.values.display.resolution == Vector2i(1280, 720) and loaded.values.audio.Music == 70, "Invalid display and audio recover safe defaults")
	check(loaded.values.audio.SFX == 100, "Out-of-range volume clamped")
	check(loaded.values.keys == Settings.DEFAULT_KEYS and loaded.values.pads[0] == Settings.DEFAULT_PAD, "Malformed and duplicate bindings recover usable controls")
	loaded.values = Settings.defaults()
	loaded.save_settings(path)
	var game = load("res://scenes/main.tscn").instantiate()
	game.play_intro_on_start = false
	game.settings.storage_path = path
	root.add_child(game)
	await process_frame
	check(game.menu.visible and not game.options.visible, "Main menu opens normally")
	await screenshot("settings-main")
	game.open_options()
	var menu = game.options
	check(menu.visible and not game.menu.visible, "Options replace main menu")
	check(menu.navigation.size() == 3 and menu.navigation[0].selected and not menu.tabs.tabs_visible, "Paper navigation replaces native tabs")
	await screenshot("settings-display")
	menu.tabs.current_tab = 2
	check(menu.navigation[2].selected and not menu.navigation[0].selected, "Current section follows keyboard or programmatic navigation")
	menu.begin_capture(0, true)
	root.push_input(key_event(KEY_LEFT))
	check(not menu.capture.is_empty() and menu.draft.keys[0][0] == KEY_A, "Cannot steal the other player's key")
	root.push_input(key_event(KEY_LEFT, false))
	root.push_input(key_event(KEY_R))
	check(not menu.capture.is_empty(), "Reserved restart key cannot be bound")
	root.push_input(key_event(KEY_R, false))
	root.push_input(key_event(KEY_Z))
	root.push_input(key_event(KEY_Z, false))
	check(menu.capture.is_empty() and menu.draft.keys[0][0] == KEY_Z, "Key capture through real input pipeline succeeds")
	menu.begin_capture(1, true)
	root.push_input(key_event(KEY_ESCAPE))
	root.push_input(key_event(KEY_ESCAPE, false))
	check(menu.visible and menu.capture.is_empty(), "Escape cancels capture without closing options")
	await screenshot("settings-controls")
	menu.save_requested()
	check(not menu.visible and game.menu.visible, "Saving returns to original menu")
	loaded.load_settings(path)
	check(loaded.values.keys[0][0] == KEY_Z and "Z / D" in game.settings.control_hint(0), "Saved mapping updates HUD and disk")
	game.open_options()
	menu.tabs.current_tab = 1
	menu.sliders.Music.slider.value = 12
	menu.mute.button_pressed = true
	check(AudioServer.is_bus_mute(0), "Sound preview applies immediately")
	await screenshot("settings-audio")
	menu.cancel()
	check(not AudioServer.is_bus_mute(0) and game.settings.values.audio.Music == 70, "Cancel restores previous audio levels and mute")
	game.open_options()
	menu.draft.display.vsync = not menu.draft.display.vsync
	menu.save_requested()
	check(menu.confirmation.visible and not menu.content_panel.visible, "Display change requires isolated confirmation")
	check(not menu.save_button.is_visible_in_tree() and not menu.navigation[0].is_visible_in_tree(), "Confirmation isolates footer and sidebar as well as fields")
	await screenshot("settings-confirmation")
	menu._process(13)
	check(not menu.confirmation.visible and menu.draft.display == game.settings.values.display, "Timeout reverts unconfirmed display settings")
	menu.draft.display.vsync = not menu.draft.display.vsync
	menu.save_requested()
	menu.finish_save()
	loaded.load_settings(path)
	check(not loaded.values.display.vsync, "Confirmed display settings are persisted")
	if visual:
		game.open_options()
		var old_size := DisplayServer.window_get_size()
		menu.draft.display.resolution = Vector2i(960, 540)
		menu.save_requested()
		for i in range(4):
			await process_frame
		check(DisplayServer.window_get_size() == Vector2i(960, 540), "Window resolution changes on the real display")
		menu.finish_save()
		game.open_options()
		menu.tabs.current_tab = 2
		await screenshot("settings-controls-small")
		menu.draft.display.fullscreen = true
		menu.save_requested()
		for i in range(4):
			await process_frame
		check(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN, "Fullscreen preview changes the real window mode")
		menu._process(13)
		for i in range(4):
			await process_frame
		check(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED and DisplayServer.window_get_size() == Vector2i(960, 540), "Timeout recovers actual window mode and size")
		menu.draft.display.resolution = old_size
		menu.save_requested()
		menu.finish_save()
	game.start_game()
	for i in range(110):
		await physics_frame
	game.sim.scores = [1, 0]
	game.open_pause()
	check(game.pause_menu.duel.text.contains("Tsukiyo") and game.pause_menu.score.text.contains("1"), "Pause presents current fighters and score")
	var tick: int = game.sim.tick
	await screenshot("settings-pause")
	game.open_options()
	for i in range(5):
		await physics_frame
	check(game.sim.tick == tick and game.sim.scores == [1, 0], "Options freeze simulation and preserve score")
	menu.tabs.current_tab = 2
	menu.restore_section()
	menu.save_requested()
	check(game.pause_menu.visible and game.paused and game.playing, "Saving during duel returns to pause without resetting match")
	check(game.settings.values.keys == Settings.DEFAULT_KEYS, "Restoring controls returns both players to defaults")
	game.resume_game()
	for i in range(3):
		await physics_frame
	check(game.sim.tick > tick and game.sim.scores == [1, 0], "Resuming continues the same duel")
	game.open_options()
	game.settings.storage_path = "user://missing-settings-directory/options.cfg"
	menu.sliders.Music.slider.value = 33
	menu.save_requested()
	check(menu.visible and game.settings.values.audio.Music == 70, "Failed disk write keeps options open and restores active preferences")
	menu.cancel()
	game.settings.storage_path = path
	game.return_to_menu()
	check(game.menu.visible and not game.playing, "Return to main menu ends duel")
	game.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("MAAI settings: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
