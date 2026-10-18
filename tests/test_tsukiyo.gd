extends SceneTree
const TsukiyoAnimation = preload("res://scripts/tsukiyo_animation.gd")
const Simulation = preload("res://scripts/combat_sim.gd")
var checks: int = 0
var failures: int = 0
var visual: bool = "--visual" in OS.get_cmdline_user_args()
var record: bool = "--record" in OS.get_cmdline_user_args()

func _initialize() -> void:
	run.call_deferred()

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)

func run() -> void:
	var animation := TsukiyoAnimation.new()
	var simulation := Simulation.new()
	check(animation.sheets.size() == 7, "Six Tsukiyo sheets plus defence loaded")
	for id in animation.sheets:
		check(animation.sheets[id].size() == (6 if id in ["sprint", "defence"] else 8), "All separate cels in " + id)
		for cel in animation.sheets[id]:
			check(cel.mesh.get_surface_count() == 1 and cel.texture != null, "Cel has valid cached render geometry")
	for i in range(6):
		var attack: Resource = simulation.attack_data(simulation.fighters[0], i)
		var fighter: Dictionary = simulation.fighters[0]
		fighter.state = "attack"
		fighter.attack = i
		var clip: Dictionary = animation.clips[attack.id]
		for phase in range(3):
			fighter.age = [0, attack.startup, attack.startup + attack.active][phase]
			var before: String = JSON.stringify(simulation.fighters)
			var cel: Dictionary = animation.pose(simulation, 0)
			check(cel.clip == attack.id and cel.frame == clip.phases[phase][0], "Correct cel at %s phase %d" % [attack.id, phase])
			check(before == JSON.stringify(simulation.fighters), "Rendering never mutates combat")
	var fighter: Dictionary = simulation.fighters[0]
	fighter.state = "idle"
	fighter.pos.x = fighter.previous.x + 5
	check(animation.pose(simulation, 0).clip == "walk", "Forward movement uses walk cycle")
	fighter.pos.x = fighter.previous.x - 5
	check(animation.pose(simulation, 0).clip == "backstep", "Retreat selects reverse-footwork cycle")
	fighter.pos.y -= 100
	fighter.vy = -1
	check(animation.pose(simulation, 0).clip == "jump", "Ascending jump has own pose")
	fighter.vy = 1
	check(animation.pose(simulation, 0).clip == "fall", "Descending jump has own pose")
	fighter.state = "dodge"
	fighter.age = simulation.config.dodge_start
	check(animation.pose(simulation, 0).frame == 1, "Low evasion pose coincides with invulnerability")
	fighter.age = simulation.config.dodge_end
	check(animation.pose(simulation, 0).frame == 2, "Dodge recovery begins after invulnerability")
	fighter.state = "dead"
	simulation.phase_tick = 100
	fighter.pos.y = simulation.config.floor_y
	fighter.vy = 0
	fighter.death_ground_age = 100
	check(animation.pose(simulation, 0).frame == 2, "Defeat holds the final fallen drawing")
	# Verify actual simulation ticks: no backward pose jumps or early looping.
	for player in range(2):
		simulation.reset_round()
		simulation.phase = "fight"
		var origin: float = simulation.fighters[player].pos.x
		var direction: int = simulation.fighters[player].facing
		var sequence: Array = []
		for age in range(simulation.config.sprint_ticks):
			var inputs: Array = [{}, {}]
			if age == 0:
				inputs[player] = {"action": "sprint"}
			simulation.step(inputs)
			var before: String = JSON.stringify(simulation.fighters)
			var cel: Dictionary = animation.pose(simulation, player)
			sequence.append(cel.frame)
			check(cel.clip == "sprint" and cel.frame == int(age / 3.0), "Sprint advances once through six poses on either side")
			check(before == JSON.stringify(simulation.fighters), "Sprint rendering never changes combat")
		check(sequence.front() == 0 and sequence.back() == 5, "Sprint starts in anticipation and ends settled")
		check(is_equal_approx((simulation.fighters[player].pos.x - origin) * direction, 260.0), "Sprint still travels 260 pixels in 18 ticks")
		simulation.step([{}, {}])
		check(animation.pose(simulation, player).clip == "idle", "Sprint returns directly to guard")
	if visual or record:
		await render_review()
	print("Tsukiyo: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func render_review() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.play_intro_on_start = false
	game.settings.storage_path = "user://tsukiyo-visual-review-unused.cfg"
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.capture_frames = 1 # Suppress focus-loss pause in automated capture only.
	game.start_demo()
	if record:
		DisplayServer.window_set_size(Vector2i(960, 540))
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tmp/tsukiyo-record"))
	var capture_index: int = 0
	for tick in range(1320):
		game.sim.step(game.demo_inputs())
		game.refresh()
		if (record and tick % 6 == 0) or tick in [0, 385, 508, 630, 755, 880, 1000, 1140, 1230]:
			await process_frame
			await RenderingServer.frame_post_draw
			var image := root.get_texture().get_image()
			if record and tick % 6 == 0:
				image.save_png("res://tmp/tsukiyo-record/%04d.png" % capture_index)
				capture_index += 1
			if tick in [0, 385, 508, 630, 755, 880, 1000, 1140, 1230]:
				image.save_png("res://tmp/tsukiyo-%04d.png" % tick)
	check(game.demo_tick == 1320, "Full demonstration traverses all eleven stages")
	game.queue_free()
	await process_frame
