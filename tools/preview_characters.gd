extends SceneTree
## Real game capture, one selected character per run, 30 fps.
func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var id: String = OS.get_cmdline_user_args()[0]
	var game = load("res://scenes/main.tscn").instantiate()
	game.play_intro_on_start = false
	game.settings.storage_path = "user://character-preview-unused.cfg"
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.capture_frames = 1
	DisplayServer.window_set_size(Vector2i(960, 540))
	game.select_character(0, id)
	game.select_character(1, "tsukiyo")
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tmp/characters-menu.png")
	game.start_demo()
	var output := "res://tmp/characters-" + id
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var index: int = 0
	for tick in range(1320):
		game.sim.step(game.demo_inputs())
		game.refresh()
		if tick % 2 == 0:
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(output + "/%04d.png" % index)
			index += 1
	game.return_to_menu()
	game.select_character(1, id)
	game.start_game()
	game.sim.phase = "fight"
	game.sim.step([{}, {"action": "attack0"}])
	for tick in range(10):
		game.sim.step([{}, {}])
	game.refresh()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output + "/mirrored.png")
	print("%s: %d frames at 30 fps and mirrored attack captured" % [id, index])
	game.queue_free()
	await process_frame
	quit()
