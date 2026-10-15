extends SceneTree
const Simulation = preload("res://scripts/combat_sim.gd")
var failures: int = 0
var checks: int = 0

func _initialize() -> void:
	test_motion()
	test_sprint_buffer()
	test_attacks()
	test_dodge()
	test_rounds()
	test_repeatability()
	print("MAAI: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)

func fresh():
	var sim = Simulation.new()
	sim.phase = "fight"
	return sim

func run_ticks(sim, count: int, a: Dictionary = {}, b: Dictionary = {}) -> void:
	for _i in range(count):
		sim.step([a, b])

func close_range(sim) -> void:
	sim.fighters[0].pos.x = 600.0
	sim.fighters[1].pos.x = 800.0

func test_motion() -> void:
	var sim = fresh()
	run_ticks(sim, 10, {"axis": -1}, {"axis": 1})
	check(sim.fighters[0].pos.x == 470 and sim.fighters[1].pos.x == 1130, "Both players walk symmetrically")
	check(sim.fighters[0].facing == 1 and sim.fighters[1].facing == -1, "Retreat keeps opponent-facing orientation")
	run_ticks(sim, 500, {"axis": -1}, {"axis": 1})
	check(sim.fighters[0].pos.x == sim.config.arena_left and sim.fighters[1].pos.x == sim.config.arena_right, "Arena limits remain solid")
	sim = fresh()
	sim.step([{"axis": 1, "action": "jump"}, {}])
	var after_jump: float = sim.fighters[0].pos.x
	run_ticks(sim, 10, {"axis": -1})
	check(is_equal_approx(sim.fighters[0].pos.x, after_jump + 50), "Opposite input does not alter airborne trajectory")
	while sim.airborne(sim.fighters[0]):
		sim.step([{}, {}])
	sim.step([{"action": "attack0"}, {}])
	check(sim.fighters[0].state == "attack" and sim.fighters[0].age == 0, "Landing adds no artificial recovery")
	sim = fresh()
	sim.fighters[0].pos.x = 900.0
	sim.fighters[1].pos.x = 1000.0
	sim.step([{"axis": 1, "action": "sprint"}, {}])
	run_ticks(sim, 30)
	check(is_equal_approx(sim.fighters[0].pos.x, 936) and sim.fighters[1].pos.x == 1000, "Sprint stops at opponent without pushing or crossing")

func test_sprint_buffer() -> void:
	var sim = fresh()
	var origin: float = sim.fighters[0].pos.x
	sim.step([{"action": "sprint", "axis": -1}, {}])
	run_ticks(sim, 17)
	check(is_equal_approx(origin - sim.fighters[0].pos.x, sim.config.sprint_distance), "Sprint travels exact configured distance")
	sim.step([{}, {}])
	check(sim.fighters[0].state == "idle", "Sprint releases control on its first legal tick")
	sim = fresh()
	sim.step([{"action": "sprint"}, {}])
	sim.step([{"action": "attack0"}, {}])
	check(sim.fighters[0].state == "sprint", "Attack cannot cancel sprint")
	run_ticks(sim, 18)
	check(sim.fighters[0].state == "idle", "Early buffered input expires")
	sim = fresh()
	sim.step([{"action": "sprint"}, {}])
	run_ticks(sim, 14)
	sim.step([{"action": "attack0"}, {}])
	run_ticks(sim, 3)
	check(sim.fighters[0].state == "attack" and sim.fighters[0].age == 0, "Late attack buffer fires exactly at sprint end")
	sim = fresh()
	sim.step([{"action": "attack0"}, {}])
	sim.step([{"action": "dodge"}, {}])
	check(sim.fighters[0].state == "attack", "Dodge cannot cancel an attack")

func test_attacks() -> void:
	var sim = fresh()
	close_range(sim)
	sim.step([{"action": "attack0"}, {}])
	run_ticks(sim, 8)
	check(sim.phase == "fight", "Startup cannot kill")
	sim.step([{}, {}])
	check(sim.phase == "round_over" and sim.scores == [1, 0], "First active contact kills once")
	check(sim.last_resolution.contacts[0].attack_age == 9, "Death records the actual active tick")
	sim = fresh()
	close_range(sim)
	sim.step([{"action": "attack0"}, {"action": "attack0"}])
	run_ticks(sim, 9)
	check(sim.last_resolution.double_ko and sim.scores == [0, 0], "Simultaneous lethal contacts are double KO without points")
	check(sim.fighters[0].state == "dead" and sim.fighters[1].state == "dead", "Both combatants die in same tick")
	sim = fresh()
	close_range(sim)
	sim.step([{}, {"action": "attack0"}])
	run_ticks(sim, 9)
	check(sim.scores == [0, 1], "Mirrored attacker has no processing-order disadvantage")
	sim = fresh()
	sim.step([{"action": "attack0"}, {}])
	run_ticks(sim, 40)
	check(sim.phase == "fight" and sim.fighters[0].state == "idle", "Out-of-range attack misses and finishes naturally")
	for move in range(3):
		sim = fresh()
		sim.step([{"action": "attack%d" % move}, {}])
		check(sim.fighters[0].attack == move, "Ground move %d selected" % move)
		sim = fresh()
		sim.step([{"action": "jump"}, {}])
		sim.step([{"action": "attack%d" % move}, {}])
		check(sim.fighters[0].attack == move + 3, "Air move %d selected" % move)
	sim = fresh()
	check(sim.segment_rect(Vector2(-100, 0), Vector2(100, 0), Rect2(-2, -2, 4, 4)), "Continuous collision catches crossing between endpoints")
	check(not sim.segment_rect(Vector2(-100, 4), Vector2(100, 4), Rect2(-2, -2, 4, 4)), "Swept near miss stays a miss")
	# An active weapon crosses a narrow body in one tick, with neither endpoint inside.
	var a: Dictionary = sim.fighters[0]
	var d: Dictionary = sim.fighters[1]
	a.state = "attack"
	a.attack = 0
	a.attack_dir = 1
	a.age = 10
	a.previous = Vector2(0, sim.config.floor_y)
	a.pos = Vector2(1000, sim.config.floor_y)
	d.pos = Vector2(500, sim.config.floor_y)
	d.previous = d.pos
	check(sim.swept_hit(a, d), "Weapon continuous collision is wired into simulation")

func test_dodge() -> void:
	var sim = fresh()
	close_range(sim)
	sim.step([{"action": "attack0"}, {}])
	run_ticks(sim, 5)
	sim.step([{}, {"action": "dodge"}])
	run_ticks(sim, 3)
	check(sim.phase == "fight" and sim.events.size() > 0 and sim.events[0].kind == "perfect_dodge", "Precise defensive window avoids the real contact")
	run_ticks(sim, 4)
	check(sim.phase == "fight", "Dodge covers the entire incoming active interval in this scenario")
	sim = fresh()
	close_range(sim)
	sim.step([{"action": "attack0"}, {}])
	run_ticks(sim, 7)
	sim.step([{}, {"action": "dodge"}])
	sim.step([{}, {}])
	check(sim.phase == "round_over", "Too-late dodge remains vulnerable")
	sim = fresh()
	close_range(sim)
	sim.step([{}, {"action": "dodge"}])
	run_ticks(sim, 6)
	sim.step([{"action": "attack0"}, {}])
	run_ticks(sim, 9)
	check(sim.phase == "round_over", "Dodge finalization is vulnerable")

func test_rounds() -> void:
	var sim = fresh()
	close_range(sim)
	sim.step([{"action": "attack0"}, {"action": "attack0"}])
	run_ticks(sim, 9 + sim.config.round_close_ticks)
	check(sim.phase == "countdown" and sim.scores == [0, 0], "Double KO repeats round after closing interval")
	for best in [3, 5]:
		sim = fresh()
		sim.reset_match(best)
		for _win in range(sim.target_wins):
			sim.phase = "fight"
			close_range(sim)
			sim.step([{"action": "attack0"}, {}])
			run_ticks(sim, 9 + sim.config.round_close_ticks)
		check(sim.phase == "match_over", "Best of %d ends at correct win count" % best)
		sim.reset_match(best)
		check(sim.scores == [0, 0] and sim.phase == "countdown", "Rematch resets best of %d" % best)

func test_repeatability() -> void:
	var a = fresh()
	var b = fresh()
	for t in range(240):
		var input_a: Dictionary = {"axis": 1 if t % 60 < 30 else -1}
		if t % 47 == 0:
			input_a.action = "jump"
		var input_b: Dictionary = {"axis": -1}
		if t % 23 == 0:
			input_b.action = "attack0"
		a.step([input_a, input_b])
		b.step([input_a, input_b])
	check(a.fighters == b.fighters and a.scores == b.scores, "Identical input streams reproduce same local simulation")
