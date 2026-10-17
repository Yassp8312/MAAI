extends SceneTree

func _initialize() -> void:
	for filename in ["01-guard-walk.png", "02-thrust.png", "03-cuts.png", "04-air.png", "05-motion-defeat.png", "06-sprint-v02.png"]:
		var image := Image.load_from_file("res://art/characters/tsukiyo/v01/" + filename)
		var bitmap := BitMap.new()
		bitmap.create_from_image_alpha(image, 0.08)
		var polygons: Array = bitmap.opaque_to_polygons(Rect2i(Vector2i.ZERO, image.get_size()), 0.8)
		var large: Array = []
		for polygon in polygons:
			var area: float = 0
			for i in range(polygon.size()):
				area += polygon[i].cross(polygon[(i + 1) % polygon.size()])
			if absf(area) > 10000:
				var bounds := Rect2(polygon[0], Vector2.ZERO)
				for point in polygon:
					bounds = bounds.expand(point)
				large.append({"bounds": bounds, "area": absf(area) / 2, "vertices": polygon.size()})
		print(filename, " ", image.get_size(), " ", large)
	quit()
