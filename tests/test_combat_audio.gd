extends SceneTree
const Simulation = preload("res://scripts/combat_sim.gd")
const CombatAudio = preload("res://scripts/combat_audio.gd")
const Settings = preload("res://scripts/game_settings.gd")
var audio
var sim
var cues: Array = []
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func fresh(id: String = "tsukiyo", gap: float = 560.0) -> void:
	sim = Simulation.new()
	sim.set_character(0, id)
	sim.fighters[1].pos.x = sim.fighters[0].pos.x + gap
	sim.phase = "fight"
	audio.reset()
	audio.present(true, true)
	cues.clear()

func step(a: Dictionary = {}, b: Dictionary = {}) -> void:
	audio.before_step(sim)
	sim.step([a, b])
	audio.after_step(sim)

func frames(count: int) -> void:
	for n in range(count):
		step()

func count_reason(reason: String, owner: int = -1) -> int:
	return cues.filter(func(c): return c.reason == reason and (owner < 0 or c.owner == owner)).size()

func run() -> void:
	Settings.apply_audio(Settings.defaults().audio)
	audio = CombatAudio.new()
	root.add_child(audio)
	audio.cue_emitted.connect(func(c): cues.append(c))
	for id in CombatAudio.IDS:
		for kind in CombatAudio.KINDS:
			for sound in audio.banks[id][kind]:
				check(sound != null and sound.get_length() > 0.02, "Imported playable asset: %s/%s" % [id, kind])
	if failures:
		quit(1)
		return
	for id in CombatAudio.IDS:
		fresh(id)
		frames(60)
		check(cues.is_empty(), "%s idle is silent" % id)
		for n in range(60):
			step({"axis": 1})
		check(count_reason("step") >= 3 and count_reason("step") <= 7, "%s walk follows cel contacts at its movement cadence" % id)
		var paths: Dictionary = {}
		for c in cues:
			check(c.character == id and c.path.contains("/%s/" % id), "%s uses its own bank" % id)
			paths[c.path] = true
		check(paths.size() == 3, "%s rotates three footsteps" % id)
		cues.clear()
		frames(40)
		check(cues.is_empty(), "No trailing footsteps after stopping")
		fresh(id)
		sim.fighters[0].pos.x = sim.config.arena_left
		for n in range(60):
			step({"axis": -1})
		check(cues.is_empty(), "No footsteps against the wall")
		for attack in range(6):
			fresh(id)
			if attack >= 3:
				step({"action": "jump"})
				frames(5)
			step({"action": "attack%d" % (attack % 3)})
			var started: int = sim.tick
			frames(50)
			check(count_reason("weapon") == 1 and count_reason("hit") == 0, "%s whiff %d: one swing, no hit" % [id, attack])
			var swings: Array = cues.filter(func(c): return c.kind == "weapon")
			check(swings.size() == 1 and swings[0].tick == started + sim.attack_data(sim.fighters[0], attack).startup, "Swing starts on character-specific active tick")
		fresh(id, 130)
		step({"action": "attack0"})
		frames(40)
		check(count_reason("hit") == 1 and count_reason("collapse") == 1, "%s real hit and grounded collapse once" % id)
		check(cues.filter(func(c): return c.reason == "hit" and c.character == id).size() == 1, "Impact belongs to attacking weapon")
		fresh(id)
		step({"action": "jump", "axis": 1})
		frames(70)
		check(count_reason("jump") == 1 and count_reason("land") == 1 and count_reason("step") == 0, "Jump: launch and landing, no steps in air")
		fresh(id)
		step({"action": "sprint"})
		frames(25)
		check(count_reason("sprint_launch") == 1 and count_reason("sprint_settle") == 1, "Sprint uses launch/settle, not a running loop")
		fresh(id)
		step({"action": "sprint"})
		frames(3)
		step({"action": "attack0"})
		var attack_tick: int = sim.tick
		check(count_reason("sprint_settle") == 1 and count_reason("weapon") == 0, "Sprint attack plants feet before the blade becomes active")
		frames(35)
		check(count_reason("sprint_settle") == 1 and count_reason("weapon") == 1, "Sprint attack does not duplicate foot or weapon sounds")
		var dash_swings: Array = cues.filter(func(c): return c.kind == "weapon")
		check(dash_swings.size() == 1 and dash_swings[0].tick == attack_tick + sim.attack_data(sim.fighters[0], 0).startup, "Sprint attack audio follows character-specific active frames")
		fresh(id)
		step({"action": "dodge"})
		frames(30)
		check(count_reason("dodge") == 1, "Dodge cloth once per action")
	# Repeated avoid-contact events must not become repeated hit sounds.
	fresh("tsukiyo", 130)
	step({"action": "attack0"})
	frames(5)
	step({}, {"action": "dodge"})
	frames(30)
	check(count_reason("dodge") == 1 and count_reason("hit") == 0, "Successful dodge never sounds like a lethal hit")
	fresh("tsukiyo", 130)
	step({"action": "attack0"}, {"action": "attack0"})
	frames(30)
	check(sim.last_resolution.get("double_ko", false), "Fixture resolves simultaneous contact")
	check(count_reason("weapon") == 2 and count_reason("hit") == 2 and count_reason("collapse") == 2, "Double KO keeps both weapons, impacts and falls")
	fresh()
	sim.phase = "round_over"
	sim.fighters[0].state = "dead"
	sim.fighters[0].pos.y -= 120
	sim.fighters[0].vy = 0.0
	frames(3)
	check(count_reason("collapse") == 0, "Airborne corpse does not thud early")
	frames(55)
	check(count_reason("collapse") == 1 and count_reason("land") == 0, "Air KO thuds exactly once at ground contact")
	fresh()
	audio.present(true, false)
	step({"action": "dodge"})
	check(cues.is_empty(), "Paused frame stepping is silent")
	audio.present(true, true)
	frames(30)
	check(cues.is_empty(), "Resume does not replay paused events")
	step({"action": "dodge"})
	check(count_reason("dodge") == 1, "New action works after resume")
	check(audio.players.all(func(p): return p.bus == "SFX"), "Every voice uses the settings SFX bus")
	audio.present(true, false)
	check(audio.players.all(func(p): return not p.playing), "Pause cancels active and queued voices")
	audio.present(false, false)
	check(audio.players.all(func(p): return not p.playing), "Leaving combat stops every voice")
	var values: Dictionary = Settings.defaults().audio
	values.SFX = 0
	Settings.apply_audio(values)
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")), "SFX slider silences combat without touching music")
	Settings.apply_audio(Settings.defaults().audio)
	print("Combat audio: %d checks, %d failures" % [checks, failures])
	audio.queue_free()
	quit(1 if failures else 0)
