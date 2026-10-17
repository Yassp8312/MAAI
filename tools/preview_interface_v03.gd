extends SceneTree
## Deterministic input and real rendered transitions, without changing player saves.
var game
var frame: int = 0

func _initialize() -> void:
	run.call_deferred()

func take(count: int, label: String = "") -> void:
	for i in range(count):
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://tmp/interface-v03/%04d.png" % frame)
		frame += 1
	if not label.is_empty():
		root.get_texture().get_image().save_png("res://art/reviews/interfaz-%s-v03.png" % label)

func key(code: int) -> void:
	for down in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = down
		root.push_input(event)

func run() -> void:
	Engine.max_fps = 30
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tmp/interface-v03"))
	game = load("res://scenes/main.tscn").instantiate()
	game.play_intro_on_start = false
	game.settings.storage_path = "user://frontend-preview-unused.cfg"
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.capture_frames = 1
	DisplayServer.window_set_size(Vector2i(960, 540))
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
	DisplayServer.window_set_position(Vector2i(-2200, -1200))
	root.title = "MAAI · captura de interfaz"
	await take(90, "presentacion")
	key(KEY_ENTER)
	await take(32, "menu")
	key(KEY_DOWN)
	await take(22)
	key(KEY_DOWN)
	await take(22)
	key(KEY_UP)
	await take(22)
	key(KEY_UP)
	await take(22)
	key(KEY_ENTER)
	await take(24)
	key(KEY_D)
	await take(20)
	key(KEY_D)
	await take(20)
	key(KEY_RIGHT)
	await take(20)
	key(KEY_RIGHT)
	await take(20, "seleccion")
	game.menu.confirm_player(0)
	await take(32, "listo")
	game.menu.confirm_player(1)
	await take(24, "encuentro")
	game.queue_free()
	await process_frame
	quit()
