extends Node2D
## Observes resolved simulation ticks. Audio never changes combat timing or rules.
signal cue_emitted(cue: Dictionary)
const IDS = ["tsukiyo", "ren", "daichi", "nao", "sayo"]
const KINDS = ["step", "land", "weapon", "impact", "dodge", "collapse"]
const ATTACK_PITCH = [1.08, 0.95, 0.88, 1.12, 1.0, 0.86]
var banks: Dictionary = {}
var clips: Dictionary = {}
var players: Array = []
var previous: Array = []
var previous_phase: String = ""
var enabled: bool = false
var running: bool = false
var counters: Dictionary = {}
var last_foot: Array = [-100, -100]
var walk_frame: Array = [-1, -1]
var collapsed: Array = [false, false]
var voice_cursor: int = 0

func _ready() -> void:
	for id in IDS:
		banks[id] = {}
		var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/characters/%s/v01/atlas.json" % id))
		clips[id] = manifest.clips
		for kind in KINDS:
			banks[id][kind] = []
			for variant in range(3):
				banks[id][kind].append(load("res://art/audio/combat/%s/%s-%d.wav" % [id, kind, variant]))
	for index in range(24):
		var player := AudioStreamPlayer2D.new()
		player.bus = "SFX"
		player.attenuation = 0.0
		player.max_distance = 4000.0
		player.panning_strength = 0.65
		add_child(player)
		players.append(player)

func reset() -> void:
	for player in players:
		player.stop()
	previous.clear()
	counters.clear()
	last_foot = [-100, -100]
	walk_frame = [-1, -1]
	collapsed = [false, false]

func present(visible_fight: bool, advancing: bool) -> void:
	if enabled and not visible_fight:
		reset()
	enabled = visible_fight
	running = advancing
	for player in players:
		# These are short one-shots: cancel even sounds queued this physics tick.
		# AudioStreamPlayer2D's paused flag alone misses not-yet-started voices.
		if not advancing:
			player.stop()

func before_step(sim: RefCounted) -> void:
	previous = sim.fighters.duplicate(true)
	previous_phase = sim.phase
	if sim.phase == "countdown":
		walk_frame = [-1, -1]
		collapsed = [false, false]
		last_foot = [-100, -100]

func after_step(sim: RefCounted) -> void:
	if not enabled or not running or previous.size() != 2 or sim.phase == "countdown":
		return
	var contacts: Array = []
	for event in sim.events:
		if event.kind == "resolution":
			contacts.append_array(event.detail.contacts)
	for i in range(2):
		var f: Dictionary = sim.fighters[i]
		var old: Dictionary = previous[i]
		var was_air: bool = sim.airborne(old)
		var in_air: bool = sim.airborne(f)
		var moved: bool = absf(f.pos.x - old.pos.x) > 0.1
		if f.state != "dead":
			collapsed[i] = false
		# The contact record preserves an attack even if its owner also died this tick.
		var attack_age: int = f.age if f.state == "attack" else -1
		for contact in contacts:
			if contact.attacker == i:
				attack_age = contact.attack_age
		if previous_phase == "fight" and f.attack >= 0 and attack_age == sim.config.attacks[f.attack].startup:
			cue(sim, i, "weapon", 0.0, ATTACK_PITCH[f.attack])
		if previous_phase == "fight" and f.state == "dodge" and f.age == 0:
			cue(sim, i, "dodge")
		if was_air and not in_air:
			cue(sim, i, "collapse" if f.state == "dead" else "land")
			collapsed[i] = f.state == "dead"
			last_foot[i] = sim.tick
		elif f.state == "dead" and not in_air and f.death_ground_age >= 7 and not collapsed[i]:
			cue(sim, i, "collapse")
			collapsed[i] = true
		elif previous_phase == "fight" and not was_air and in_air:
			cue(sim, i, "step", -3.0, 1.08, "jump")
			last_foot[i] = sim.tick
		elif previous_phase == "fight" and not in_air and not was_air:
			if f.state == "sprint" and f.age == 0 and moved:
				cue(sim, i, "step", 1.0, 1.0, "sprint_launch")
				cue(sim, i, "dodge", -2.0, 1.1, "sprint_cloth")
				last_foot[i] = sim.tick
			elif old.state == "sprint" and f.state in ["idle", "attack"]:
				cue(sim, i, "step", 0.0, 0.96, "sprint_settle")
				last_foot[i] = sim.tick
			elif f.state == "idle" and moved:
				var name: String = "walk" if (f.pos.x - old.pos.x) * f.facing > 0 else "backstep"
				var clip: Dictionary = clips[f.character_id][name]
				var frame: int = int(sim.tick / 60.0 * float(clip.fps)) % clip.frames.size()
				var contact_frame: bool = frame == 0 or frame == int(clip.frames.size() / 2.0)
				if (walk_frame[i] == -1 or (frame != walk_frame[i] and contact_frame)) and sim.tick - last_foot[i] >= 8:
					cue(sim, i, "step", -1.5 if name == "backstep" else 0.0)
					last_foot[i] = sim.tick
				walk_frame[i] = frame
		if f.state != "idle" or not moved or in_air:
			walk_frame[i] = -1
	for contact in contacts:
		var attacker: int = contact.attacker
		cue(sim, attacker, "impact", 0.0, ATTACK_PITCH[sim.fighters[attacker].attack], "hit", sim.fighters[1 - attacker].pos.x)

func cue(sim: RefCounted, owner: int, kind: String, gain: float = 0.0, pitch: float = 1.0, reason: String = "", at_x: float = -1.0) -> void:
	var id: String = sim.fighters[owner].character_id
	var key: String = "%d/%s/%s" % [owner, id, kind]
	var count: int = counters.get(key, owner)
	var variant: int = count % 3
	counters[key] = count + 1
	pitch *= [1.0, 1.025, 0.98][variant]
	var x: float = sim.fighters[owner].pos.x if at_x < 0.0 else at_x
	var stream: AudioStream = banks[id][kind][variant]
	cue_emitted.emit({"tick": sim.tick, "owner": owner, "character": id, "kind": kind,
		"reason": reason if reason != "" else kind, "path": stream.resource_path, "gain_db": gain - 3.0, "pitch": pitch, "x": x})
	var player: AudioStreamPlayer2D = players[voice_cursor % players.size()]
	voice_cursor += 1
	player.stop()
	player.stream = stream
	player.volume_db = gain - 3.0
	player.pitch_scale = pitch
	player.position = Vector2(x, 450.0)
	player.stream_paused = false
	player.play()
