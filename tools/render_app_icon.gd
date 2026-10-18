extends SceneTree
func _initialize() -> void:
	var svg: String = FileAccess.get_file_as_string("res://art/branding/maai-icon.svg")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tmp/icons"))
	for size in [16, 24, 32, 48, 64, 128, 256, 512]:
		var image := Image.new()
		assert(image.load_svg_from_string(svg, size / 512.0) == OK)
		image.save_png("res://tmp/icons/maai-%d.png" % size)
		if size == 512: image.save_png("res://art/branding/maai-icon.png")
	quit()
