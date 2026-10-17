extends SceneTree
const Simulation = preload("res://scripts/combat_sim.gd")
const CharacterAnimation = preload("res://scripts/tsukiyo_animation.gd")
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	test_reach()
	test_posture()
	test_air_death()
	print("Combat geometry: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(description)

func fresh(id: String = "tsukiyo", player: int = 0):
	var sim = Simulation.new()
	sim.set_character(player, id)
	sim.phase = "fight"
	return sim

func test_reach() -> void:
	for id in Simulation.CHARACTER_PROFILES:
		for player in range(2):
			var sim = fresh(id, player)
			var a: Dictionary = sim.fighters[player]
			a.previous = a.pos
			a.state = "attack"
			a.attack_dir = a.facing
			for move in range(6):
				a.attack = move
				var data: Resource = sim.config.attacks[move]
				var maximum: float = 0
				for age in range(data.startup, data.startup + data.active):
					a.age = age
					var blade: Rect2 = sim.blade(a)
					var reach: float = blade.end.x - a.pos.x if player == 0 else a.pos.x - blade.position.x
					maximum = maxf(maximum, reach)
					check(blade.size.x > 0 and blade.size.y > 0, "Valid hitbox on each active tick")
				check(is_equal_approx(maximum, sim.combat_profile(a).reaches[move]), "Ground/air reach follows selected profile on both sides")
			for gap in [130.0, 215.0, 315.0]:
				sim = fresh(id, player)
				sim.fighters[0].pos.x = 600
				sim.fighters[1].pos.x = 600 + gap
				var input: Array = [{}, {}]
				input[player] = {"action": "attack0"}
				sim.step(input)
				for tick in range(30):
					sim.step([{}, {}])
				var expected: bool = gap == 130 or (gap == 215 and id in ["tsukiyo", "ren", "daichi"]) or (gap == 315 and id == "daichi")
				check((sim.scores[player] == 1) == expected, "%s at distance %.0f has the expected real hit/miss" % [id, gap])
			sim.reset_round()
			check(sim.fighters[player].character_id == id, "New round retains selected weapon")
	# Different fighters cannot overwrite a shared attack resource.
	var sim = fresh("nao")
	sim.set_character(1, "daichi")
	sim.reset_match()
	check(sim.combat_profile(sim.fighters[0]).reaches[0] == 140 and sim.combat_profile(sim.fighters[1]).reaches[0] == 300, "Mixed profiles survive rematch independently")
	check(sim.config.attacks[0].size.x == 190, "Base attack resource remains unchanged")

func test_posture() -> void:
	for id in Simulation.CHARACTER_PROFILES:
		for player in range(2):
			var sim = fresh(id, player)
			var f: Dictionary = sim.fighters[player]
			var standing: Rect2 = sim.body(f)
			var animation = CharacterAnimation.new(id)
			f.state = "dodge"
			for age in range(sim.config.dodge_ticks):
				f.age = age
				var low: bool = age >= sim.config.dodge_start and age < sim.config.dodge_end
				check((sim.body(f).size.y < standing.size.y) == low, "Hurtbox follows exact crouch interval")
				check((animation.pose(sim, player).frame == 1) == low, "Drawing and collision posture agree")
				check(sim.body(f).end.y == standing.end.y and sim.body(f).size.x == standing.size.x, "Crouch keeps ground anchor and lateral separation")
			var a: Dictionary = sim.fighters[1 - player]
			a.pos = f.pos - Vector2(f.facing * -100, 0)
			a.previous = a.pos
			a.attack_dir = -f.facing
			a.state = "attack"
			a.attack = 0
			f.age = sim.config.dodge_start
			f.previous = f.pos
			# Position a high thrust above this character's crouched head.
			a.pos.y = f.pos.y - sim.combat_profile(f).dodge_height + 125
			a.previous = a.pos
			for age in [9, 10]:
				a.age = age
				check(sim.swept_hit(a, f, true), "High thrust would hit standing posture")
				check(not sim.swept_hit(a, f), "High thrust misses crouch, including continuous collision")
			a.attack = 2
			a.age = 16
			a.pos.y = f.pos.y
			a.previous = a.pos
			check(sim.swept_hit(a, f), "Low cut still intersects crouching body geometrically")
			check(sim.invulnerable(f), "Brief existing invulnerability still protects low contacts")
			f.age = sim.config.dodge_end
			check(not sim.invulnerable(f) and sim.body(f) == standing, "Recovery restores vulnerability and full height")

func test_air_death() -> void:
	for id in Simulation.CHARACTER_PROFILES:
		for victim in range(2):
			for velocity in [-6.0, 0.0, 6.0]:
				var sim = fresh(id, victim)
				sim.fighters[0].pos.x = 600
				sim.fighters[1].pos.x = 780
				var f: Dictionary = sim.fighters[victim]
				f.pos.y -= 100
				f.vy = velocity
				f.vx = 3 * f.facing
				var attacker: Dictionary = sim.fighters[1 - victim]
				attacker.state = "attack"
				attacker.attack = 0
				attacker.attack_dir = attacker.facing
				attacker.age = 8
				sim.step([{}, {}])
				check(sim.phase == "round_over" and f.state == "dead", "Real hit kills airborne fighter ascending, apex or descending")
				var score: Array = sim.scores.duplicate()
				var animation = CharacterAnimation.new(id)
				var landed: bool = false
				for tick in range(100):
					var old_y: float = f.pos.y
					sim.step([{"action": "jump", "axis": -1}, {"action": "attack0", "axis": 1}])
					check(sim.scores == score, "Post-KO motion cannot award another point")
					check(f.state == "dead" and f.pos.y >= old_y, "Dead fighter falls and cannot respond to commands")
					check(f.pos.y <= sim.config.floor_y, "Death never sinks below floor")
					if sim.airborne(f):
						check(animation.pose(sim, victim).frame == 0 and f.death_ground_age == 0, "No lying pose before landing")
					else:
						landed = true
						break
				check(landed and f.vy == 0, "Dead fighter reaches ground with zero vertical velocity")
				for tick in range(14):
					sim.step([{}, {}])
				check(animation.pose(sim, victim).frame == 2, "Fallen drawing advances only after touchdown")
	# A short round-close setting must still wait for BOTH airborne fighters.
	var settings: Resource = load("res://data/combat.tres").duplicate(true)
	settings.round_close_ticks = 1
	var sim = Simulation.new(settings)
	sim.phase = "round_over"
	sim.fighters[0].state = "dead"
	sim.fighters[0].pos.y -= 250
	sim.fighters[1].pos.y -= 300
	sim.fighters[1].vy = -6
	for tick in range(200):
		if sim.phase != "round_over":
			break
		var falling: bool = sim.airborne(sim.fighters[0]) or sim.airborne(sim.fighters[1])
		sim.step([{}, {}])
		if falling and (sim.airborne(sim.fighters[0]) or sim.airborne(sim.fighters[1])):
			check(sim.phase == "round_over", "Round cannot restart with either fighter in midair")
	check(sim.phase == "countdown", "Round eventually restarts after both settle")
	sim = fresh()
	sim.phase = "round_over"
	sim.fighters[0].state = "dead"
	var winner: Dictionary = sim.fighters[1]
	winner.state = "attack"
	winner.attack = 3
	winner.age = 8
	winner.pos.y -= 180
	winner.buffer = "jump"
	winner.buffer_until = 1000
	for tick in range(80):
		sim.step([{}, {"action": "attack0", "axis": 1}])
	check(winner.state == "idle" and winner.pos.y == sim.config.floor_y, "Airborne winner completes attack and lands without accepting new or buffered actions")
	# Simultaneous airborne contacts still trade, then both bodies land.
	sim = fresh()
	for player in range(2):
		var f: Dictionary = sim.fighters[player]
		f.pos = Vector2(600 + player * 150, sim.config.floor_y - 180)
		f.state = "attack"
		f.attack = 3
		f.attack_dir = f.facing
		f.age = 7
		f.vy = -2
	sim.step([{}, {}])
	check(sim.last_resolution.get("double_ko", false) and sim.scores == [0, 0], "Airborne simultaneous hits still produce a scoreless double KO")
	for tick in range(80):
		sim.step([{}, {}])
	for f in sim.fighters:
		check(f.state == "dead" and f.pos.y == sim.config.floor_y, "Both double-KO victims land")
