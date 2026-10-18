extends Node2D
## Presentation only: floor, boundaries and contact shadows read the simulation.
const BACKDROP = preload("res://art/environments/courtyard/courtyard-v01.png")
const BACKDROPS = [BACKDROP, preload("res://art/environments/monochrome/bamboo.png"), preload("res://art/environments/monochrome/shore.png")]
const NAMES = ["Patio de tinta", "Santuario del bambú", "Orilla del silencio", "Laboratorio"]
var arena_index: int = 0
var backdrop: Sprite2D
const Wind = preload("res://scripts/courtyard_wind.gd")
var simulation: RefCounted
var laboratory: bool = false
var elapsed: float = 0
var running: bool = false
var wind: AudioStreamPlayer

func _ready() -> void:
	z_index = -10
	backdrop = Sprite2D.new()
	backdrop.centered = false
	backdrop.z_index = -1
	var ink := ShaderMaterial.new()
	ink.shader = preload("res://art/environments/monochrome/ink.gdshader")
	backdrop.material = ink
	add_child(backdrop)
	set_arena(0)
	wind = Wind.new()
	add_child(wind)

func set_arena(index: int) -> void:
	arena_index = posmod(index, NAMES.size())
	laboratory = arena_index == 3
	if backdrop == null: return
	backdrop.visible = not laboratory
	if not laboratory:
		backdrop.texture = BACKDROPS[arena_index]
		backdrop.scale = Vector2(1600, 900) / backdrop.texture.get_size()
		backdrop.material.set_shader_parameter("clarity", 0.38 if arena_index == 0 else 0.12)
	queue_redraw()

func title() -> String:
	return NAMES[3 if laboratory else arena_index]

func present(sim: RefCounted, displayed: bool, moving: bool) -> void:
	simulation = sim
	visible = displayed
	running = displayed and moving and not laboratory
	backdrop.visible = not laboratory
	wind.set_active(running)
	queue_redraw()

func _process(delta: float) -> void:
	if running:
		elapsed += delta
		queue_redraw()

func shadow_for(fighter: Dictionary) -> Dictionary:
	var height: float = maxf(0, simulation.config.floor_y - fighter.pos.y)
	return {"position": Vector2(fighter.pos.x, simulation.config.floor_y + 2),
		"width": lerpf(39, 23, clampf(height / 260, 0, 1)),
		"alpha": lerpf(0.22, 0.07, clampf(height / 260, 0, 1))}

func _draw() -> void:
	if simulation == null or laboratory:
		return
	var floor_y: float = simulation.config.floor_y
	var left: float = simulation.config.arena_left
	var right: float = simulation.config.arena_right
	# Inlaid end stones mark the exact allowed centre positions, never new colliders.
	for edge in [left, right]:
		var tile := PackedVector2Array([Vector2(edge - 12, floor_y - 9), Vector2(edge + 12, floor_y - 9), Vector2(edge + 18, floor_y + 10), Vector2(edge - 18, floor_y + 10)])
		draw_colored_polygon(tile, Color("666666"))
		draw_polyline(PackedVector2Array([tile[0], tile[1], tile[2], tile[3], tile[0]]), Color("cccccc"), 1, true)
		draw_line(Vector2(edge, floor_y - 6), Vector2(edge, floor_y + 7), Color("dddddd"), 2)
	# A faint horizontal stone seam keeps every landing readable on the terrace.
	draw_line(Vector2(left + 18, floor_y + 3), Vector2(right - 18, floor_y + 3), Color(0.25, 0.25, 0.25, 0.18), 1)
	for f in simulation.fighters:
		var shadow: Dictionary = shadow_for(f)
		draw_set_transform(shadow.position, 0, Vector2(shadow.width, 6))
		draw_circle(Vector2.ZERO, 1, Color(0.12, 0.12, 0.12, shadow.alpha))
		draw_set_transform(Vector2.ZERO)
		if f.state == "dead" and not simulation.airborne(f):
			for n in range(7):
				draw_circle(Vector2(f.pos.x + (n - 3) * 9, floor_y + 2 + sin(n * 4.0) * 2), 2 + n % 3, Color("454545"))
	# Sparse bamboo and grasses sit outside the playable width, behind the fighters.
	for side in range(2):
		for stem in range(5):
			var base := Vector2(19 + stem * 13 if side == 0 else 1581 - stem * 13, 748)
			var length: float = 55 + stem * 18
			var bend: float = sin(elapsed * 0.85 + stem * 0.7 + side) * (4 + stem)
			var tip: Vector2 = base + Vector2(bend + (9 if side == 0 else -9), -length)
			draw_polyline(PackedVector2Array([base, base.lerp(tip, 0.52) + Vector2(bend * 0.3, 0), tip]), Color("606060"), 1.3, true)
			for leaf in range(3):
				var attach: Vector2 = base.lerp(tip, 0.4 + leaf * 0.18)
				var direction: float = 1 if (leaf + stem) % 2 == 0 else -1
				draw_colored_polygon(PackedVector2Array([attach, attach + Vector2(direction * 16, -12), attach + Vector2(direction * 25 + bend * 0.3, -13), attach + Vector2(direction * 11, -3)]), Color("555555"))
	# Leaves remain behind silhouettes and mostly above the combat plane.
	for leaf in range(9):
		var travel: float = fmod(elapsed * (12 + leaf) + leaf * 187, 1600)
		var point := Vector2(1600 - travel, 200 + leaf * 37 + sin(travel * 0.006 + leaf) * 25)
		var angle: float = elapsed * 0.7 + leaf
		var shape := PackedVector2Array()
		for offset in [Vector2(-4, 0), Vector2(0, -2), Vector2(5, 0), Vector2(0, 2)]:
			shape.append(point + offset.rotated(angle))
		draw_colored_polygon(shape, Color(0.3, 0.3, 0.3, 0.20))
	if arena_index == 2:
		for i in range(8):
			var x: float = 300 + i * 140 + sin(elapsed * 0.2 + i) * 10
			var y: float = 530 + i * 16
			draw_line(Vector2(x, y), Vector2(x + 45 + sin(elapsed + i) * 8, y), Color(0.5, 0.5, 0.5, 0.09), 1, true)
