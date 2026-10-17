extends SceneTree
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
	var game = load("res://scenes/main.tscn").instantiate()
	game.play_intro_on_start = false
	game.settings.storage_path = "user://courtyard-test-unused.cfg"
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.capture_frames = 1
	check(not game.arena.visible and not game.arena.wind.requested, "No arena or wind on presentation")
	game.start_game()
	check(game.arena.visible and not game.arena.laboratory and game.arena.wind.requested, "Duels start in the courtyard with ambience")
	check(game.arena.wind.bus == "Ambience", "Wind uses the existing ambience volume bus")
	var before: Array = game.sim.fighters.duplicate(true)
	game.arena._process(1)
	check(game.sim.fighters == before, "Environment animation cannot move combatants")
	var f: Dictionary = game.sim.fighters[0]
	var standing: Dictionary = game.arena.shadow_for(f)
	f.pos.y -= 180
	var jumping: Dictionary = game.arena.shadow_for(f)
	check(jumping.position.y == game.sim.config.floor_y + 2, "Airborne shadow stays on simulation floor")
	check(jumping.width < standing.width and jumping.alpha < standing.alpha, "Shadow becomes smaller and lighter with jump height")
	f.state = "dead"
	check(game.arena.shadow_for(f).position == jumping.position, "Airborne KO shadow stays grounded too")
	game.start_game()
	game.open_pause()
	game.refresh()
	var clock: float = game.arena.elapsed
	game.arena._process(1)
	check(game.arena.elapsed == clock and not game.arena.wind.requested, "Pause freezes scenery and fades ambience")
	before = game.sim.fighters.duplicate(true)
	var phase: String = game.sim.phase
	game.toggle_arena()
	check(game.arena.laboratory and game.sim.fighters == before and game.sim.phase == phase, "Changing scenery preserves the duel and phase")
	game.resume_game()
	game.refresh()
	check(not game.arena.wind.requested, "Laboratory remains silent")
	game.toggle_arena()
	check(game.arena.wind.requested, "Returning to courtyard restores ambience")
	game.open_options()
	game.refresh()
	check(not game.arena.wind.requested, "Options pauses ambience")
	game.options.cancel()
	game.return_to_menu()
	check(not game.arena.visible and not game.arena.wind.requested, "Returning to menu hides arena and stops wind")
	game.queue_free()
	for i in range(3):
		await process_frame
	print("Courtyard: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
