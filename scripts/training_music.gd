extends "res://scripts/menu_music.gd"
## Ink Duel's quieter dojo variation. Practice resets never restart the score.
const PATH = "res://art/music/training.ogg"
var quiet: bool = false
var duck_remaining: float = 0.0
var mix_db: float = 0.0

func _ready() -> void:
	if not ResourceLoader.exists(PATH): return
	track = load(PATH)
	level_db = -4.0
	super._ready()

func on_combat_cue(event: Dictionary) -> void:
	if enabled and event.kind in ["weapon", "impact", "parry"]:
		duck_remaining = maxf(duck_remaining, 0.25 if event.kind in ["impact", "parry"] else 0.15)

func set_enabled(value: bool) -> void:
	if voices.is_empty(): return
	super.set_enabled(value)

func _process(delta: float) -> void:
	if voices.is_empty(): return
	duck_remaining = maxf(0, duck_remaining - delta)
	var target: float = -12.0 if quiet else (-2.0 if duck_remaining > 0 else 0.0)
	mix_db = move_toward(mix_db, target, delta * (50.0 if target < mix_db else 10.0))
	super._process(delta)

func set_level(index: int, weight: float) -> void:
	super.set_level(index, weight)
	voices[index].volume_db += mix_db

func silence() -> void:
	super.silence()
	duck_remaining = 0
	mix_db = 0
