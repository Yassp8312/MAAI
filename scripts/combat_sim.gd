extends RefCounted
## Pure tick simulation: no input devices, sprites, audio or scene tree.
var config: Resource
var fighters: Array = []
var tick: int = 0
var phase: String = "countdown"
var phase_tick: int = 0
var scores: Array = [0, 0]
var target_wins: int = 2
var result: String = ""
var events: Array = []
var last_resolution: Dictionary = {}

func _init(settings: Resource = null):
	config = settings if settings != null else load("res://data/combat.tres")
	reset_match(3)

func reset_match(best_of: int = 3) -> void:
	target_wins = 3 if best_of == 5 else 2
	scores = [0, 0]
	tick = 0
	last_resolution = {}
	reset_round()

func reset_round() -> void:
	fighters.clear()
	for i in range(2):
		fighters.append({"pos": Vector2(520 + 560 * i, config.floor_y),
			"previous": Vector2(520 + 560 * i, config.floor_y),
			"vx": 0.0, "vy": 0.0, "facing": 1 if i == 0 else -1,
			"state": "idle", "age": 0, "attack": -1, "attack_dir": 1,
			"dash_dir": 1, "air_attacked": false, "buffer": "", "buffer_until": -1})
	phase = "countdown"
	phase_tick = 0
	result = ""
	events.clear()

func airborne(f: Dictionary) -> bool:
	return f.pos.y < config.floor_y or f.vy < 0.0

func body(f: Dictionary, previous: bool = false) -> Rect2:
	var p: Vector2 = f.previous if previous else f.pos
	return Rect2(p - Vector2(config.body_size.x * 0.5, config.body_size.y), config.body_size)

func invulnerable(f: Dictionary) -> bool:
	return f.state == "dodge" and f.age >= config.dodge_start and f.age < config.dodge_end

func active(f: Dictionary) -> bool:
	if f.state != "attack":
		return false
	var move: Resource = config.attacks[f.attack]
	return f.age >= move.startup and f.age < move.startup + move.active

func blade(f: Dictionary, old: bool = false) -> Rect2:
	var move: Resource = config.attacks[f.attack]
	var age: int = f.age - 1 if old else f.age
	var t: float = clampf(float(age - move.startup) / maxf(1.0, move.active - 1.0), 0.0, 1.0)
	var offset: Vector2 = move.start.lerp(move.end, t)
	if f.attack_dir < 0:
		offset.x = -offset.x - move.size.x
	var p: Vector2 = f.previous if old else f.pos
	return Rect2(p + offset, move.size)

func step(inputs: Array) -> void:
	events.clear()
	tick += 1
	if phase == "match_over":
		return
	if phase == "countdown":
		phase_tick += 1
		if phase_tick >= config.countdown_ticks:
			phase = "fight"
			phase_tick = 0
		return
	if phase == "round_over":
		phase_tick += 1
		if phase_tick >= config.round_close_ticks:
			if scores.max() >= target_wins:
				phase = "match_over"
			else:
				reset_round()
		return
	for i in range(2):
		var f: Dictionary = fighters[i]
		f.previous = f.pos
		f.facing = 1 if fighters[1 - i].pos.x >= f.pos.x else -1
		advance(f, inputs[i])
	resolve_pushboxes()
	# Collect both results BEFORE mutating either fighter. Equal ticks trade.
	var killed: Array = [false, false]
	var contacts: Array = []
	for i in range(2):
		var attacker: Dictionary = fighters[i]
		var defender: Dictionary = fighters[1 - i]
		if active(attacker) and swept_hit(attacker, defender):
			if invulnerable(defender):
				events.append({"kind": "perfect_dodge" if defender.age < config.perfect_end else "dodge", "player": 1 - i})
			else:
				killed[1 - i] = true
				contacts.append({"attacker": i, "move": config.attacks[attacker.attack].id,
					"attack_age": attacker.age, "hitbox": blade(attacker), "hurtbox": body(defender)})
	if killed[0] or killed[1]:
		phase = "round_over"
		phase_tick = 0
		if killed[0] and killed[1]:
			result = "DOBLE KO · Se repite la ronda"
		else:
			var winner: int = 1 if killed[0] else 0
			scores[winner] += 1
			result = "JUGADOR %d · Golpe decisivo" % (winner + 1)
		for i in range(2):
			if killed[i]:
				fighters[i].state = "dead"
		last_resolution = {"tick": tick, "contacts": contacts, "double_ko": killed[0] and killed[1]}
		events.append({"kind": "resolution", "detail": last_resolution})

func advance(f: Dictionary, input: Dictionary) -> void:
	f.age += 1
	if f.state == "attack":
		var a: Resource = config.attacks[f.attack]
		if f.age >= a.startup + a.active + a.finish:
			f.state = "idle"
	elif f.state == "sprint" and f.age >= config.sprint_ticks:
		f.state = "idle"
	elif f.state == "dodge" and f.age >= config.dodge_ticks:
		f.state = "idle"
	var command: String = input.get("action", "")
	if command != "":
		f.buffer = command
		f.buffer_until = tick + config.buffer_ticks - 1
	if tick > f.buffer_until:
		f.buffer = ""
	var axis: int = clampi(int(input.get("axis", 0)), -1, 1)
	if f.state == "idle" and f.buffer != "":
		if start_action(f, f.buffer, axis):
			f.buffer = ""
	if f.state == "sprint":
		f.pos.x += f.dash_dir * config.sprint_distance / config.sprint_ticks
	elif airborne(f):
		f.pos.x += f.vx
	elif f.state == "idle":
		f.pos.x += axis * config.walk_speed
	if airborne(f):
		f.pos.y += f.vy
		f.vy += config.gravity
		if f.pos.y >= config.floor_y:
			f.pos.y = config.floor_y
			f.vy = 0.0
			f.air_attacked = false
	f.pos.x = clampf(f.pos.x, config.arena_left, config.arena_right)

func start_action(f: Dictionary, command: String, axis: int) -> bool:
	if command.begins_with("attack"):
		if airborne(f) and f.air_attacked:
			return false
		f.attack = int(command.right(1)) + (3 if airborne(f) else 0)
		f.attack_dir = f.facing
		f.state = "attack"
		f.age = 0
		if airborne(f):
			f.air_attacked = true
		return true
	if airborne(f):
		return false
	if command == "jump":
		f.vy = config.jump_speed
		f.vx = axis * config.walk_speed
		f.air_attacked = false
		return true
	if command == "sprint":
		f.dash_dir = axis if axis != 0 else f.facing
		f.state = "sprint"
		f.age = 0
		return true
	if command == "dodge":
		f.state = "dodge"
		f.age = 0
		return true
	return false

func resolve_pushboxes() -> void:
	# MVP hypothesis: preserve sides even in the air, no crossing opponent.
	var left: Dictionary = fighters[0]
	var right: Dictionary = fighters[1]
	var overlap: float = config.body_size.x - (right.pos.x - left.pos.x)
	if overlap > 0.0:
		var approach_left: float = maxf(0.0, left.pos.x - left.previous.x)
		var approach_right: float = maxf(0.0, right.previous.x - right.pos.x)
		var total: float = approach_left + approach_right
		var share: float = approach_left / total if total > 0.00001 else 0.5
		left.pos.x -= overlap * share
		right.pos.x += overlap * (1.0 - share)

func swept_hit(a: Dictionary, d: Dictionary) -> bool:
	# Continuous moving AABB vs AABB, relative to defender movement.
	# On the first active tick only the final pose is live (startup cannot kill).
	var current: Rect2 = blade(a)
	var move: Resource = config.attacks[a.attack]
	if a.age == move.startup:
		return current.intersects(body(d))
	var previous: Rect2 = blade(a, true)
	var from: Vector2 = previous.get_center() - d.previous
	var to: Vector2 = current.get_center() - d.pos
	var target := Rect2(Vector2(-config.body_size.x * 0.5, -config.body_size.y) - current.size * 0.5, config.body_size + current.size)
	return segment_rect(from, to, target)

func segment_rect(from: Vector2, to: Vector2, rect: Rect2) -> bool:
	var delta: Vector2 = to - from
	var enter: float = 0.0
	var leave: float = 1.0
	for axis in range(2):
		if absf(delta[axis]) < 0.00001:
			if from[axis] < rect.position[axis] or from[axis] > rect.end[axis]:
				return false
		else:
			var a: float = (rect.position[axis] - from[axis]) / delta[axis]
			var b: float = (rect.end[axis] - from[axis]) / delta[axis]
			enter = maxf(enter, minf(a, b))
			leave = minf(leave, maxf(a, b))
			if enter > leave:
				return false
	return true
