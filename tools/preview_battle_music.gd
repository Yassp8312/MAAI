extends SceneTree
var game

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.play_intro_on_start = false
	game.settings.storage_path = "user://battle-music-preview-unused.cfg"
	root.add_child(game)
	game.set_physics_process(false)
	game.capture_frames = 1
	DisplayServer.window_set_size(Vector2i(960, 540))
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
	DisplayServer.window_set_position(Vector2i(-2200, -1200))
	game.select_character(0, "tsukiyo")
	game.select_character(1, "ren")
	var layer := CanvasLayer.new()
	layer.layer = 25
	root.add_child(layer)
	var label := Label.new()
	label.position = Vector2(460, 205)
	label.size = Vector2(680, 50)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", Color("242b28"))
	layer.add_child(label)
	for section in range(2):
		game.start_game()
		game.sim.phase = "fight"
		label.text = "Banda sonora2 · Combate 1" if section == 0 else "Banda sonora 3 · Combate 2"
		label.show()
		for frame in range(600):
			if frame == 360:
				game.open_pause()
			elif frame == 420:
				game.resume_game()
			elif frame == 480:
				game.sim.fighters[1].pos.x = game.sim.fighters[0].pos.x + 190
			elif frame == 570:
				game.return_to_menu()
				label.hide()
			if not game.paused and game.playing:
				for substep in range(2):
					var input: Dictionary = {}
					if frame >= 30 and frame < 65:
						input.axis = 1
					elif frame >= 70 and frame < 105:
						input.axis = -1
					if substep == 0:
						if frame in [150, 483]: input.action = "attack0"
						elif frame == 210: input.action = "dodge"
						elif frame == 270: input.action = "jump"
					game.combat_audio.before_step(game.sim)
					game.sim.step([input, {}])
					game.combat_audio.after_step(game.sim)
			game.refresh()
			await process_frame
			await RenderingServer.frame_post_draw
	game.queue_free()
	await process_frame
	quit()
