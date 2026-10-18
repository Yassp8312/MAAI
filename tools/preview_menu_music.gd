extends SceneTree
var game

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.play_intro_on_start = false
	game.settings.storage_path = "user://menu-music-preview-unused.cfg"
	root.add_child(game)
	game.set_physics_process(false)
	game.capture_frames = 1
	DisplayServer.window_set_size(Vector2i(960, 540))
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
	DisplayServer.window_set_position(Vector2i(-2200, -1200))
	for frame in range(990):
		if frame == 270:
			game.menu.show_home()
		elif frame == 450:
			game.open_options()
			game.options.tabs.current_tab = 1
		elif frame == 600:
			game.options.cancel()
			game.menu.open_selection()
			game.menu.choose(0, 0)
			game.menu.choose(1, 2)
		elif frame == 780:
			game.menu.confirm_player(0)
			game.menu.confirm_player(1)
		game.refresh()
		await process_frame
		await RenderingServer.frame_post_draw
	game.queue_free()
	await process_frame
	quit()
