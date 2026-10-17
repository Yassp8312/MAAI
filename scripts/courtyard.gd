extends Node2D
## Presentation only: floor, boundaries and contact shadows read the simulation.
const BACKDROP = preload("res://art/environments/courtyard/courtyard-v01.png")
const Wind = preload("res://scripts/courtyard_wind.gd")
var simulation: RefCounted
var laboratory: bool = false
var elapsed: float = 0
var running: bool = false
var wind: AudioStreamPlayer

func _ready() -> void:
	z_index = -10
	wind = Wind.new()
	add_child(wind)

func present(sim: RefCounted, displayed: bool, moving: bool) -> void:
	simulation = sim
	visible = displayed
	running = displayed and moving and not laboratory
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
	draw_texture_rect(BACKDROP, Rect2(0, 0, 1600, 900), false)
	var floor_y: float = simulation.config.floor_y
	var left: float = simulation.config.arena_left
	var right: float = simulation.config.arena_right
	# Inlaid end stones mark the exact allowed centre positions, never new colliders.
	for edge in [left, right]:
		var tile := PackedVector2Array([Vector2(edge - 12, floor_y - 9), Vector2(edge + 12, floor_y - 9), Vector2(edge + 18, floor_y + 10), Vector2(edge - 18, floor_y + 10)])
		draw_colored_polygon(tile, Color("655e4e"))
		draw_polyline(PackedVector2Array([tile[0], tile[1], tile[2], tile[3], tile[0]]), Color("cec3a9"), 1, true)
		draw_line(Vector2(edge, floor_y - 6), Vector2(edge, floor_y + 7), Color("d9ccb0"), 2)
	# A faint horizontal stone seam keeps every landing readable on the terrace.
	draw_line(Vector2(left + 18, floor_y + 3), Vector2(right - 18, floor_y + 3), Color(0.27, 0.25, 0.20, 0.18), 1)
	for f in simulation.fighters:
		var shadow: Dictionary = shadow_for(f)
		draw_set_transform(shadow.position, 0, Vector2(shadow.width, 6))
		draw_circle(Vector2.ZERO, 1, Color(0.12, 0.13, 0.11, shadow.alpha))
		draw_set_transform(Vector2.ZERO)
		if f.state == "dead" and not simulation.airborne(f):
			for n in range(7):
				draw_circle(Vector2(f.pos.x + (n - 3) * 9, floor_y + 2 + sin(n * 4.0) * 2), 2 + n % 3, Color("793d33"))
	# Sparse bamboo and grasses sit outside the playable width, behind the fighters.
	for side in range(2):
		for stem in range(5):
			var base := Vector2(19 + stem * 13 if side == 0 else 1581 - stem * 13, 748)
			var length: float = 55 + stem * 18
			var bend: float = sin(elapsed * 0.85 + stem * 0.7 + side) * (4 + stem)
			var tip: Vector2 = base + Vector2(bend + (9 if side == 0 else -9), -length)
			draw_polyline(PackedVector2Array([base, base.lerp(tip, 0.52) + Vector2(bend * 0.3, 0), tip]), Color("5b604a"), 1.3, true)
			for leaf in range(3):
				var attach: Vector2 = base.lerp(tip, 0.4 + leaf * 0.18)
				var direction: float = 1 if (leaf + stem) % 2 == 0 else -1
				draw_colored_polygon(PackedVector2Array([attach, attach + Vector2(direction * 16, -12), attach + Vector2(direction * 25 + bend * 0.3, -13), attach + Vector2(direction * 11, -3)]), Color("555c46"))
	# Leaves remain behind silhouettes and mostly above the combat plane.
	for leaf in range(9):
		var travel: float = fmod(elapsed * (12 + leaf) + leaf * 187, 1600)
		var point := Vector2(1600 - travel, 200 + leaf * 37 + sin(travel * 0.006 + leaf) * 25)
		var angle: float = elapsed * 0.7 + leaf
		var shape := PackedVector2Array()
		for offset in [Vector2(-4, 0), Vector2(0, -2), Vector2(5, 0), Vector2(0, 2)]:
			shape.append(point + offset.rotated(angle))
		draw_colored_polygon(shape, Color(0.39, 0.24, 0.14, 0.28))
