extends AudioStreamPlayer
## Quiet procedural plucks. Routed through the user's existing SFX/Master buses.
var tones: Dictionary = {}

func _ready() -> void:
	bus = "SFX"
	volume_db = -19
	max_polyphony = 3
	for kind in ["move", "confirm", "back", "begin"]:
		var duration: float = 0.055 if kind == "move" else 0.22
		var frequency: float = {"move": 520.0, "confirm": 740.0, "back": 310.0, "begin": 440.0}[kind]
		var bytes := PackedByteArray()
		var count: int = int(22050 * duration)
		bytes.resize(count * 2)
		for i in range(count):
			var t: float = float(i) / 22050
			var envelope: float = minf(1, t / 0.004) * exp(-t * 24) * (1 - float(i) / count)
			var value: float = (sin(TAU * frequency * t) + 0.3 * sin(TAU * frequency * 2.01 * t)) * envelope * 0.6
			bytes.encode_s16(i * 2, int(value * 32767))
		var wav := AudioStreamWAV.new()
		wav.format = AudioStreamWAV.FORMAT_16_BITS
		wav.mix_rate = 22050
		wav.data = bytes
		tones[kind] = wav

func cue(kind: String) -> void:
	# Headless verification has no audio mixer to drain pending playbacks.
	if DisplayServer.get_name() == "headless":
		return
	if tones.has(kind):
		stop()
		stream = tones[kind]
		play()

func _exit_tree() -> void:
	stop()
