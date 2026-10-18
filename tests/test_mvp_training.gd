extends SceneTree
const Sim = preload("res://scripts/combat_sim.gd")
const Dummy = preload("res://scripts/training_dummy.gd")
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, why: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(why)

func step(sim, dummy, player: Dictionary = {}, manual: Dictionary = {}) -> void:
	var rival: Dictionary = dummy.sample(sim, manual)
	if dummy.should_step(sim): sim.step([player, rival])
	dummy.after_step(sim)

func run() -> void:
	print("Training checks: reset and behaviors")
	var sim = Sim.new()
	var t = Dummy.new()
	for distance in [110, 220, 335, 440]:
		t.distance = distance
		t.reset(sim)
		check(sim.phase == "fight" and sim.fighters[1].pos.x - sim.fighters[0].pos.x == distance, "Exact reset distance and no countdown")
	t.mode = "idle"
	var origin: Vector2 = sim.fighters[1].pos
	for i in range(30): step(sim, t, {}, {"axis": -1, "action": "attack0"})
	check(sim.fighters[1].pos == origin and sim.fighters[1].state == "idle", "Stationary dummy ignores manual J2 input")
	for mode in ["repeat", "dodge", "jump", "sequence"]:
		t.mode = mode
		t.move = 2
		t.distance = 440
		t.reset(sim)
		var actions: Array = []
		for i in range(280):
			var input: Dictionary = t.sample(sim)
			if input.has("action"): actions.append(input.action)
			sim.step([{}, input])
			t.after_step(sim)
		check(actions.size() >= 3, "Repeated behavior continues: " + mode)
		if mode == "sequence": check(actions.slice(0, 3) == ["attack0", "attack1", "attack2"], "Sequence respects order")
		else: check(actions[0] == {"repeat": "attack2", "dodge": "dodge", "jump": "jump"}[mode], "Correct configured action")
	t.mode = "parry"
	t.distance = 150
	t.reset(sim)
	step(sim, t, {"action": "attack0"})
	for i in range(20): step(sim, t)
	check(sim.scores == [0, 0] and sim.fighters[0].parry_tick > 0, "Dummy parry resolves through normal combat")
	check(sim.config.parry_window == 9 and sim.config.parried_ticks == 18, "Training preserves defence rules")
	# Record and replay the exact tick inputs, including movement, jump and release.
	print("Training checks: recording")
	t.distance = 440
	t.start_recording(sim)
	var positions: Array = []
	for i in range(120):
		var input: Dictionary = {"axis": -1 if i < 20 else 0}
		if i == 22: input.action = "jump"
		if i == 30: input.action = "attack1"
		step(sim, t, {}, input)
		positions.append(sim.fighters[1].pos)
	t.finish_recording()
	check(t.recording_inputs.size() == 120 and t.can_replay(sim), "Recording keeps 120 tick inputs for current matchup")
	t.mode = "replay"
	t.reset(sim)
	for i in range(120):
		step(sim, t)
		check(sim.fighters[1].pos == positions[i], "Replay reproduces movement at tick %d" % i)
	sim.set_character(1, "nao")
	check(not t.can_replay(sim), "Changing matchup invalidates incompatible recording")
	sim.set_character(1, "tsukiyo")
	t.start_recording(sim)
	for i in range(320): step(sim, t)
	check(not t.recording and t.recording_inputs.size() == 300, "Recording ends at five seconds")
	# A real whiff punish drives the exercise result.
	print("Training checks: guided exercise")
	sim.set_character(0, "nao")
	sim.set_character(1, "daichi")
	t.mode = "repeat"
	t.move = 0
	t.exercise = "punish"
	t.distance = 335
	t.reset(sim)
	t.wait_ticks = 1
	step(sim, t)
	for i in range(19): step(sim, t)
	for i in range(16): step(sim, t, {"axis": 1})
	step(sim, t, {"action": "attack0"})
	for i in range(12): step(sim, t)
	check(t.successes == 1 and t.hits == 1 and sim.scores[0] == 1, "Exercise rewards an actual recovery punish")
	t.auto_reset = false
	for i in range(100): step(sim, t)
	check(sim.phase == "round_over" and sim.fighters[1].state == "dead" and t.hits == 1, "Disabled reset holds settled KO without duplicated statistics")
	t.auto_reset = true
	for i in range(90): step(sim, t)
	check(sim.phase == "fight" and sim.scores == [0, 0], "Automatic reset returns to training without points")
	var game = load("res://scenes/main.tscn").instantiate()
	print("Training checks: UI integration")
	game.play_intro_on_start = false
	game.settings.storage_path = "user://mvp-training-test-unused.cfg"
	root.add_child(game)
	game.set_physics_process(false)
	game.capture_frames = 1
	game.start_game("practice")
	game.training_menu.open()
	check(game.training_menu.visible and game.paused and not game.training_panel.visible, "Training settings freeze combat and hide HUD button")
	game.training_menu.exercise("punish")
	check(game.selected_characters == ["nao", "daichi"] and not game.paused and game.training.exercise == "punish", "Exercise selects correct fighters and resumes")
	var before: Array = game.sim.fighters.duplicate(true)
	for index in range(4):
		game.select_arena(index)
		check(game.sim.fighters == before and game.arena.title() == game.arena.NAMES[index], "Arenas share simulation and expose correct title")
	game.open_pause()
	check(game.pause_menu.training_button.visible, "Training can be opened using pause and controller")
	game.start_game()
	game.open_pause()
	check(not game.pause_menu.training_button.visible and not game.training_panel.visible, "Duels have no training controls")
	game.return_to_menu()
	game.menu.show_credits()
	check(game.menu.screen == "credits" and game.menu.credits.EMAIL == "jorgecintra2@gmail.com", "Credits are reachable with approved feedback address")
	game.menu.credits.show_page(1)
	check(game.menu.credits.pages[1].visible and not game.menu.credits.pages[0].visible, "Resource credits have their own readable page")
	game.menu.play_boot()
	check(game.menu.screen == "studio" and not game.menu_music.enabled and not game.battle_music.enabled, "Studio opens silently before prologue")
	game.menu.studio.finish()
	check(game.menu.screen == "intro", "Studio transitions into existing prologue")
	game.menu.show_home()
	check(not game.menu.prologue.active, "Leaving prologue stops narration")
	check(ProjectSettings.get_setting("application/config/icon") == "res://art/branding/maai-icon.png", "Application uses MAAI window branding")
	game.queue_free()
	await process_frame
	print("MVP training: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
