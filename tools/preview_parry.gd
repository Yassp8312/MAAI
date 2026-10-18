extends SceneTree
## Real combat, alternating successful deflection, counter and failed timing.
const IDS = ["tsukiyo", "ren", "daichi", "nao", "sayo"]
var game
var caption: Label
var cues: Array = []

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://art/reviews/parry"))
	game = load("res://scenes/main.tscn").instantiate()
	game.play_intro_on_start = false
	game.settings.storage_path = "user://parry-preview-unused.cfg"
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
	caption.position = Vector2(385, 300)
	caption.size = Vector2(830, 45)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_color_override("font_color", Color("252923"))
	caption.add_theme_font_size_override("font_size", 24)
	layer.add_child(caption)
	game.combat_audio.cue_emitted.connect(func(c): cues.append(c))
	for section in range(5):
		game.select_character(0, IDS[section])
		game.select_character(1, IDS[(section + 1) % 5])
		game.start_game("practice")
		game.cycle_training()
		# Both characters can reach; no automatic input during this scripted capture.
		game.sim.fighters[0].pos.x = 710
		game.sim.fighters[1].pos.x = 820
		for frame in range(150):
			caption.text = "Bloqueo preciso → arma desviada → respuesta" if frame < 95 else "Demasiado pronto: mantener el botón no protege"
			if frame == 95:
				game.training.reset(game.sim)
				game.sim.fighters[0].pos.x = 710
				game.sim.fighters[1].pos.x = 820
			for subframe in range(2):
				var inputs: Array = [{}, {}]
				var t: int = frame * 2 + subframe
				if t in [50, 240]: inputs[1].action = "attack0"
				if t in [56, 220]: inputs[0].action = "parry"
				if t == 67: inputs[0].action = "attack0"
				game.combat_audio.before_step(game.sim)
				game.sim.step(inputs)
				game.combat_audio.after_step(game.sim)
			game.refresh()
			await process_frame
			await RenderingServer.frame_post_draw
			if frame in [30, 34]:
				root.get_texture().get_image().save_png("res://art/reviews/parry/%s-%d.png" % [IDS[section], frame])
	game.return_to_menu()
	game.open_options()
	game.options.tabs.current_tab = 2
	caption.hide()
	for frame in range(4): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://art/reviews/parry/controles.png")
	assert(game.options.key_buttons[-1].get_global_rect().end.y < game.options.status.get_global_rect().position.y, "Defence binding must fit above status and footer")
	print("Preview: %d parries, %d body hits" % [cues.filter(func(c): return c.kind == "parry").size(), cues.filter(func(c): return c.kind == "impact").size()])
	game.combat_audio.reset()
	game.queue_free()
	await process_frame
	quit()
