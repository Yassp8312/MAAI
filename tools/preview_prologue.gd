extends SceneTree
var game

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.settings.storage_path = "user://prologue-preview-unused.cfg"
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.capture_frames = 1
	DisplayServer.window_set_size(Vector2i(1600, 900) if "--record" in OS.get_cmdline_user_args() else Vector2i(960, 540))
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
	DisplayServer.window_set_position(Vector2i(-2200, -1200))
	var intro = game.menu.prologue
	intro.clean_preview = true
	intro.seek_preview(0)
	intro.set_paused(false)
	await create_timer(0.5).timeout
	for seconds in [3, 10, 16, 20, 23, 26, 31, 38, 45]:
		intro.seek_preview(seconds)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://art/reviews/prologo-v03-%02d.png" % seconds)
	if "--record" in OS.get_cmdline_user_args():
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tmp/prologue-v03-record"))
		for frame in range(ceili(intro.duration() * 30)):
			intro.seek_preview(frame / 30.0)
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_jpg("res://tmp/prologue-v03-record/%04d.jpg" % frame, 0.96)
	game.queue_free()
	await process_frame
	quit()
