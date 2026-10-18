extends RefCounted
## Pure tick simulation: no input devices, sprites, audio or scene tree.
const CHARACTER_PROFILES = {
	"tsukiyo": preload("res://data/characters/tsukiyo.tres"),
	"ren": preload("res://data/characters/ren.tres"),
	"daichi": preload("res://data/characters/daichi.tres"),
	"nao": preload("res://data/characters/nao.tres"),
	"sayo": preload("res://data/characters/sayo.tres")
}
var character_ids: Array = ["tsukiyo", "tsukiyo"]
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
var attack_cache: Dictionary = {}

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
			"dash_dir": 1, "air_attacked": false, "buffer": "", "buffer_until": -1,
			"character_id": character_ids[i], "death_ground_age": 0,
			"parry_dir": 1 if i == 0 else -1, "parry_point": Vector2.ZERO,
			"parry_tick": -100})
	phase = "countdown"
	phase_tick = 0
	result = ""
	events.clear()

func airborne(f: Dictionary) -> bool:
	return f.pos.y < config.floor_y or f.vy < 0.0

func set_character(player: int, id: String) -> void:
	if player < 0 or player >= 2 or not CHARACTER_PROFILES.has(id):
		return
	character_ids[player] = id
	fighters[player].character_id = id

func combat_profile(f: Dictionary) -> Resource:
	return CHARACTER_PROFILES[f.character_id]

func attack_data(f: Dictionary, index: int = -1) -> Resource:
	var id: String = f.character_id
	if not attack_cache.has(id):
		var profile: Resource = combat_profile(f)
		var moves: Array = []
		for i in range(config.attacks.size()):
			var move: Resource = config.attacks[i].duplicate()
			move.startup = profile.startup_ticks[i]
			move.active = profile.active_ticks[i]
			move.finish = profile.recovery_ticks[i]
			move.advance = profile.advances[i]
			move.display_name = profile.move_names[i]
			move.role = profile.move_roles[i]
			moves.append(move)
		attack_cache[id] = moves
	return attack_cache[id][f.attack if index < 0 else index]

func walk_speed(f: Dictionary) -> float:
	return config.walk_speed * combat_profile(f).walk_scale

func sprint_distance(f: Dictionary) -> float:
	return config.sprint_distance * combat_profile(f).sprint_scale

func attack_progress(move: Resource, age: int) -> float:
	var t: float = clampf(float(age - move.advance_delay) / maxi(1, move.startup - move.advance_delay), 0, 1)
	return t * t * (3.0 - 2.0 * t)

func attack_step(f: Dictionary) -> float:
	var move: Resource = attack_data(f)
	return move.advance * (attack_progress(move, f.age) - attack_progress(move, f.age - 1)) * f.attack_dir

func crouching(f: Dictionary) -> bool:
	return f.state == "dodge" and f.age >= config.dodge_start and f.age < config.dodge_end

func body(f: Dictionary, previous: bool = false, standing: bool = false) -> Rect2:
	var p: Vector2 = f.previous if previous else f.pos
	var size: Vector2 = config.body_size
	if not standing and crouching(f):
		size.y = minf(size.y, combat_profile(f).dodge_height)
	return Rect2(p - Vector2(size.x * 0.5, size.y), size)

func invulnerable(f: Dictionary) -> bool:
	return f.state == "dodge" and f.age >= config.dodge_start and f.age < config.dodge_end

func parry_ready(f: Dictionary) -> bool:
	return f.state == "parry" and f.age < config.parry_window and not airborne(f)

func can_parry(defender: Dictionary, attacker: Dictionary) -> bool:
	return parry_ready(defender) and (attacker.pos.x - defender.pos.x) * defender.parry_dir > 0.0

func active(f: Dictionary) -> bool:
	if f.state != "attack":
		return false
	var move: Resource = attack_data(f)
	return f.age >= move.startup and f.age < move.startup + move.active

func blade(f: Dictionary, old: bool = false) -> Rect2:
	var move: Resource = attack_data(f)
	var age: int = f.age - 1 if old else f.age
	var t: float = clampf(float(age - move.startup) / maxf(1.0, move.active - 1.0), 0.0, 1.0)
	var offset: Vector2 = move.start.lerp(move.end, t)
	var size: Vector2 = move.size
	var base_reach: float = maxf(move.start.x, move.end.x) + move.size.x
	var reach_scale: float = combat_profile(f).reaches[f.attack] / base_reach
	offset.x *= reach_scale
	size.x *= reach_scale
	if f.attack_dir < 0:
		offset.x = -offset.x - size.x
	var p: Vector2 = f.previous if old else f.pos
	return Rect2(p + offset, size)

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
		# Resolution stops attacks and input, but never gravity or landing.
		var settled: bool = true
		for f in fighters:
			f.previous = f.pos
			if f.state != "dead":
				advance_action_clock(f)
			if airborne(f):
				f.pos.x = clampf(f.pos.x + f.vx, config.arena_left, config.arena_right)
				advance_gravity(f)
			elif f.state == "dead":
				f.death_ground_age += 1
			if airborne(f) or (f.state == "dead" and f.death_ground_age < 21):
				settled = false
		phase_tick += 1
		if phase_tick >= config.round_close_ticks and settled:
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
	var parries: Array = []
	for i in range(2):
		var attacker: Dictionary = fighters[i]
		var defender: Dictionary = fighters[1 - i]
		# Standing envelope is only a feedback probe for a successfully avoided blow.
		# Lethal collision always uses the actual current posture.
		if active(attacker) and (swept_hit(attacker, defender) or (invulnerable(defender) and swept_hit(attacker, defender, true))):
			if invulnerable(defender):
				events.append({"kind": "perfect_dodge" if defender.age < config.perfect_end else "dodge", "player": 1 - i})
			elif can_parry(defender, attacker):
				var hit: Rect2 = blade(attacker)
				var hurt: Rect2 = body(defender)
				var point := Vector2(hurt.get_center().x + defender.parry_dir * hurt.size.x * 0.5,
					clampf(hit.get_center().y, hurt.position.y, hurt.end.y))
				parries.append({"kind": "parry", "player": 1 - i, "attacker": i,
					"attack_age": attacker.age, "point": point})
			else:
				killed[1 - i] = true
				contacts.append({"attacker": i, "move": attack_data(attacker).id,
					"attack_age": attacker.age, "hitbox": blade(attacker), "hurtbox": body(defender),
					"defence_expired": defender.state == "parry" and defender.age >= config.parry_window})
	# Mutate only after both contacts have been evaluated; a deflected swing ends now.
	for parry in parries:
		var defender: Dictionary = fighters[parry.player]
		var attacker: Dictionary = fighters[parry.attacker]
		defender.state = "parry_success"
		attacker.state = "parried"
		for f in [defender, attacker]:
			f.age = 0
			f.buffer = ""
			f.buffer_until = -1
			f.parry_tick = tick
			f.parry_point = parry.point
		events.append(parry)
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
				fighters[i].age = 0
				fighters[i].death_ground_age = 0
				fighters[i].buffer = ""
				fighters[i].vy = maxf(0.0, fighters[i].vy)
		last_resolution = {"tick": tick, "contacts": contacts, "double_ko": killed[0] and killed[1]}
		events.append({"kind": "resolution", "detail": last_resolution})

func advance_action_clock(f: Dictionary) -> void:
	f.age += 1
	if f.state == "attack":
		var a: Resource = attack_data(f)
		if f.age >= a.startup + a.active + a.finish:
			f.state = "idle"
	elif f.state == "sprint" and f.age >= config.sprint_ticks:
		f.state = "idle"
	elif f.state == "dodge" and f.age >= config.dodge_ticks:
		f.state = "idle"
	elif f.state == "parry" and f.age >= config.parry_ticks:
		f.state = "idle"
	elif f.state == "parry_success" and f.age >= config.parry_success_ticks:
		f.state = "idle"
	elif f.state == "parried" and f.age >= config.parried_ticks:
		f.state = "idle"

func advance(f: Dictionary, input: Dictionary) -> void:
	advance_action_clock(f)
	var command: String = input.get("action", "")
	# Precision defence is not buffered; it can plant a sprint, but never cancel an attack/dodge.
	if command == "parry":
		if f.state in ["idle", "sprint"] and not airborne(f):
			f.buffer = ""
			f.buffer_until = -1
			start_action(f, command, 0)
	elif command != "":
		f.buffer = command
		f.buffer_until = tick + config.buffer_ticks - 1
	if tick > f.buffer_until:
		f.buffer = ""
	var axis: int = clampi(int(input.get("axis", 0)), -1, 1)
	# Attacks can interrupt a dash immediately; other commands keep their buffer.
	var sprint_attack: bool = f.state == "sprint" and f.buffer.begins_with("attack")
	if (f.state == "idle" or sprint_attack) and f.buffer != "":
		if start_action(f, f.buffer, axis):
			f.buffer = ""
	if f.state == "sprint":
		f.pos.x += f.dash_dir * sprint_distance(f) / config.sprint_ticks
	elif airborne(f):
		f.pos.x += f.vx
	elif f.state == "attack":
		f.pos.x += attack_step(f)
	elif f.state == "idle":
		f.pos.x += axis * walk_speed(f)
	advance_gravity(f)
	f.pos.x = clampf(f.pos.x, config.arena_left, config.arena_right)

func advance_gravity(f: Dictionary) -> void:
	if not airborne(f):
		return
	f.pos.y += f.vy
	f.vy += config.gravity
	if f.pos.y >= config.floor_y:
		f.pos.y = config.floor_y
		f.vy = 0.0
		f.air_attacked = false

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
		f.vx = axis * walk_speed(f)
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
	if command == "parry":
		f.state = "parry"
		f.age = 0
		f.parry_dir = f.facing
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

func swept_hit(a: Dictionary, d: Dictionary, standing: bool = false) -> bool:
	# Continuous moving AABB vs AABB, relative to defender movement.
	# On the first active tick only the final pose is live (startup cannot kill).
	var current: Rect2 = blade(a)
	var hurt: Rect2 = body(d, false, standing)
	var move: Resource = attack_data(a)
	if a.age == move.startup:
		return current.intersects(hurt)
	var previous: Rect2 = blade(a, true)
	var from: Vector2 = previous.get_center() - d.previous
	var to: Vector2 = current.get_center() - d.pos
	# The current pose applies for this whole tick. Never sweep the old standing
	# height into a new crouch, which would produce a phantom head hit.
	var target := Rect2(hurt.position - d.pos - current.size * 0.5, hurt.size + current.size)
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
