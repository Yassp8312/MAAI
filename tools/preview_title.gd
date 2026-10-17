extends SceneTree
## Capture one complete carousel loop at its real timing, without touching saves.
func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tmp/title-record"))
	var game = load("res://scenes/main.tscn").instantiate()
	game.play_intro_on_start = false
	game.settings.storage_path = "user://frontend-preview-unused.cfg"
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.capture_frames = 1
	DisplayServer.window_set_size(Vector2i(960, 540))
	var menu = game.menu
	menu.set_process(false)
	menu.title_clock = 0
	for frame in range(720):
		menu._process(1.0 / 30)
		await process_frame
		await RenderingServer.frame_post_draw
		var capture := root.get_texture().get_image()
		capture.save_png("res://tmp/title-record/%04d.png" % frame)
		if frame % 135 == 45:
			capture.save_png("res://tmp/title-%s.png" % menu.roster[menu.title_index].id)
	game.queue_free()
	await process_frame
	quit()
