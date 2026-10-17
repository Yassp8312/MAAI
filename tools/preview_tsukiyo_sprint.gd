extends SceneTree
## Capture the real renderer at 60 Hz, then expose each tick four times for review.
## Only playback slows down; the same unmodified simulation drives both passes.
func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.play_intro_on_start = false
	game.settings.storage_path = "user://tsukiyo-sprint-review-unused.cfg"
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.capture_frames = 1
	game.start_game()
	game.practice = true
	DisplayServer.window_set_size(Vector2i(960, 540))
	var label := Label.new()
	label.position = Vector2(450, 215)
	label.add_theme_font_size_override("font_size", 24)
	game.add_child(label)
	var output := "res://tmp/tsukiyo-sprint-record"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var index: int = 0
	for slow in [false, true]:
		label.text = "SPRINT · " + ("CÁMARA LENTA ×0,25" if slow else "VELOCIDAD REAL")
		for player in range(2):
			game.sim.reset_round()
			game.sim.phase = "fight"
			for tick in range(90):
				var inputs: Array = [{}, {}]
				if tick == 25:
					inputs[player] = {"action": "sprint"}
				game.sim.step(inputs)
				game.refresh()
				await process_frame
				await RenderingServer.frame_post_draw
				var frame := root.get_texture().get_image()
				for repeat in range(4 if slow else 1):
					frame.save_png(output + "/%04d.png" % index)
					index += 1
	print("Sprint review: %d frames at 60 fps" % index)
	game.queue_free()
	await process_frame
	quit()
