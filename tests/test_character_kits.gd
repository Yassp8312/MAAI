extends SceneTree
const Sim = preload("res://scripts/combat_sim.gd")
const CharacterAnimation = preload("res://scripts/tsukiyo_animation.gd")
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, text: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		if failures <= 12: push_error(text)

func fresh(id: String, player: int = 0):
	var sim = Sim.new()
	sim.set_character(player, id)
	sim.phase = "fight"
	return sim

func run() -> void:
	for id in Sim.CHARACTER_PROFILES:
		for player in range(2):
			for index in range(6):
				var sim = fresh(id, player)
				var f: Dictionary = sim.fighters[player]
				var technique = sim.attack_data(f, index)
				var animation = CharacterAnimation.new(id)
				check(technique.startup > 0 and technique.active > 0 and technique.finish > 0 and not technique.role.is_empty(), "Every move has usable timings and a purpose")
				check(technique != sim.config.attacks[index], "Per-character data cannot mutate the shared template")
				f.state = "attack"
				f.attack = index
				f.attack_dir = f.facing
				f.age = -1
				if index >= 3:
					f.pos.y -= 300
					f.vy = -18
				var origin: float = f.pos.x
				var total: int = technique.startup + technique.active + technique.finish
				for age in range(total):
					sim.step([{}, {}])
					check(sim.phase == "fight" and f.state == "attack", "%s/%d stays committed for its complete action" % [id, index])
					check(sim.active(f) == (age >= technique.startup and age < technique.startup + technique.active), "Hitbox follows this character's active interval")
					var pose = animation.pose(sim, player)
					var phase: int = 0 if age < technique.startup else (1 if age < technique.startup + technique.active else 2)
					check(animation.clips[technique.id].phases[phase].any(func(frame): return int(frame) == pose.frame), "Animation uses the same preparation/contact/recovery as collision: %s / %d / age %d" % [id, index, age])
					if index < 3 and age >= technique.startup:
						check(is_equal_approx(f.pos.x, origin + technique.advance * f.attack_dir), "Authored attack step finishes at contact and never drifts in recovery")
				check(is_equal_approx(f.pos.x, origin + technique.advance * f.attack_dir), "Complete step matches data on either side")
				sim.step([{}, {}])
				check(f.state == "idle", "Action releases on its own recovery boundary")
				check(sim.config.parry_window == 9 and sim.config.parry_ticks == 20 and sim.config.parry_success_ticks == 6 and sim.config.parried_ticks == 18, "Approved parry timing is unchanged for every character")
	# Same weapon decision must work when sides are swapped.
	for nao in range(2):
		var daichi: int = 1 - nao
		var sim = fresh("nao", nao)
		sim.set_character(daichi, "daichi")
		sim.fighters[0].pos.x = 600
		sim.fighters[1].pos.x = 935
		var inputs: Array = [{}, {}]
		inputs[daichi] = {"action": "attack0"}
		sim.step(inputs)
		for i in range(19): sim.step([{}, {}])
		check(sim.phase == "fight" and sim.fighters[daichi].state == "attack" and not sim.active(sim.fighters[daichi]), "A missed long thrust leaves Daichi recovering")
		inputs = [{}, {}]
		inputs[nao] = {"axis": sim.fighters[nao].facing}
		for i in range(16): sim.step(inputs)
		inputs[nao] = {"action": "attack0"}
		sim.step(inputs)
		for i in range(12): sim.step([{}, {}])
		check(sim.scores[nao] == 1, "Nao can close distance and punish Daichi's whiff before he recovers")
		sim = fresh("nao", nao)
		sim.set_character(daichi, "daichi")
		sim.fighters[0].pos.x = 600
		sim.fighters[1].pos.x = 885
		sim.step([{"action": "attack0"}, {"action": "attack0"}])
		for i in range(20): sim.step([{}, {}])
		check(sim.scores[daichi] == 1, "Blind entry can still be intercepted by the yari; no invulnerability is added")
		sim = fresh("nao", nao)
		sim.set_character(daichi, "daichi")
		sim.fighters[0].pos.x = 600
		sim.fighters[1].pos.x = 710
		inputs = [{}, {}]
		inputs[nao] = {"action": "attack2"}
		inputs[daichi] = {"action": "attack1"}
		sim.step(inputs)
		for i in range(12): sim.step([{}, {}])
		check(sim.scores[nao] == 1, "Nao's stationary quick punish beats a slower prepared swing at close range")
	# Lunge cannot cross a body, leave the arena or continue after a confirmed parry.
	for player in range(2):
		var sim = fresh("nao", player)
		var f: Dictionary = sim.fighters[player]
		sim.fighters[0].pos.x = 700
		sim.fighters[1].pos.x = 765
		var inputs: Array = [{}, {}]
		inputs[player].action = "attack0"
		sim.step(inputs)
		for i in range(9): sim.step([{}, {}])
		inputs = [{}, {}]
		inputs[1 - player].action = "parry"
		sim.step(inputs)
		check(f.state == "parried", "Existing parry deflects the entry move")
		var x: float = f.pos.x
		for i in range(18): sim.step([{}, {}])
		check(f.pos.x == x and sim.fighters[1].pos.x - sim.fighters[0].pos.x >= sim.config.body_size.x, "Rejected entry stops moving and never crosses opponent")
		for id in ["nao", "ren", "sayo"]:
			sim = fresh(id, player)
			f = sim.fighters[player]
			var index: int = 2 if id == "sayo" else 0
			f.state = "attack"
			f.attack = index
			f.attack_dir = f.facing
			f.pos.x = sim.config.arena_left if (player == 0) == (id == "sayo") else sim.config.arena_right
			# Keep the opponent out of this artificial boundary fixture.
			sim.fighters[1 - player].pos.x = f.pos.x + (500 if player == 0 else -500)
			for i in range(30):
				sim.step([{}, {}])
				check(f.pos.x >= sim.config.arena_left and f.pos.x <= sim.config.arena_right, "Attack travel stays inside arena")
	var game = load("res://scenes/main.tscn").instantiate()
	game.play_intro_on_start = false
	game.settings.storage_path = "user://kit-test-unused.cfg"
	root.add_child(game)
	game.set_physics_process(false)
	game.select_character(0, "nao")
	game.select_character(1, "daichi")
	game.start_game("practice")
	game.open_pause()
	check(not game.training_panel.visible, "Opening pause immediately hides the practice controls")
	game.pause_menu.techniques_button.pressed.emit()
	check(game.move_guide.visible and game.paused and not game.pause_menu.visible, "Move guide preserves a paused fight")
	check("Entrada" in game.move_guide.move_titles[0][0].text and "Punta de guardia" in game.move_guide.move_titles[1][0].text, "Guide follows selected characters")
	var tick_before: int = game.sim.tick
	await physics_frame
	check(game.sim.tick == tick_before, "Reading the guide cannot advance combat")
	game.move_guide.close()
	check(game.pause_menu.visible and game.paused and not game.move_guide.visible, "Closing the guide returns to pause")
	game.queue_free()
	await process_frame
	print("Character kits: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
