extends SceneTree
var game
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.play_intro_on_start = false
	game.settings.storage_path = "user://training-music-preview-unused.cfg"
	root.add_child(game)
	game.set_physics_process(false)
	game.capture_frames = 1
	DisplayServer.window_set_size(Vector2i(960, 540))
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
	DisplayServer.window_set_position(Vector2i(-2200, -1200))
	game.select_character(0, "nao")
	game.select_character(1, "daichi")
	game.select_arena(2)
	game.start_game("practice")
	game.menu_music.silence()
	game.training_menu.exercise("punish")
	for frame in range(600):
		if frame == 300: game.training_menu.open()
		if frame == 360:
			game.training_menu.hide()
			game.resume_game()
		if not game.paused:
			for sub in range(2):
				var input: Dictionary = {}
				var f: Dictionary = game.sim.fighters[1]
				if f.state == "attack" and f.age >= 19 and f.age < 35: input.axis = 1
				if f.state == "attack" and f.age == 35: input.action = "attack0"
				var rival: Dictionary = game.training.sample(game.sim)
				game.combat_audio.before_step(game.sim)
				game.sim.step([input, rival])
				game.combat_audio.after_step(game.sim)
				game.training.after_step(game.sim)
		game.refresh()
		await process_frame
		await RenderingServer.frame_post_draw
	# Credits check after adding the arrangement to the existing list.
	game.return_to_menu()
	game.menu.show_credits()
	game.menu.credits.show_page(1)
	for i in range(15): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://art/reviews/training-music/creditos.png")
	print("Training music preview: %d confirmed exercise successes" % game.training.successes)
	game.queue_free()
	await process_frame
	quit()
