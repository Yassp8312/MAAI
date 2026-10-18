extends SceneTree
## Reproducible native capture; all contacts come from the real simulation.
var game
var caption: Label
const OUT = "res://art/reviews/character-kits/"

func _initialize() -> void:
	run.call_deferred()

func capture(name: String) -> void:
	root.get_texture().get_image().save_png(OUT + name + ".png")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	game = load("res://scenes/main.tscn").instantiate()
	game.play_intro_on_start = false
	game.settings.storage_path = "user://character-kits-preview-unused.cfg"
	root.add_child(game)
	game.set_physics_process(false)
	game.capture_frames = 1
	DisplayServer.window_set_size(Vector2i(960, 540))
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
	DisplayServer.window_set_position(Vector2i(-2200, -1200))
	game.settings.values.audio.Music = 0
	game.settings.apply_audio(game.settings.values.audio)
	var layer := CanvasLayer.new()
	layer.layer = 30
	root.add_child(layer)
	caption = Label.new()
	caption.position = Vector2(300, 300)
	caption.size = Vector2(1000, 45)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_color_override("font_color", Color("252923"))
	caption.add_theme_font_size_override("font_size", 24)
	layer.add_child(caption)
	var scenes: Array = [
		["nao", "daichi", 335, "Nao: provocar el fallo, acercarse y entrar"],
		["nao", "daichi", 285, "Daichi: una entrada sin preparación sigue siendo interceptable"],
		["ren", "tsukiyo", 315, "Ren: la estocada acompaña el paso hacia delante"],
		["sayo", "nao", 350, "Sayo: el corte bajo recoge distancia al retirarse"]
	]
	for section in range(scenes.size()):
		var scene: Array = scenes[section]
		game.select_character(0, scene[0])
		game.select_character(1, scene[1])
		game.start_game("practice")
		game.sim.phase = "fight"
		game.sim.fighters[0].pos.x = 600
		game.sim.fighters[1].pos.x = 600 + scene[2]
		caption.text = scene[3]
		var winner: int = -1
		for frame in range(90):
			for subframe in range(2):
				var t: int = frame * 2 + subframe
				var inputs: Array = [{}, {}]
				if section == 0:
					if t == 30: inputs[1].action = "attack0"
					if t >= 50 and t < 66: inputs[0].axis = 1
					if t == 66: inputs[0].action = "attack0"
				elif t == 30:
					inputs[0].action = "attack2" if section == 3 else "attack0"
					if section == 1: inputs[1].action = "attack0"
				game.combat_audio.before_step(game.sim)
				game.sim.step(inputs)
				game.combat_audio.after_step(game.sim)
				if game.sim.scores.max() > 0: winner = game.sim.scores.find(1)
			game.refresh()
			await process_frame
			await RenderingServer.frame_post_draw
			if frame in [20, 37]: capture("scene-%d-%d" % [section, frame])
		if section < 3: assert(winner == (1 if section == 1 else 0), "Actual matchup result changed")
	caption.hide()
	game.select_character(0, "nao")
	game.select_character(1, "daichi")
	game.start_game("practice")
	game.open_pause()
	assert(not game.training_panel.visible, "Practice controls must not cover the pause menu")
	for frame in range(4): await process_frame
	await RenderingServer.frame_post_draw
	capture("pausa")
	game.move_guide.open()
	for frame in range(60):
		await process_frame
		await RenderingServer.frame_post_draw
		if frame == 10: capture("tecnicas")
	for player in range(2):
		for move in range(5):
			assert(game.move_guide.move_roles[player][move].get_global_rect().end.y <= game.move_guide.move_titles[player][move + 1].get_global_rect().position.y, "Move descriptions must not overlap")
	game.return_to_selection()
	game.menu.choose(0, 1)
	for frame in range(15): await process_frame
	await RenderingServer.frame_post_draw
	capture("seleccion")
	game.combat_audio.reset()
	game.queue_free()
	await process_frame
	print("Character kits native preview: matchup outcomes and guide layout passed")
	quit()
