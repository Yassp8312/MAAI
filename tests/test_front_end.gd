extends SceneTree
var game
var menu
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func key(code: int, down: bool = true, repeat: bool = false) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = down
	event.echo = repeat
	return event

func tap(code: int) -> void:
	root.push_input(key(code))
	root.push_input(key(code, false))

func pad(device: int, button: int) -> void:
	var event := InputEventJoypadButton.new()
	event.device = device
	event.button_index = button
	event.pressed = true
	root.push_input(event)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event)

func stick(device: int, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = device
	event.axis = JOY_AXIS_LEFT_X
	event.axis_value = value
	root.push_input(event)

func run() -> void:
	Input.use_accumulated_input = false
	game = load("res://scenes/main.tscn").instantiate()
	game.play_intro_on_start = false
	game.settings.storage_path = "user://frontend-test-unused.cfg"
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.capture_frames = 1
	menu = game.menu
	menu.set_process(false)
	check(menu.screen == "title" and menu.visible and not game.playing, "Starts at presentation without simulating a duel")
	menu.title_clock = 0
	for i in range(menu.roster.size()):
		check(menu.title_slides[0].caption.text == menu.roster[i].name, "Carousel presents each available character in order")
		menu._process(menu.TITLE_HOLD + menu.TITLE_FADE)
	check(menu.title_index == 0, "Carousel loops back to Tsukiyo")
	menu._process(menu.TITLE_HOLD + menu.TITLE_FADE * 0.5)
	check(is_equal_approx(menu.title_slides[0].node.modulate.a, 0.5) and is_equal_approx(menu.title_slides[1].node.modulate.a, 0.5), "Portrait and caption layers crossfade together")
	menu.title_age = 1
	tap(KEY_ENTER)
	check(menu.screen == "home" and menu.home_buttons[0].has_focus(), "Title accepts keyboard and focuses first home action")
	var frozen_clock: float = menu.title_clock
	menu._process(10)
	check(menu.title_clock == frozen_clock, "Carousel stops outside presentation, including a partially completed fade")
	menu.show_screen("title")
	menu.suspended = true
	menu._process(10)
	check(menu.title_clock == frozen_clock, "Suspending presentation freezes carousel")
	menu.suspended = false
	menu._process(menu.TITLE_FADE * 0.5)
	check(menu.title_index == 1 and menu.title_slides[0].caption.text == "Ren", "Returning to presentation completes the pending transition")
	menu.show_home()
	# Headless has no OS pointer; exercise the enter signal, then native keyboard focus.
	menu.home_buttons[3].mouse_entered.emit()
	check(menu.home_buttons[3].has_focus() and "Ajusta" in menu.home_description.text, "Mouse-enter signal moves native focus and updates the option description")
	check(not game.options.visible, "Hovering an option never activates it")
	menu.home_buttons[0].grab_focus()
	tap(KEY_DOWN)
	check(menu.home_buttons[1].has_focus(), "Home navigates by keyboard")
	tap(KEY_UP)
	tap(KEY_ENTER)
	check(menu.screen == "select" and not game.playing, "Duelo opens character selection")
	tap(KEY_D)
	check(game.selected_characters == ["ren", "tsukiyo"], "Player 1 changes only their portrait and character")
	tap(KEY_RIGHT)
	tap(KEY_RIGHT)
	check(game.selected_characters == ["ren", "daichi"], "Player 2 has independent keyboard selection")
	root.push_input(key(KEY_D, true, true))
	check(game.selected_characters[0] == "ren", "Held-key repeats do not skip choices")
	tap(KEY_F)
	tap(KEY_D)
	check(menu.ready_players == [true, false] and game.selected_characters[0] == "ren", "Confirmation locks that player's choice")
	tap(KEY_Q)
	check(not menu.ready_players[0] and menu.screen == "select", "Cancel unlocks without leaving selection")
	tap(KEY_TAB)
	check(game.best_of == 5 and menu.ready_players == [false, false], "Format accessible without mouse and resets readiness")
	tap(KEY_F)
	tap(KEY_U)
	check(menu.screen == "versus" and not game.playing, "Both confirmations present the matchup before combat")
	tap(KEY_K)
	check(menu.screen == "select" and not menu.ready_players[1], "Either player can cancel the matchup transition")
	tap(KEY_U)
	menu._process(2)
	check(game.playing and not menu.visible and game.sim.target_wins == 3, "Transition starts the selected match format")
	check(game.sim.character_ids == ["ren", "daichi"], "Chosen characters and combat profiles enter the duel together")
	check(game.controls.blocked == [true, true], "Confirmation inputs are blocked until released in combat")
	game.open_pause()
	game.return_to_selection()
	check(menu.screen == "select" and not game.playing and not game.pause_menu.visible, "Pause can return to selection")
	check(game.selected_characters == ["ren", "daichi"] and menu.ready_players == [false, false], "Returning preserves choices but requires new confirmation")
	# Mouse buttons use the same independent choice path as keyboard.
	await process_frame
	var mouse_position: Vector2 = menu.roster_buttons[0][4].get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = mouse_position
	root.push_input(motion, true)
	for down in [true, false]:
		var click := InputEventMouseButton.new()
		click.position = mouse_position
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = down
		root.push_input(click, true)
	check(game.selected_characters[0] == "sayo", "Mouse click reaches the portrait through its decorative children")
	menu.roster_buttons[1][4].pressed.emit()
	check(game.selected_characters == ["sayo", "sayo"], "Portrait buttons support mirror matches")
	# Remapped physical keys drive selection and its on-screen hints.
	game.settings.values.keys[0][1] = KEY_Z
	game.settings.apply_bindings()
	menu.open_selection()
	tap(KEY_D)
	check(game.selected_characters[0] == "sayo", "Old movement key no longer selects")
	tap(KEY_Z)
	check(game.selected_characters[0] == "tsukiyo" and "Z" in menu.hints[0].text, "Remapped movement and hints agree")
	# Synthetic controller events test routing, not physical hardware connectivity.
	menu.device_slots = [42, 73]
	pad(42, JOY_BUTTON_DPAD_RIGHT)
	check(game.selected_characters[0] == "ren", "Controller slot 1 moves player 1")
	pad(73, JOY_BUTTON_DPAD_LEFT)
	check(game.selected_characters[1] == "nao", "Controller slot 2 moves player 2")
	pad(99, JOY_BUTTON_DPAD_RIGHT)
	check(game.selected_characters == ["ren", "nao"], "Unassigned controller cannot steal a selection")
	stick(42, 0.8)
	stick(42, 0.9)
	check(game.selected_characters[0] == "daichi", "Held stick only advances once")
	stick(42, 0)
	stick(42, 0.8)
	check(game.selected_characters[0] == "nao", "Releasing stick permits a second deliberate choice")
	pad(42, JOY_BUTTON_A)
	pad(73, JOY_BUTTON_A)
	check(menu.screen == "versus", "Two controller confirmations start matchup")
	menu.connection_changed(73, false)
	check(menu.screen == "select" and menu.transition_remaining == 0 and not menu.ready_players[1], "Controller loss cancels pending launch")
	# Back navigation, practice and gallery each keep the chosen pair.
	menu.open_selection("practice")
	menu.confirm_player(0)
	menu.confirm_player(1)
	menu._process(2)
	check(game.playing and game.practice and not game.demo, "Practice has its own launch behavior")
	menu.open_selection("gallery")
	menu.confirm_player(0)
	menu.confirm_player(1)
	menu._process(2)
	check(game.playing and game.demo and game.practice, "Gallery starts the existing animation demonstration")
	menu.show_home()
	menu.home_buttons[3].pressed.emit()
	check(game.options.visible and not menu.visible, "Options opens over frontend")
	game.options.cancel()
	check(menu.visible and menu.screen == "home" and menu.home_buttons[3].has_focus(), "Options returns to menu with correct focus")
	check(menu.sound.bus == "SFX", "Interface sound respects SFX and Master controls")
	for player in range(2):
		game.start_game()
		game.sim.scores = [2, 0] if player == 0 else [0, 2]
		game.sim.phase = "match_over"
		game._physics_process(1.0 / 60)
		check(menu.visible and menu.screen == "result", "Match completion opens functional result screen")
		check(CatalogName(game.selected_characters[player]) in menu.result_title.text, "Result identifies actual winning character")
		var chosen: Array = game.selected_characters.duplicate()
		menu.result_buttons[0].pressed.emit()
		check(game.sim.scores == [0, 0] and game.selected_characters == chosen and not menu.visible, "Rematch resets score without changing characters")
	game.sim.scores = [2, 1]
	menu.show_result()
	menu.result_buttons[1].pressed.emit()
	check(menu.screen == "select" and not game.playing, "Result offers another character selection")
	tap(KEY_ESCAPE)
	check(menu.screen == "home", "Escape from selection returns home")
	menu.open_selection()
	menu.confirm_player(0)
	menu.confirm_player(1)
	game.capture_frames = 0
	menu._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(menu.screen == "select" and menu.transition_remaining == 0, "Focus loss prevents the matchup from launching an unattended duel")
	# Every intended control stays inside the 1600x900 logical viewport.
	for group in menu.roster_buttons + [menu.ready_buttons, menu.home_buttons, menu.result_buttons]:
		for b in group:
			check(Rect2(Vector2.ZERO, Vector2(1600, 900)).encloses(b.get_rect()), "Control fits smallest supported aspect ratio")
	game.queue_free()
	for i in range(3):
		await process_frame
	print("Front end: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func CatalogName(id: String) -> String:
	return preload("res://scripts/character_catalog.gd").display_name(id)
