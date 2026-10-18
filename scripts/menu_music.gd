extends Node
## One continuous menu score, with two voices only for the loop crossfade.
const TRACK = preload("res://art/music/menu-ink-duel.ogg")
const LEVEL_DB: float = -7.0
const LOOP_FADE: float = 3.0
var track: AudioStream = TRACK
var level_db: float = LEVEL_DB
var fade_in: float = 1.4
var fade_out: float = 0.8
var voices: Array = []
var voice_active: Array = [false, false]
var enabled: bool = false
var gain: float = 0.0
var active: int = 0
var crossing: bool = false
var cross_age: float = 0.0
var starts: int = 0

func _ready() -> void:
	for index in range(2):
		var voice := AudioStreamPlayer.new()
		voice.bus = "Music"
		voice.stream = track
		voice.volume_db = -80
		add_child(voice)
		voices.append(voice)
		voice.finished.connect(func():
			voice_active[index] = false
			if enabled and index == active and not crossing:
				play_voice(index))

func play_voice(index: int) -> void:
	voice_active[index] = true
	# Headless verification has no regular mixer to drain rapid playback changes.
	# Keep the state machine testable; rendered previews use the real audio path.
	if DisplayServer.get_name() != "headless":
		voices[index].play()

func stop_voice(index: int) -> void:
	voice_active[index] = false
	voices[index].stop()

func set_enabled(value: bool) -> void:
	if enabled == value:
		return
	enabled = value
	if enabled and not voice_active[active]:
		play_voice(active)
		starts += 1

func silence() -> void:
	enabled = false
	gain = 0.0
	crossing = false
	cross_age = 0.0
	for index in range(voices.size()):
		stop_voice(index)
		voices[index].volume_db = -80

func begin_loop() -> void:
	if crossing or not enabled:
		return
	crossing = true
	cross_age = 0.0
	voices[1 - active].volume_db = -80
	play_voice(1 - active)

func _process(delta: float) -> void:
	gain = move_toward(gain, 1.0 if enabled else 0.0, delta / (fade_in if enabled else fade_out))
	if not enabled and gain == 0.0:
		if voice_active[0] or voice_active[1]:
			silence()
		return
	if enabled and not crossing and voices[active].get_playback_position() >= track.get_length() - LOOP_FADE:
		begin_loop()
	if crossing:
		cross_age += delta
		var weight: float = clampf(cross_age / LOOP_FADE, 0.0, 1.0)
		# Linear weights leave headroom even if adjacent phrases correlate.
		set_level(active, gain * (1.0 - weight))
		set_level(1 - active, gain * weight)
		if weight >= 1.0:
			stop_voice(active)
			active = 1 - active
			crossing = false
	else:
		set_level(active, gain)
		set_level(1 - active, 0.0)

func set_level(index: int, weight: float) -> void:
	voices[index].volume_db = level_db + linear_to_db(maxf(weight, 0.0001))

func _exit_tree() -> void:
	silence()
	for voice in voices:
		voice.stream = null
