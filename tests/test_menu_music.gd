extends SceneTree
var failures: int = 0
var checks: int = 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.play_intro_on_start = false
	game.settings.storage_path = "user://menu-music-test-unused.cfg"
	root.add_child(game)
	game.set_physics_process(false)
	game.menu_music.set_process(false)
	var music = game.menu_music
	check(music.TRACK.get_length() > 230 and not music.TRACK.loop, "Full score imported without competing automatic loop")
	check(music.enabled and music.starts == 1, "Title starts menu music once")
	game.menu.show_home()
	game.open_options()
	game.refresh()
	check(music.enabled and music.starts == 1, "Menu and options preserve playback")
	game.options.cancel()
	game.menu.open_selection()
	game.refresh()
	check(music.enabled and music.starts == 1, "Selection preserves playback")
	music._process(1.4)
	check(is_equal_approx(music.gain, 1.0), "Entry fades to configured level")
	game.start_game()
	check(not music.enabled and music.gain > 0, "Starting combat requests fade-out")
	music._process(0.9)
	check(music.gain == 0 and not music.voice_active.has(true), "Score ends before combat countdown finishes")
	game.open_pause()
	game.open_options()
	game.refresh()
	check(not music.enabled, "Combat options do not start menu score")
	game.options.cancel()
	game.return_to_menu()
	check(music.enabled and music.starts == 2, "Returning home starts score again")
	music._process(1.4)
	var old: int = music.active
	music.begin_loop()
	music._process(1.5)
	check(music.crossing and music.voice_active[old] and music.voice_active[1-old], "Loop overlaps two voices")
	check(is_equal_approx(music.voices[old].volume_db, music.voices[1-old].volume_db), "Loop midpoint uses balanced linear weights")
	music._process(1.5)
	check(not music.crossing and music.active != old and not music.voice_active[old], "Loop hands playback to new voice")
	game.menu.play_prologue()
	check(not music.enabled and music.gain == 0 and not music.voice_active.has(true), "Prologue silences menu score before narration")
	game.menu.show_screen("title")
	game.refresh()
	check(music.enabled, "Menu music returns after prologue")
	check(music.voices.all(func(v): return v.bus == "Music"), "Both voices respect Music settings")
	game.queue_free()
	await process_frame
	print("Menu music: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
