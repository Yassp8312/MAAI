extends SceneTree
## Register alpha silhouettes and foot pivots without modifying source PNG pixels.
const IDS = ["tsukiyo", "ren", "daichi", "nao", "sayo"]
var failures: int = 0

func _initialize() -> void:
	var ids: Array = Array(OS.get_cmdline_user_args())
	if ids.is_empty(): ids = IDS
	for id in ids: build(id)
	quit(1 if failures else 0)

func polygon_area(points: PackedVector2Array) -> float:
	var area: float = 0
	for i in range(points.size()): area += points[i].cross(points[(i + 1) % points.size()])
	return absf(area) * 0.5

func bounds(points: PackedVector2Array) -> Rect2:
	var rect := Rect2(points[0], Vector2.ZERO)
	for p in points: rect = rect.expand(p)
	return rect

func build(id: String) -> void:
	var folder: String = "res://art/characters/%s/v01/" % id
	var image := Image.load_from_file(folder + "07-defence.png")
	if image == null:
		failures += 1
		return
	var mask := BitMap.new()
	mask.create_from_image_alpha(image, 0.08)
	var shapes: Array = []
	for polygon in mask.opaque_to_polygons(Rect2i(Vector2i.ZERO, image.get_size()), 0.8):
		if polygon_area(polygon) > 10000:
			shapes.append({"points": polygon, "rect": bounds(polygon)})
	if shapes.size() != 6:
		push_error("Expected six isolated poses for %s, found %d" % [id, shapes.size()])
		failures += 1
		return
	shapes.sort_custom(func(a, b):
		var row_a: int = int(a.rect.get_center().y / (image.get_height() / 2.0))
		var row_b: int = int(b.rect.get_center().y / (image.get_height() / 2.0))
		return a.rect.get_center().x < b.rect.get_center().x if row_a == row_b else row_a < row_b)
	# One body scale per sheet preserves crouching/recoil height instead of stretching it.
	# Registered from head to floor in the upright poses, excluding raised weapons.
	var scales: Dictionary = {"tsukiyo": 0.56, "ren": 0.54, "daichi": 0.60, "nao": 0.51, "sayo": 0.51}
	var cels: Array = []
	for i in range(6):
		var shape: Dictionary = shapes[i]
		var points: Array = []
		var feet: Array = []
		for point in shape.points:
			points.append([point.x, point.y])
			if point.y >= shape.rect.end.y - (60 if id == "nao" else 26):
				feet.append(point.x)
		if Geometry2D.triangulate_polygon(shape.points).is_empty():
			failures += 1
			push_error("Untriangulable defence pose: %s/%d" % [id, i])
			return
		var scale: float = scales[id]
		cels.append({"outline": points, "pivot": [(feet.min() + feet.max()) / 2.0, shape.rect.end.y], "scale": scale})
		print("%s cel %d bounds %s pivot %s scale %.3f" % [id, i, shape.rect, cels[-1].pivot, scale])
	var clips: Dictionary = {
		"parry": {"frames": [["defence", 0], ["defence", 1], ["defence", 5]], "fps": 12},
		"parry_success": {"frames": [["defence", 1], ["defence", 2], ["defence", 5]], "fps": 20},
		"parried": {"frames": [["defence", 3], ["defence", 4], ["defence", 5]], "fps": 10}}
	if id == "nao":
		# Cel 1 has an ambiguous extra blade; use the clean two-dagger deflection pose.
		clips.parry.frames[1] = ["defence", 2]
		clips.parry_success.frames = [["defence", 2], ["defence", 0], ["defence", 5]]
	var file := FileAccess.open(folder + "defence.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"sheets": {"defence": {"file": "07-defence.png", "scale": 1, "cels": cels}}, "clips": clips}))
