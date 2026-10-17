extends SceneTree
func _initialize() -> void:
	for path in OS.get_cmdline_user_args():
		var image := Image.load_from_file(path)
		var mask := BitMap.new()
		mask.create_from_image_alpha(image, 0.08)
		var contours: Array = mask.opaque_to_polygons(Rect2i(Vector2i.ZERO, image.get_size()), 0.8)
		var large: Array = []
		for p in contours:
			var area: float = 0
			for i in range(p.size()):
				area += p[i].cross(p[(i + 1) % p.size()])
			if absf(area) < 3000:
				continue
			var bounds := Rect2(p[0], Vector2.ZERO)
			for point in p:
				bounds = bounds.expand(point)
			large.append({"bounds": [bounds.position.x,bounds.position.y,bounds.size.x,bounds.size.y], "area": absf(area)/2})
		print(path, " ", image.get_size(), " ", JSON.stringify(large))
	quit()
