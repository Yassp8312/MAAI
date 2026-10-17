extends SceneTree
## Register generated sheets without changing their source pixels.
## Usage: --headless --path . --script tools/build_character_atlas.gd -- ren
var errors: int = 0

func area(polygon: PackedVector2Array) -> float:
	var value: float = 0
	for i in range(polygon.size()):
		value += polygon[i].cross(polygon[(i + 1) % polygon.size()])
	return absf(value) / 2

func _initialize() -> void:
	for id in OS.get_cmdline_user_args():
		build(id)
	quit(1 if errors else 0)

func build(id: String) -> void:
	var folder := "res://art/characters/%s/v01/" % id
	var source_file := FileAccess.open(folder + "registration.json", FileAccess.READ)
	if source_file == null:
		push_error("Missing registration: " + id)
		errors += 1
		return
	var specs: Dictionary = JSON.parse_string(source_file.get_as_text())
	var output: Dictionary = {"sheets": {}, "clips": specs.clips}
	var count: int = 0
	for sheet_id in specs.sheets:
		var spec: Dictionary = specs.sheets[sheet_id]
		var source := Image.load_from_file(folder + spec.file)
		var mask := BitMap.new()
		mask.create_from_image_alpha(source, 0.08)
		var contours: Array = mask.opaque_to_polygons(Rect2i(Vector2i.ZERO, source.get_size()), 0.8)
		var cels: Array = []
		for cel in spec.cels:
			var seed := Vector2(cel.seed[0], cel.seed[1])
			var found: PackedVector2Array = []
			for contour in contours:
				if area(contour) > 1500 and Geometry2D.is_point_in_polygon(seed, contour):
					found = contour
					break
			if found.is_empty() or Geometry2D.triangulate_polygon(found).is_empty():
				push_error("Cannot extract %s/%s cel %d" % [id, sheet_id, cels.size()])
				errors += 1
				continue
			var points: Array = []
			for point in found:
				points.append([point.x, point.y])
			cels.append({"outline": points, "pivot": cel.pivot, "scale": cel.get("scale", spec.scale)})
			count += 1
		output.sheets[sheet_id] = {"file": spec.file, "scale": spec.scale, "cels": cels}
	if errors == 0:
		var file := FileAccess.open(folder + "atlas.json", FileAccess.WRITE)
		file.store_string(JSON.stringify(output))
		print("%s: %d registered cels" % [id, count])
