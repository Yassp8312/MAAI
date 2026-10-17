extends SceneTree
## Capture actual game geometry and a real airborne KO from each side.
var game
const OUTPUT = "res://tmp/combat-review"

func _initialize() -> void:
	run.call_deferred()

func snapshot(name: String) -> void:
	game.refresh()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUTPUT + "/" + name + ".png")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	game = load("res://scenes/main.tscn").instantiate()
	game.play_intro_on_start = false
	game.settings.storage_path = "user://combat-review-unused.cfg"
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.capture_frames = 1
	DisplayServer.window_set_size(Vector2i(960, 540))
	game.debug_boxes = true
	for id in ["nao", "sayo", "tsukiyo", "ren", "daichi"]:
		game.select_character(0, id)
		game.start_game()
		game.sim.phase = "fight"
		var f: Dictionary = game.sim.fighters[0]
		f.state = "attack"
		f.attack = 0
		f.attack_dir = 1
		f.age = 12
		await snapshot("reach-" + id)
		game.sim.reset_round()
		game.sim.phase = "fight"
		f = game.sim.fighters[0]
		f.state = "dodge"
		f.age = 0
		await snapshot("dodge-before-" + id)
		f.age = game.sim.config.dodge_start
		await snapshot("dodge-low-" + id)
		f.age = game.sim.config.dodge_end
		await snapshot("dodge-after-" + id)
	game.debug_boxes = false
	game.select_character(0, "sayo")
	game.select_character(1, "tsukiyo")
	var index: int = 0
	for victim in range(2):
		game.start_game()
		game.sim.phase = "fight"
		for player in range(2):
			game.sim.fighters[player].pos = Vector2(650 + 150 * player, game.sim.config.floor_y - 180)
			game.sim.fighters[player].vy = -2
		var a: Dictionary = game.sim.fighters[1 - victim]
		a.state = "attack"
		a.attack = 3
		a.age = 7
		a.attack_dir = a.facing
		for tick in range(120):
			game.sim.step([{}, {}])
			await snapshot("death-%04d" % index)
			index += 1
	print("Combat review: 20 geometry captures, 240 death frames at 60 FPS")
	game.queue_free()
	await process_frame
	quit()
