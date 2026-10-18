extends SceneTree
var game
const OUT = "res://art/reviews/mvp/"
func _initialize() -> void:
	run.call_deferred()

func shot(name: String, frames: int = 15) -> void:
	for i in range(frames): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + name + ".png")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	game = load("res://scenes/main.tscn").instantiate()
	game.play_intro_on_start = false
	game.settings.storage_path = "user://mvp-preview-unused.cfg"
	root.add_child(game)
	game.set_physics_process(false)
	game.capture_frames = 1
	DisplayServer.window_set_size(Vector2i(1280, 720))
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
	DisplayServer.window_set_position(Vector2i(-2200, -1200))
	game.settings.values.audio.Master = 0
	game.settings.apply_audio(game.settings.values.audio)
	game.menu.play_boot()
	await shot("studio", 60)
	game.menu.show_home()
	await shot("menu")
	game.menu.show_credits()
	await shot("creditos-equipo")
	game.menu.credits.show_page(1)
	await shot("creditos-recursos")
	game.menu.open_selection("practice")
	game.menu.choose(0, 3)
	game.menu.choose(1, 2)
	await shot("seleccion")
	game.start_game("practice")
	for index in range(3):
		game.select_arena(index)
		await shot("arena-%d" % index)
	game.training_menu.open()
	await shot("entrenamiento")
	game.training_menu.exercise("punish")
	for tick in range(120):
		var input: Dictionary = {}
		if tick >= 79 and tick < 95: input.axis = 1
		if tick == 95: input.action = "attack0"
		var rival: Dictionary = game.training.sample(game.sim)
		game.combat_audio.before_step(game.sim)
		game.sim.step([input, rival])
		game.combat_audio.after_step(game.sim)
		game.training.after_step(game.sim)
		game.refresh()
		await process_frame
		if tick == 110:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(OUT + "ejercicio.png")
	assert(game.training.successes == 1, "Captured exercise must succeed through real collision")
	game.open_pause()
	await shot("pausa")
	game.queue_free()
	await process_frame
	print("MVP native preview completed")
	quit()
