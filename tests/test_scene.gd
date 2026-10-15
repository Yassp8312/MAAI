extends SceneTree

func _initialize() -> void:
	var scene = load("res://scenes/main.tscn")
	if scene == null:
		push_error("Main scene could not load")
		quit(1)
		return
	var instance = scene.instantiate()
	root.add_child.call_deferred(instance)
	finish.call_deferred(instance)

func finish(instance: Node) -> void:
	await process_frame
	if instance.get_script() == null or not instance.has_method("start_game"):
		push_error("Main script missing")
		quit(1)
		return
	instance.start_game()
	for i in range(120):
		await physics_frame
	if instance.sim.phase != "fight":
		push_error("Scene did not enter playable fight")
		quit(1)
		return
	print("MAAI: scene loaded and reached playable fight")
	quit(0)
