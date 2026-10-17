extends SceneTree
## Record with --write-movie tmp/combat-audio.avi --fixed-fps 30.
var game
var title: Label
var caption: Label
var frame: int = 0
var record: Array = []
const IDS = ["tsukiyo", "ren", "daichi", "nao", "sayo"]
const DETAILS = ["Pisada ligera · hoja precisa", "Cuero y apoyo firme · corte áspero", "Apoyo pesado · asta y barrido grave", "Paso amortiguado · hoja corta y rápida", "Tela ligera · apertura y chasquido del abanico"]

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.play_intro_on_start = false
	game.settings.storage_path = "user://combat-audio-preview-unused.cfg"
	root.add_child(game)
	game.set_physics_process(false)
	game.capture_frames = 1
	DisplayServer.window_set_size(Vector2i(960, 540))
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
	DisplayServer.window_set_position(Vector2i(-2200, -1200))
	game.settings.values.audio = game.settings.defaults().audio
	game.settings.values.audio.Music = 0
	game.settings.values.audio.Ambience = 0
	game.settings.apply_audio(game.settings.values.audio)
	var layer := CanvasLayer.new()
	layer.layer = 30
	root.add_child(layer)
	var bg := ColorRect.new()
	bg.color = Color("101512")
	bg.position = Vector2(250, 120)
	bg.size = Vector2(1100, 140)
	layer.add_child(bg)
	title = Label.new()
	title.position = Vector2(270, 128)
	title.size = Vector2(1060, 58)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	layer.add_child(title)
	caption = Label.new()
	caption.position = Vector2(270, 195)
	caption.size = Vector2(1060, 55)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size", 24)
	layer.add_child(caption)
	game.combat_audio.cue_emitted.connect(func(c):
		var item: Dictionary = c.duplicate()
		item["video_frame"] = frame
		record.append(item))
	for section in range(5):
		game.select_character(0, IDS[section])
		game.select_character(1, IDS[(section + 1) % 5])
		game.start_game()
		game.sim.phase = "fight"
		title.text = IDS[section].to_upper() + " — " + DETAILS[section]
		for local_frame in range(270):
			frame = section * 270 + local_frame
			if local_frame == 210:
				game.sim.reset_round()
				game.sim.phase = "fight"
				game.sim.fighters[1].pos.x = game.sim.fighters[0].pos.x + 130
				game.combat_audio.reset()
			caption.text = "Pasos y retroceso" if local_frame < 65 else ("Ataque sin contacto" if local_frame < 100 else ("Esquiva" if local_frame < 135 else ("Salto y aterrizaje" if local_frame < 210 else "Golpe e impacto en el suelo")))
			for substep in range(2):
				var input: Dictionary = {}
				if local_frame >= 12 and local_frame < 35:
					input.axis = 1
				elif local_frame >= 38 and local_frame < 61:
					input.axis = -1
				if substep == 0:
					if local_frame == 70 or local_frame == 215:
						input.action = "attack0"
					elif local_frame == 105:
						input.action = "dodge"
					elif local_frame == 140:
						input.action = "jump"
				game.combat_audio.before_step(game.sim)
				game.sim.step([input, {}])
				game.combat_audio.after_step(game.sim)
			game.refresh()
			await process_frame
			await RenderingServer.frame_post_draw
			if local_frame == 80:
				root.get_texture().get_image().save_png("res://tmp/combat-audio-%s.png" % IDS[section])
	FileAccess.open("res://tmp/combat-audio-events.json", FileAccess.WRITE).store_string(JSON.stringify(record, "\t"))
	game.queue_free()
	await process_frame
	quit()
