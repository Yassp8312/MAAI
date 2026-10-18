extends "res://scripts/menu_music.gd"
## Alternate complete matches; rounds and pauses keep the same score playing.
const TRACKS = [preload("res://art/music/battle-2.ogg"), preload("res://art/music/battle-3.ogg")]
var selected: int = -1
var quiet: bool = false
var duck_remaining: float = 0.0
var mix_db: float = 0.0

func _ready() -> void:
	track = TRACKS[0]
	level_db = -3.0
	fade_in = 1.1
	super._ready()

func begin_match() -> void:
	silence()
	selected = (selected + 1) % TRACKS.size()
	track = TRACKS[selected]
	active = 0
	quiet = false
	duck_remaining = 0.0
	mix_db = 0.0
	for voice in voices:
		voice.stream = track
	set_enabled(true)

func on_combat_cue(event: Dictionary) -> void:
	if enabled and event.kind in ["weapon", "impact", "parry"]:
		duck_remaining = maxf(duck_remaining, 0.32 if event.kind in ["impact", "parry"] else 0.18)

func _process(delta: float) -> void:
	duck_remaining = maxf(0.0, duck_remaining - delta)
	var target: float = -12.0 if quiet else (-3.0 if duck_remaining > 0 else 0.0)
	mix_db = move_toward(mix_db, target, delta * (60.0 if target < mix_db else 10.0))
	super._process(delta)

func set_level(index: int, weight: float) -> void:
	super.set_level(index, weight)
	voices[index].volume_db += mix_db
