extends SceneTree
var game
var menu
var recording: bool = "--record" in OS.get_cmdline_user_args()
var frame_index: int = 0

func _initialize() -> void:
	run.call_deferred()

func capture(name: String) -> void:
	for i in range(90 if recording else 24):
		if recording and menu.screen == "versus":
			menu.transition_remaining = maxf(0.1, menu.transition_remaining - 1.0 / 60)
			menu.queue_redraw()
		await process_frame
		if recording and i % 2 == 0:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://tmp/frontend-record/%04d.png" % frame_index)
			frame_index += 1
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tmp/ui-" + name + ".png")

func run() -> void:
	if recording:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tmp/frontend-record"))
	game = load("res://scenes/main.tscn").instantiate()
	game.play_intro_on_start = false
	game.settings.storage_path = "user://frontend-preview-unused.cfg"
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.capture_frames = 1
	DisplayServer.window_set_size(Vector2i(960, 540))
	menu = game.menu
	await capture("title")
	menu.show_home()
	await capture("home")
	menu.open_selection()
	menu.choose(0, 4)
	menu.choose(1, 1)
	await capture("selection")
	menu.confirm_player(0)
	await capture("ready")
	menu.confirm_player(1)
	menu.set_process(false)
	await capture("versus")
	menu.launch()
	game.sim.scores = [2, 1]
	game.sim.phase = "match_over"
	menu.show_result()
	await capture("result")
	game.start_game()
	game.open_pause()
	await capture("pause")
	game.queue_free()
	await process_frame
	print("Front end: title, home, selection, ready, versus, result and pause captured")
	quit()
