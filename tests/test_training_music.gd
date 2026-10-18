extends SceneTree
var checks: int = 0
var failures: int = 0
func _initialize() -> void:
	run.call_deferred()
func check(ok: bool, why: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(why)
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.play_intro_on_start = false
	game.settings.storage_path = "user://training-music-test-unused.cfg"
	root.add_child(game)
	game.set_physics_process(false)
	var music = game.training_music
	music.set_process(false)
	check(music.voices.size() == 2 and music.track.get_length() > 89 and music.track.get_length() < 91, "Dojo score is imported with two crossfade voices")
	check(not music.enabled and music.starts == 0, "Menu does not start training music")
	game.start_game("practice")
	check(music.enabled and music.starts == 1 and not game.battle_music.enabled and not game.menu_music.enabled, "Training enables its own score")
	music._process(1.5)
	check(music.gain == 1 and music.level_db == -4, "Training fade reaches authored level")
	for i in range(3):
		game.training.reset(game.sim)
		game.refresh()
	check(music.starts == 1, "Resetting exercises does not restart music")
	game.training_menu.open()
	music._process(0.3)
	check(music.enabled and music.quiet and music.mix_db == -12 and music.starts == 1, "Training adjustments lower music without restarting")
	game.training_menu.exercise("punish")
	music._process(1.3)
	check(music.mix_db == 0 and music.starts == 1, "Exercise restores continuous score")
	for kind in ["weapon", "impact", "parry"]:
		game.combat_audio.cue_emitted.emit({"kind": kind})
		music._process(0.05)
		check(music.mix_db == -2, "Real cue makes space for " + kind)
		music._process(0.6)
		check(music.mix_db == 0, "Music recovers after " + kind)
	var old: int = music.active
	music.begin_loop()
	music._process(1.5)
	check(music.crossing and music.voice_active.all(func(value): return value), "Loop overlaps both voices")
	music._process(1.5)
	check(not music.crossing and music.active != old and music.starts == 1, "Crossfade completes without restarting session")
	game.open_options()
	check(music.quiet and music.enabled, "Practice options retain its quiet music")
	game.options.cancel()
	game.resume_game()
	game.return_to_menu()
	music._process(0.9)
	check(not music.enabled and not music.voice_active.has(true), "Returning to menus fades training out")
	game.start_game()
	check(not music.enabled and game.battle_music.enabled and game.battle_music.selected == 0, "Training never consumes combat track rotation")
	game.start_demo()
	check(not music.enabled, "Gallery remains without training score")
	game.start_game("practice")
	game.menu.play_prologue()
	check(not music.enabled and not music.voice_active.has(true), "Prologue silences training immediately")
	check(music.voices.all(func(voice): return voice.bus == "Music"), "Music and Master settings govern both voices")
	game.queue_free()
	await process_frame
	print("Training music: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
