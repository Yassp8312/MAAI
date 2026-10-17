extends AudioStreamPlayer
## Quiet placeholder wind, no downloaded recordings. Respects Ambience/Master.
var requested: bool = false
var level: float = 0

func _ready() -> void:
	bus = "Ambience"
	volume_db = -60
	if DisplayServer.get_name() == "headless":
		return
	var rate: int = 22050
	var count: int = rate * 12
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var random := RandomNumberGenerator.new()
	random.seed = 74219
	var low: float = 0
	var softer: float = 0
	for i in range(count):
		var t: float = float(i) / rate
		low = lerpf(low, random.randf_range(-1, 1), 0.055)
		softer = lerpf(softer, low, 0.008)
		var gust: float = 0.5 + 0.22 * sin(TAU * t / 12) + 0.12 * sin(TAU * t / 4)
		var seam: float = minf(1, minf(t, 12 - t) / 0.35)
		var value: float = clampf((low * 0.7 + softer * 1.8) * gust * seam, -1, 1)
		bytes.encode_s16(i * 2, int(value * 32767))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.data = bytes
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = count
	stream = wav

func set_active(active: bool) -> void:
	requested = active
	if active and not playing and stream != null:
		play()

func _process(delta: float) -> void:
	level = move_toward(level, 1.0 if requested else 0.0, delta * 2)
	volume_db = linear_to_db(maxf(level * 0.34, 0.001))
	if not requested and level <= 0 and playing:
		stop()

func _exit_tree() -> void:
	stop()
