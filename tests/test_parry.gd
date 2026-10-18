extends SceneTree
const Simulation = preload("res://scripts/combat_sim.gd")
const Settings = preload("res://scripts/game_settings.gd")
const LocalInput = preload("res://scripts/local_input.gd")
const Audio = preload("res://scripts/combat_audio.gd")
const Dummy = preload("res://scripts/training_dummy.gd")
var checks: int = 0
var failures: int = 0
var cues: Array = []

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(description)

func fresh():
	var sim = Simulation.new()
	sim.phase = "fight"
	sim.fighters[0].pos.x = 700
	sim.fighters[1].pos.x = 800
	return sim

func tick(sim, count: int) -> void:
	for i in range(count): sim.step([{}, {}])

func run() -> void:
	# Both sides, every weapon and attack height, first/last successful tick and expiry.
	for id in Simulation.CHARACTER_PROFILES:
		for defender in range(2):
			for move in range(6):
				for age in [0, 8, 9, 15]:
					var sim = fresh()
					sim.set_character(defender, id)
					sim.set_character(1 - defender, id)
					var a: Dictionary = sim.fighters[1 - defender]
					var d: Dictionary = sim.fighters[defender]
					# Place the actual active blade at torso height (including aerial techniques).
					a.state = "attack"
					a.attack = move
					a.attack_dir = a.facing
					a.age = sim.attack_data(a, move).startup - 1
					d.state = "parry"
					d.age = age - 1
					sim.step([{}, {}])
					check(d.state == ("parry_success" if age < 9 else "dead"), "%s side %d move %d defence age %d" % [id, defender, move, age])
					if age < 9:
						check(sim.events.size() == 1 and sim.events[0].kind == "parry" and a.state == "parried" and sim.scores == [0, 0], "Deflection produces one event, recoil and no KO")
						tick(sim, 5)
						check(d.state == "parry_success" and a.state == "parried" and sim.events.is_empty(), "No repeated contact from the stopped attack")
						tick(sim, 1)
						check(d.state == "idle" and a.state == "parried", "Defender recovers first")
						tick(sim, 12)
						check(a.state == "idle", "Attacker recovers without a stuck state")
	var sim = fresh()
	sim.step([{"action": "parry"}, {}])
	check(sim.parry_ready(sim.fighters[0]) and sim.fighters[0].age == 0, "Defence starts immediately")
	tick(sim, 9)
	check(not sim.parry_ready(sim.fighters[0]), "Early defence expires without any hit")
	tick(sim, 40)
	check(sim.fighters[0].state == "idle", "Empty attempt returns to idle")
	for command in ["attack0", "dodge", "jump"]:
		sim = fresh()
		sim.fighters[1].pos.x = 1400
		sim.step([{"action": command}, {}])
		sim.step([{"action": "parry"}, {}])
		check(sim.fighters[0].state != "parry" and sim.fighters[0].buffer != "parry", "Cannot cancel or buffer defence during %s" % command)
		tick(sim, 65)
		check(sim.fighters[0].state == "idle", "Rejected defence never triggers on recovery/landing")
	sim = fresh()
	sim.step([{"action": "sprint", "axis": -1}, {}])
	var x: float = sim.fighters[0].pos.x
	sim.step([{"action": "parry"}, {}])
	check(sim.fighters[0].state == "parry" and sim.fighters[0].pos.x == x, "Sprint can plant into defence immediately")
	sim = fresh()
	sim.fighters[1].parry_dir = 1
	sim.fighters[1].state = "parry"
	sim.fighters[0].state = "attack"
	sim.fighters[0].attack = 0
	sim.fighters[0].attack_dir = 1
	sim.fighters[0].age = 8
	sim.step([{}, {}])
	check(sim.fighters[1].state == "dead", "Defence does not cover behind its locked direction")
	sim = fresh()
	sim.fighters[1].pos.x = 1400
	sim.step([{"action": "attack0"}, {"action": "parry"}])
	tick(sim, 12)
	check(sim.fighters[0].state == "attack" and sim.fighters[1].state == "parry", "Whiff creates neither recoil nor deflection")
	sim = fresh()
	sim.step([{"action": "parry"}, {"action": "parry"}])
	check(sim.events.is_empty(), "Two defence attempts cannot parry each other")

	# Existing customized controls survive migration, even when E/J/R3 were occupied.
	var old_keys: Array = [Settings.DEFAULT_KEYS[0].slice(0, 8), Settings.DEFAULT_KEYS[1].slice(0, 8)]
	old_keys[0][0] = KEY_E
	old_keys[1][0] = KEY_J
	var migrated = Settings.migrate_bindings(old_keys, true)
	check(Settings.valid_bindings(migrated, true), "Migrated keyboard remains conflict-free")
	check(migrated[0].slice(0, 8) == old_keys[0] and migrated[1].slice(0, 8) == old_keys[1], "Migration preserves all existing keyboard actions")
	var old_pads: Array = [Settings.DEFAULT_PAD.slice(0, 6), Settings.DEFAULT_PAD.slice(0, 6)]
	old_pads[0][0] = JOY_BUTTON_RIGHT_STICK
	migrated = Settings.migrate_bindings(old_pads, false)
	check(Settings.valid_bindings(migrated, false) and migrated[0].slice(0, 6) == old_pads[0], "Migration preserves pad assignments and finds free defence button")
	var settings = Settings.new()
	settings.apply_bindings()
	var adapter = LocalInput.new(settings)
	adapter.sample(0)
	Input.action_press("p0_8")
	check(adapter.sample(0).action == "parry", "New keyboard defence reaches input adapter")
	await physics_frame
	await physics_frame
	check(adapter.sample(0).action == "", "Holding defence does not repeat")
	adapter.block_until_release()
	check(adapter.sample(0).action == "", "Held defence cannot leak from menus")
	Input.action_release("p0_8")
	adapter.sample(0)
	Input.action_press("p0_8")
	check(adapter.sample(0).action == "parry", "Release then press allows a new attempt")
	Input.action_release("p0_8")

	Settings.apply_audio(Settings.defaults().audio)
	var audio = Audio.new()
	root.add_child(audio)
	audio.cue_emitted.connect(func(c): cues.append(c))
	for id in Simulation.CHARACTER_PROFILES:
		sim = fresh()
		sim.set_character(1, id)
		sim.fighters[0].state = "attack"
		sim.fighters[0].attack = 0
		sim.fighters[0].attack_dir = 1
		sim.fighters[0].age = 8
		audio.reset()
		audio.present(true, true)
		cues.clear()
		audio.before_step(sim)
		sim.step([{}, {"action": "parry"}])
		audio.after_step(sim)
		for i in range(10):
			audio.before_step(sim)
			sim.step([{}, {}])
			audio.after_step(sim)
		check(cues.filter(func(c): return c.kind == "parry").size() == 1, "%s plays one metallic deflection" % id)
		check(cues.filter(func(c): return c.kind == "impact").is_empty(), "Parry never plays a body hit")
		check(cues.filter(func(c): return c.kind == "parry")[0].path.contains("/%s/parry-" % id), "Uses defender's weapon bank")
	audio.reset()
	await physics_frame
	audio.queue_free()

	var dummy = Dummy.new()
	sim = fresh()
	for move in range(3):
		dummy.cycle(sim)
		check(dummy.move == move and sim.phase == "fight", "Practice cycles repeatable move")
		var actions: int = 0
		for i in range(60):
			if not dummy.sample(sim).is_empty(): actions += 1
		check(actions == 1, "Dummy waits before first attack")
	dummy.cycle(sim)
	check(dummy.move == -1, "Practice returns to free controls")
	var game = load("res://scenes/main.tscn").instantiate()
	game.play_intro_on_start = false
	game.settings.storage_path = "user://parry-integration-unused.cfg"
	root.add_child(game)
	game.set_physics_process(false)
	game.start_game("practice")
	check(game.training_button.visible, "Practice exposes a mouse-accessible drill control")
	game.training_button.pressed.emit()
	check(game.training_menu.visible and game.paused, "Training button opens paused settings")
	game.training_menu.exercise("parry")
	check(game.training.move == 0 and game.sim.phase == "fight", "Parry exercise resets into a repeatable encounter")
	game.open_pause()
	game.refresh()
	check(not game.training_button.visible, "Drill control cannot reset a paused encounter")
	game.resume_game()
	game.start_game()
	check(game.training.move == -1 and not game.training_button.visible, "A duel clears the training controller")
	game.open_options()
	game.options.tabs.current_tab = 2
	await process_frame
	await process_frame
	check(game.options.key_buttons.size() == 9 and game.options.pad_buttons.size() == 7, "Options expose defence for keyboard and pad")
	# Dummy/headless fonts have different metrics; native preview checks the actual layout.
	if DisplayServer.get_name() != "headless":
		check(game.options.key_buttons[-1].get_global_rect().end.y < game.options.save_button.get_global_rect().position.y, "New binding row fits above the options footer")
	game.queue_free()
	await process_frame
	print("MAAI parry: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
