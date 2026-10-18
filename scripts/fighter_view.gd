extends Node2D
## Replace this scene or supply SpriteFrames; this node never changes simulation.
@export var sprite_frames: SpriteFrames
@export var sprite_height: float = 250.0
@export var foot_anchor: Vector2 = Vector2(-1, -1)
@export var use_tsukiyo: bool = false
@export var character_id: String = "tsukiyo"
var character_animation: RefCounted
var fighter: Dictionary = {}
var simulation: RefCounted
var player: int = 0
var debug_boxes: bool = false

func _ready() -> void:
	if use_tsukiyo:
		set_character(character_id)
		var ink := ShaderMaterial.new()
		ink.shader = preload("res://art/characters/tsukiyo/ink.gdshader")
		material = ink

func set_character(id: String) -> void:
	character_id = id
	if use_tsukiyo:
		character_animation = preload("res://scripts/tsukiyo_animation.gd").new(id)
	queue_redraw()

func present(sim: RefCounted, index: int, debug: bool) -> void:
	simulation = sim
	fighter = sim.fighters[index]
	player = index
	debug_boxes = debug
	position = fighter.pos
	queue_redraw()

func _draw() -> void:
	if fighter.is_empty():
		return
	var white := Color("e5e5df")
	var gray := Color("9b9b96")
	var facing: int = fighter.facing
	var death: float = minf(1.0, fighter.death_ground_age / 24.0) if fighter.state == "dead" and not simulation.airborne(fighter) else 0.0
	if death > 0.0:
		draw_set_transform(Vector2(0, -8 * death), -facing * death * PI * 0.48, Vector2(1, 1))
	if character_animation != null:
		var cel: Dictionary = character_animation.pose(simulation, player)
		var tilt: float = 0.0
		if fighter.state == "parry":
			tilt = -facing * 0.035 * (1.0 - float(fighter.age) / simulation.config.parry_ticks)
		elif fighter.state == "parry_success":
			tilt = -facing * 0.055 * (1.0 - float(fighter.age) / simulation.config.parry_success_ticks)
		elif fighter.state == "parried":
			tilt = -facing * 0.035 * sin(PI * (fighter.age + 1.0) / (simulation.config.parried_ticks + 1.0))
		draw_set_transform(Vector2.ZERO, tilt, Vector2(facing * cel.scale, cel.scale))
		draw_mesh(cel.mesh, cel.texture)
	elif sprite_frames != null:
		draw_sprite_pose(facing)
	else:
		# Deliberately plain anatomical proxy. Its envelope matches the hurtbox.
		var lean: float = sin(simulation.tick * 0.09) * 1.5
		if fighter.state == "sprint":
			lean = facing * 12.0
		var dodge: float = 9.0 if fighter.state == "dodge" else 0.0
		var ink := Color("252526") if player == 0 else Color("101011")
		var torso := PackedVector2Array([Vector2(-25 + lean, -194 + dodge), Vector2(23 + lean, -194 + dodge), Vector2(31, -89), Vector2(-31, -89)])
		draw_colored_polygon(torso, ink)
		draw_polyline(PackedVector2Array([torso[0], torso[1], torso[2], torso[3], torso[0]]), white, 3, true)
		draw_arc(Vector2(lean, -224 + dodge), 24, 0, TAU, 32, white, 3, true)
		draw_line(Vector2(lean + facing * 8, -226 + dodge), Vector2(lean + facing * 22, -226 + dodge), white, 3, true)
		var stride: float = sin(simulation.tick * 0.3) * 13.0 if absf(fighter.pos.x - fighter.previous.x) > 0.1 else 0.0
		draw_polyline(PackedVector2Array([Vector2(-18, -89), Vector2(-24 - stride, -48), Vector2(-27, 0)]), white, 5, true)
		draw_polyline(PackedVector2Array([Vector2(18, -89), Vector2(24 + stride, -48), Vector2(27, 0)]), white, 5, true)
		draw_line(Vector2(-31, 0), Vector2(-12, 0), white, 4)
		draw_line(Vector2(12, 0), Vector2(31, 0), white, 4)
		draw_line(Vector2(-25, -101), Vector2(27, -101), gray, 4)
		var hand := Vector2(facing * 50, -145 + dodge)
		draw_polyline(PackedVector2Array([Vector2(lean, -181 + dodge), Vector2(facing * 25, -153 + dodge), hand]), white, 4, true)
		if fighter.state != "attack":
			draw_line(hand, hand + Vector2(facing * 145, -35), white, 4, true)
		if player == 1:
			draw_line(Vector2(-17, -178), Vector2(17, -178), white, 2)
	draw_set_transform(Vector2.ZERO)
	# Only the defender draws the contact flash, once per resolved deflection.
	if fighter.state == "parry_success":
		var contact: Vector2 = fighter.parry_point - position
		var fade: float = 1.0 - float(fighter.age) / simulation.config.parry_success_ticks
		for ray in range(5):
			var direction := Vector2.RIGHT.rotated(-2.6 + ray * 1.17)
			draw_line(contact + direction * 5, contact + direction * (12 + 20 * fade), Color(0.96, 0.92, 0.80, fade), 2, true)
	if debug_boxes and simulation.parry_ready(fighter):
		draw_line(Vector2(facing * 40, -225), Vector2(facing * 40, -35), Color("eee4ce"), 3, true)
	if fighter.state == "attack":
		var blade: Rect2 = simulation.blade(fighter)
		blade.position -= position
		var live: bool = simulation.active(fighter)
		var color: Color = white if live else Color("666662")
		if character_animation == null and sprite_frames == null:
			draw_line(blade.position + Vector2(0, blade.size.y * 0.5), blade.end - Vector2(0, blade.size.y * 0.5), color, blade.size.y if live else 3.0, true)
		if debug_boxes and live:
			draw_rect(blade, Color(1, 1, 1, 0.13))
			draw_rect(blade, white, false, 1)
	if debug_boxes and simulation.invulnerable(fighter):
		draw_line(Vector2(-36, 8), Vector2(36, 8), white, 3)
	if debug_boxes and fighter.state != "dead":
		var hurt: Rect2 = simulation.body(fighter)
		hurt.position -= position
		draw_rect(hurt, Color(0.8, 0.8, 0.8, 0.05))
		draw_rect(hurt, gray, false, 1)
		draw_circle(Vector2.ZERO, 4, white)

func draw_sprite_pose(facing: int) -> void:
	var animation: String = fighter.state
	if animation == "idle":
		animation = "jump" if simulation.airborne(fighter) else ("walk" if absf(fighter.pos.x - fighter.previous.x) > 0.1 else "idle")
	if fighter.state == "attack":
		animation = simulation.attack_data(fighter).id
	if not sprite_frames.has_animation(animation):
		animation = "idle"
	if not sprite_frames.has_animation(animation):
		return
	var count: int = sprite_frames.get_frame_count(animation)
	if count == 0:
		return
	var duration: float = 0.0
	for frame in range(count):
		duration += sprite_frames.get_frame_duration(animation, frame)
	var clock_ticks: int = simulation.tick
	if fighter.state in ["attack", "sprint", "dodge"]:
		clock_ticks = fighter.age
	elif fighter.state == "dead":
		clock_ticks = 0 if simulation.airborne(fighter) else fighter.death_ground_age
	var elapsed: float = clock_ticks / 60.0 * sprite_frames.get_animation_speed(animation)
	if fighter.state == "attack":
		var a: Resource = simulation.attack_data(fighter)
		elapsed = float(fighter.age) / (a.startup + a.active + a.finish) * duration
	elif sprite_frames.get_animation_loop(animation):
		elapsed = fmod(elapsed, duration)
	else:
		elapsed = minf(elapsed, duration - 0.0001)
	var index: int = count - 1
	for frame in range(count):
		var exposure: float = sprite_frames.get_frame_duration(animation, frame)
		if elapsed < exposure:
			index = frame
			break
		elapsed -= exposure
	var texture: Texture2D = sprite_frames.get_frame_texture(animation, index)
	if texture == null:
		return
	var scale_factor: float = sprite_height / texture.get_height()
	var pivot: Vector2 = foot_anchor if foot_anchor.x >= 0 else Vector2(texture.get_width() * 0.5, texture.get_height())
	draw_set_transform(Vector2.ZERO, 0, Vector2(facing * scale_factor, scale_factor))
	draw_texture(texture, -pivot)
	draw_set_transform(Vector2.ZERO)

