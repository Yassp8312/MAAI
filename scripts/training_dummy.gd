extends RefCounted
## Ordinary inputs and real contacts; never changes combat rules.
const MODES = ["manual", "idle", "repeat", "parry", "dodge", "jump", "sequence", "replay"]
const NAMES = ["Control libre de J2", "Quedarse quieto", "Repetir un ataque", "Responder con parry", "Repetir esquiva", "Repetir salto", "Secuencia de tres ataques", "Reproducir grabación"]
var mode: String = "manual"
var move: int = -1
var distance: float = 335.0
var interval: int = 100
var wait_ticks: int = 60
var auto_reset: bool = true
var show_info: bool = true
var sequence: Array = [0, 1, 2]
var sequence_index: int = 0
var recording: bool = false
var recording_inputs: Array = []
var record_characters: Array = []
var record_distance: float = 335.0
var replay_tick: int = 0
var replay_rest: int = 0
var exercise: String = "free"
var hits: int = 0
var losses: int = 0
var deflections: int = 0
var successes: int = 0
var feedback: String = "Mide la distancia y elige tu respuesta."
var last_rival: Dictionary = {}

func cycle(sim: RefCounted) -> void:
	move = (move + 2) % 4 - 1
	mode = "repeat" if move >= 0 else "manual"
	distance = clampf(sim.combat_profile(sim.fighters[1]).reaches[maxi(0, move)] - 30.0, 95.0, 180.0)
	reset(sim)

func reset(sim: RefCounted) -> void:
	wait_ticks = 60
	sequence_index = 0
	replay_tick = 0
	replay_rest = 0
	sim.reset_round()
	sim.scores = [0, 0]
	sim.phase = "fight"
	var gap: float = record_distance if mode == "replay" and not recording_inputs.is_empty() else distance
	sim.fighters[0].pos.x = 800.0 - gap * 0.5
	sim.fighters[1].pos.x = 800.0 + gap * 0.5
	for f in sim.fighters: f.previous = f.pos
	last_rival = {}

func clear_stats() -> void:
	hits = 0
	losses = 0
	deflections = 0
	successes = 0
	feedback = "Nueva sesión. Mide la distancia."

func start_recording(sim: RefCounted) -> void:
	mode = "manual"
	move = -1
	exercise = "free"
	recording_inputs.clear()
	record_characters = sim.character_ids.duplicate()
	record_distance = distance
	reset(sim)
	recording = true
	feedback = "Grabando J2: usa sus controles durante cinco segundos."

func finish_recording() -> void:
	recording = false
	feedback = "Grabación lista · %0.1f s. Reprodúcela desde Entrenamiento." % (recording_inputs.size() / 60.0)

func can_replay(sim: RefCounted) -> bool:
	return not recording_inputs.is_empty() and sim.character_ids == record_characters

func sample(sim: RefCounted, manual: Dictionary = {}) -> Dictionary:
	last_rival = sim.fighters[1].duplicate(true)
	if sim.phase != "fight": return {}
	if recording:
		recording_inputs.append(manual.duplicate(true))
		if recording_inputs.size() >= 300: finish_recording()
		return manual
	if mode == "manual": return manual
	if mode == "idle": return {}
	if mode == "replay":
		if not can_replay(sim): return {}
		if replay_tick < recording_inputs.size():
			var input: Dictionary = recording_inputs[replay_tick].duplicate(true)
			replay_tick += 1
			return input
		replay_rest += 1
		if replay_rest >= 60: reset(sim)
		return {}
	var rival: Dictionary = sim.fighters[1]
	if mode == "parry":
		var player: Dictionary = sim.fighters[0]
		if player.state == "attack" and rival.state == "idle" and not sim.airborne(rival):
			var attack: Resource = sim.attack_data(player)
			if player.age == maxi(0, attack.startup - 2): return {"action": "parry"}
		return {}
	wait_ticks -= 1
	if wait_ticks > 0 or rival.state != "idle" or sim.airborne(rival): return {}
	wait_ticks = interval
	if mode == "dodge": return {"action": "dodge"}
	if mode == "jump": return {"action": "jump"}
	var chosen: int = maxi(0, move)
	if mode == "sequence":
		chosen = sequence[sequence_index]
		sequence_index = (sequence_index + 1) % sequence.size()
	return {"action": "attack%d" % chosen}

func after_step(sim: RefCounted) -> void:
	for event in sim.events:
		if event.kind == "parry" and event.player == 0:
			deflections += 1
			feedback = "Desvío confirmado. Busca la respuesta que alcance."
			if exercise == "parry": successes += 1
		elif event.kind == "resolution":
			if recording: finish_recording()
			for contact in event.detail.contacts:
				if contact.attacker == 0:
					hits += 1
					feedback = "Golpe confirmado. R repite desde la distancia elegida."
					if exercise == "punish" and not last_rival.is_empty() and last_rival.state == "attack":
						var attack: Resource = sim.attack_data(last_rival)
						if last_rival.age >= attack.startup + attack.active:
							successes += 1
							feedback = "Castigo conseguido: entraste durante la recuperación de Daichi."
				else:
					losses += 1
					feedback = "Demasiado pronto: el parry ya había terminado." if contact.get("defence_expired", false) else "El rival alcanzó tu cuerpo. Prueba otra distancia o espera su fallo."
	if auto_reset and sim.phase == "countdown": reset(sim)

func should_step(sim: RefCounted) -> bool:
	if auto_reset or sim.phase != "round_over": return true
	for f in sim.fighters:
		if sim.airborne(f) or (f.state == "dead" and f.death_ground_age < 21): return true
	sim.events.clear()
	return false

func hint(_sim: RefCounted) -> String:
	if recording: return "GRABANDO J2 · %.1f / 5 s · F3 para detener" % (recording_inputs.size() / 60.0)
	if exercise == "punish": return "CASTIGAR EL FALLO · Espera la punta de Daichi, acércate y entra · F3 ajustes / R repetir"
	if exercise == "parry": return "DESVIAR · Pulsa al recibir; mantener no protege · F3 ajustes / R repetir"
	return "%s · F3 entrenamiento / R repetir" % NAMES[MODES.find(mode)]

func phase_name(sim: RefCounted, f: Dictionary) -> String:
	if f.state == "attack":
		var attack: Resource = sim.attack_data(f)
		return "Preparación" if f.age < attack.startup else ("Contacto" if sim.active(f) else "Recuperación")
	return {"idle": "Guardia", "sprint": "Sprint", "dodge": "Esquiva", "parry": "Parry", "parried": "Arma desviada", "parry_success": "Desvío", "dead": "Derrota"}.get(f.state, f.state)
