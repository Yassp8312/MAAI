extends SceneTree
const CharacterAnimation = preload("res://scripts/tsukiyo_animation.gd")
const Catalog = preload("res://scripts/character_catalog.gd")
const Simulation = preload("res://scripts/combat_sim.gd")
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func run() -> void:
	var roster: Array = Catalog.available()
	check(roster.size() == 5, "All five characters are available")
	var previous_texture: Texture2D
	for entry in roster:
		var animation := CharacterAnimation.new(entry.id)
		check(animation.clips.size() == 14, entry.id + " has all combat clips")
		var twin := CharacterAnimation.new(entry.id)
		check(twin.sheets.guard[0].mesh == animation.sheets.guard[0].mesh, "Same character shares cached meshes")
		check(animation.sheets.guard[0].texture != previous_texture, "Different characters never reuse another character's texture")
		previous_texture = animation.sheets.guard[0].texture
		for name in animation.clips:
			var clip: Dictionary = animation.clips[name]
			for ref in clip.frames:
				check(animation.sheets.has(ref[0]) and int(ref[1]) < animation.sheets[ref[0]].size(), "Every clip references an existing cel")
		var simulation := Simulation.new()
		simulation.phase = "fight"
		for player in range(2):
			for forward in [true, false]:
				simulation.reset_round()
				simulation.phase = "fight"
				var facing: int = simulation.fighters[player].facing
				var origin: float = simulation.fighters[player].pos.x
				for tick in range(12):
					var inputs: Array = [{}, {}]
					inputs[player] = {"axis": facing * (1 if forward else -1)}
					simulation.step(inputs)
					var pose: Dictionary = animation.pose(simulation, player)
					check(pose.clip == ("walk" if forward else "backstep"), "Movement selects forward/backward animation on either side")
					check(simulation.fighters[player].facing == facing, "Retreat keeps facing the opponent")
				check(is_equal_approx(absf(simulation.fighters[player].pos.x - origin), 12 * simulation.config.walk_speed), "New footwork preserves movement distance")
			for state in ["idle", "sprint", "dodge", "dead"]:
				simulation.fighters[player].state = state
				for age in range(30):
					simulation.fighters[player].age = age
					simulation.fighters[player].death_ground_age = age
					simulation.phase_tick = age
					var before := JSON.stringify(simulation.fighters)
					var pose: Dictionary = animation.pose(simulation, player)
					check(pose.mesh.get_surface_count() == 1, "State produces valid geometry: " + state)
					check(before == JSON.stringify(simulation.fighters), "Art cannot alter simulation")
			for attack_index in range(6):
				var attack: Resource = simulation.config.attacks[attack_index]
				simulation.fighters[player].state = "attack"
				simulation.fighters[player].attack = attack_index
				for age in range(attack.startup + attack.active + attack.finish):
					simulation.fighters[player].age = age
					check(animation.pose(simulation, player).clip == attack.id, "Complete attack timeline supported")
	var game = load("res://scenes/main.tscn").instantiate()
	game.play_intro_on_start = false
	game.settings.storage_path = "user://character-review-unused.cfg"
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	check(game.menu.roster_buttons.size() == 2, "Both players have a portrait selector")
	for index in range(roster.size()):
		game.menu.open_selection()
		for player in range(2):
			game.menu.roster_buttons[player][index].pressed.emit()
			check(game.selected_characters[player] == roster[index].id, "Selector signal changes the intended player")
			check(game.sim.fighters[player].character_id == roster[index].id, "Selector applies the matching combat profile")
		game.start_game()
		check(game.views[0].character_id == roster[index].id and game.views[1].character_id == roster[index].id, "Mirror match uses chosen character on both sides")
		check(game.sim.character_ids == [roster[index].id, roster[index].id], "Match reset preserves both combat profiles")
		game.start_demo()
		for tick in range(1320):
			game.sim.step(game.demo_inputs())
			for player in range(2):
				game.views[player].character_animation.pose(game.sim, player)
		check(game.demo_tick == 1320, "Entire demonstration completes for " + roster[index].id)
		game.return_to_menu()
	game.select_character(0, roster.back().id)
	game.select_character(1, roster.front().id)
	game.start_game()
	check(game.views[0].character_id != game.views[1].character_id, "Mixed match preserves each independent choice")
	game.queue_free()
	await process_frame
	print("Characters: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
