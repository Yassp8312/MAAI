extends SceneTree
## Run externally against the exported executable; this tool is not shipped.
var game
var failures: int = 0
var output: String
var results: Array = []

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	results.append({"passed": ok, "check": label})
	if not ok: failures += 1

func shot(name: String) -> void:
	for i in range(12): await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(output.path_join(name + ".png")) == OK, "capture " + name)

func run() -> void:
	output = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(output)
	game = load("res://scenes/main.tscn").instantiate()
	game.settings.storage_path = "user://export-verification-unused.cfg"
	root.add_child(game)
	game.set_physics_process(false)
	game.capture_frames = 1
	DisplayServer.window_set_size(Vector2i(1280, 720))
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
	DisplayServer.window_set_position(Vector2i(-2200, -1200))
	check(game.menu.screen == "studio", "packaged startup opens studio")
	for i in range(75): await process_frame
	await shot("studio")
	for i in range(90): await process_frame
	check(game.menu.screen == "intro", "studio advances automatically to prologue")
	await shot("prologo")
	game.menu.show_home()
	await shot("menu")
	check(game.menu_music.voices[0].playing or game.menu_music.voices[1].playing, "menu decoder playing")
	var ids := ["tsukiyo", "ren", "daichi", "nao", "sayo"]
	for i in range(ids.size()):
		game.select_character(0, ids[i])
		game.select_character(1, ids[(i + 1) % ids.size()])
		game.start_game("practice")
		game.select_arena(i % 3)
		await shot("arena-" + ids[i])
		check(game.training_music.voices[0].playing or game.training_music.voices[1].playing, "dojo decoder playing for " + ids[i])
		game.return_to_menu()
	game.start_game()
	check(game.battle_music.enabled, "duel score enabled")
	await shot("combate")
	game.open_pause()
	await shot("pausa")
	game.open_options()
	await shot("opciones")
	game.options.cancel()
	game.return_to_menu()
	game.menu.show_credits()
	game.menu.credits.show_page(1)
	await shot("creditos")
	print("Export verification: %d failures" % failures)
	var report := FileAccess.open(output.path_join("verification.json"), FileAccess.WRITE)
	report.store_string(JSON.stringify({"failures": failures, "checks": results, "executable": OS.get_executable_path()}, "\t"))
	report.close()
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)
