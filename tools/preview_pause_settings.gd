extends SceneTree
var game

func _initialize() -> void:
	run.call_deferred()

func capture(name: String) -> void:
	game.refresh()
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://art/reviews/interface-options/%s.png" % name)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://art/reviews/interface-options"))
	game = load("res://scenes/main.tscn").instantiate()
	game.play_intro_on_start = false
	game.settings.storage_path = "user://interface-preview-unused.cfg"
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.capture_frames = 1
	DisplayServer.window_set_size(Vector2i(960, 540))
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
	DisplayServer.window_set_position(Vector2i(-2200, -1200))
	game.select_character(0, "tsukiyo")
	game.select_character(1, "daichi")
	game.start_game()
	game.sim.phase = "fight"
	game.sim.scores = [1, 0]
	game.open_pause()
	await capture("pausa")
	game.open_options()
	for index in range(3):
		game.options.tabs.current_tab = index
		await capture(["pantalla", "sonido", "controles"][index])
	game.options.begin_capture(0, true)
	await capture("asignacion")
	game.options.cancel_capture()
	game.options.tabs.current_tab = 0
	game.options.draft.display.vsync = not game.options.draft.display.vsync
	game.options.save_requested()
	await capture("confirmacion")
	game.options.revert_preview()
	game.options.cancel()
	game.queue_free()
	await process_frame
	quit()
