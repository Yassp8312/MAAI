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

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.play_intro_on_start = false
	game.settings.storage_path = "user://battle-music-test-unused.cfg"
	root.add_child(game)
	game.set_physics_process(false)
	game.menu_music.set_process(false)
	var music = game.battle_music
	music.set_process(false)
	check(not music.enabled and music.selected == -1, "Menu does not consume combat rotation")
	for track in music.TRACKS:
		check(track.get_length() > 160 and not track.loop, "Complete combat score imports without native repeat")
	game.start_game()
	check(music.enabled and music.selected == 0 and music.starts == 1, "First duel starts Banda sonora2")
	music._process(1.2)
	check(is_equal_approx(music.gain, 1), "Combat fade reaches target")
	for i in range(3):
		game.sim.reset_round()
		game.refresh()
	check(music.selected == 0 and music.starts == 1, "Rounds keep the same music without restarting")
	game.open_pause()
	game.refresh()
	music._process(0.3)
	check(music.enabled and music.mix_db == -12 and music.starts == 1, "Pause lowers music without losing playback")
	game.open_options()
	game.refresh()
	check(music.enabled and music.quiet and not game.menu_music.enabled, "Combat options keep only reduced combat music")
	game.options.cancel()
	game.resume_game()
	game.refresh()
	music._process(1.3)
	check(music.mix_db == 0 and music.starts == 1, "Resume restores level without restart")
	music.on_combat_cue({"kind": "weapon"})
	music._process(0.05)
	check(music.mix_db < 0, "Weapon sound briefly makes room in music")
	music._process(0.6)
	check(music.mix_db == 0, "Transient reduction recovers")
	var old: int = music.active
	music.begin_loop()
	music._process(1.5)
	check(music.crossing and music.voice_active[0] and music.voice_active[1], "Long fight crossfades its own score")
	music._process(1.5)
	check(not music.crossing and music.active != old and music.selected == 0, "Loop retains chosen score")
	game.sim.scores = [2, 0]
	game.menu.show_result()
	game.refresh()
	check(not music.enabled and game.menu_music.enabled, "Result returns to menu score")
	music._process(0.9)
	check(not music.voice_active.has(true), "Combat score fades out fully")
	game.menu.rematch()
	check(music.selected == 1 and music.enabled, "Rematch switches to Banda sonora 3")
	game.return_to_menu()
	music._process(0.9)
	game.menu.open_selection("practice")
	game.menu.launch()
	check(game.practice and not music.enabled and music.selected == 1, "Practice remains unscored and does not consume next track")
	game.start_demo()
	check(game.demo and not music.enabled and music.selected == 1, "Gallery remains unscored")
	game.return_to_menu()
	game.start_game()
	check(music.selected == 0, "Next duel cycles back to Banda sonora2")
	game.menu.play_prologue()
	check(not music.enabled and not music.voice_active.has(true), "Prologue cannot overlap combat score")
	check(music.voices.all(func(v): return v.bus == "Music"), "Combat follows Music and Master controls")
	game.queue_free()
	await process_frame
	print("Battle music: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
