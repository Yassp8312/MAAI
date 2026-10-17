extends SceneTree
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func tap(code: int) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	root.push_input(event)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event)

func run() -> void:
	Input.use_accumulated_input = false
	var game = load("res://scenes/main.tscn").instantiate()
	game.settings.storage_path = "user://prologue-test-unused.cfg"
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.capture_frames = 1
	var menu = game.menu
	var intro = menu.prologue
	intro.set_process(false)
	check(menu.screen == "intro" and intro.active and not game.playing, "Normal startup opens the prologue before presentation")
	check(intro.duration() > 46 and intro.duration() < 49, "Duration includes the complete narration and title hold")
	check(AudioServer.get_bus_index("IntroVO") >= 0 and intro.voice.bus == "IntroVO", "Narration has its own volume bus")
	check(intro.music.stream != null and intro.music.bus == "Music" and not intro.music.stream.loop, "Selected soundtrack is routed independently and does not loop")
	check(absf(intro.music.stream.get_length() - intro.duration()) < 0.1, "Edited soundtrack matches the prologue duration")
	var initial_time: float = intro.time
	intro.time = 45
	intro.update_frame()
	check(is_zero_approx(intro.music.volume_db), "Approved stem does not receive a second attenuation or end fade")
	intro.time = initial_time
	intro.update_frame()
	check(intro.portraits.size() == 5, "All five character masters are available")
	check(intro.caption_at(1).begins_with("Hubo un tiempo"), "Opening caption matches narration")
	check(intro.caption_at(42).contains("primer paso"), "Final sentence has a caption")
	check(intro.caption_at(44).is_empty(), "Title hold has no stale subtitle")
	tap(KEY_SPACE)
	check(intro.paused, "Space pauses intro")
	var frozen: float = intro.time
	intro._process(2)
	check(intro.time == frozen, "Pause freezes visual timeline")
	tap(KEY_SPACE)
	intro._process(1)
	check(not intro.paused and intro.time > frozen, "Space resumes timeline")
	tap(KEY_S)
	check(not intro.subtitles_enabled and not intro.subtitle.visible, "Subtitles can be hidden")
	tap(KEY_S)
	check(intro.subtitles_enabled and intro.subtitle.visible, "Subtitles can be restored")
	intro._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(intro.paused and not intro.has_focus, "Losing focus pauses the prologue")
	intro._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	check(intro.paused, "Returning focus does not unexpectedly resume narration")
	tap(KEY_ESCAPE)
	check(menu.screen == "title" and not intro.active and not intro.voice.playing and not intro.music.playing, "Skip reaches presentation and stops both audio tracks")
	menu.play_prologue()
	check(intro.active and intro.time == 0 and not intro.paused, "Replay resets timeline and pause state")
	intro._process(intro.duration() + 1)
	check(menu.screen == "title" and not intro.active, "Natural ending reaches presentation")
	menu.play_prologue()
	var event := InputEventJoypadButton.new()
	event.pressed = true
	event.button_index = JOY_BUTTON_A
	root.push_input(event)
	check(intro.paused, "Controller A pauses intro")
	event = event.duplicate()
	event.button_index = JOY_BUTTON_B
	root.push_input(event)
	check(menu.screen == "title", "Controller B skips intro")
	menu.play_prologue()
	game.start_game()
	check(not intro.active and not intro.voice.playing and not intro.music.playing and game.playing, "Starting combat stops any prologue playback")
	game.queue_free()
	await process_frame
	print("Prologue: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
