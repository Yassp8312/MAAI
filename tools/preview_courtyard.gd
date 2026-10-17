extends SceneTree
var game

func _initialize() -> void:
	run.call_deferred()

func capture(name: String) -> void:
	game.refresh()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://art/reviews/patio-%s.png" % name)

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.play_intro_on_start = false
	game.settings.storage_path = "user://courtyard-preview-unused.cfg"
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.capture_frames = 1
	DisplayServer.window_set_size(Vector2i(960, 540))
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
	DisplayServer.window_set_position(Vector2i(-2200, -1200))
	for entry in game.menu.roster:
		game.select_character(0, entry.id)
		game.select_character(1, entry.id)
		game.start_game()
		game.sim.phase = "fight"
		await capture(entry.id)
	game.select_character(0, "tsukiyo")
	game.select_character(1, "daichi")
	game.start_game()
	game.sim.phase = "fight"
	game.sim.step([{"action": "jump"}, {}])
	for i in range(16):
		game.sim.step([{}, {}])
	await capture("salto")
	game.sim.fighters[0].state = "dead"
	await capture("ko-aereo")
	game.start_game()
	game.sim.phase = "fight"
	game.sim.fighters[0].pos.x = game.sim.config.arena_left
	game.sim.fighters[1].pos.x = game.sim.config.arena_right
	await capture("limites")
	game.open_pause()
	await capture("pausa")
	game.toggle_arena()
	game.resume_game()
	await capture("laboratorio")
	if "--record" in OS.get_cmdline_user_args():
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tmp/courtyard-record"))
		game.toggle_arena()
		game.select_character(0, "tsukiyo")
		game.select_character(1, "ren")
		game.start_game()
		game.sim.phase = "fight"
		game.arena.set_process(false)
		for frame in range(240):
			for tick in range(2):
				var first: Dictionary = {}
				var second: Dictionary = {}
				if tick == 0:
					if frame == 45:
						first.action = "jump"
					elif frame == 140:
						first.action = "dodge"
					if frame == 95:
						second.action = "attack0"
				if frame >= 180 and frame < 192:
					first.axis = 1
					second.axis = -1
				game.sim.step([first, second])
			game.refresh()
			game.arena._process(1.0 / 30)
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://tmp/courtyard-record/%04d.png" % frame)
	game.queue_free()
	await process_frame
	quit()
