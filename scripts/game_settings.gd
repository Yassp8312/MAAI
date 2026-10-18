extends RefCounted
## Preferences are independent of combat and character assets.
const FILE_PATH = "user://settings.cfg"
const RESOLUTIONS = [Vector2i(960, 540), Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1440), Vector2i(3840, 2160)]
const DEFAULT_KEYS = [[KEY_A, KEY_D, KEY_W, KEY_S, KEY_Q, KEY_F, KEY_G, KEY_H, KEY_E],
	[KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN, KEY_K, KEY_U, KEY_I, KEY_O, KEY_J]]
const DEFAULT_PAD = [JOY_BUTTON_A, JOY_BUTTON_RIGHT_SHOULDER, JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_X, JOY_BUTTON_Y, JOY_BUTTON_B, JOY_BUTTON_RIGHT_STICK]
const ACTION_NAMES = ["Mover a la izquierda", "Mover a la derecha", "Saltar", "Sprint", "Esquivar", "Ataque 1", "Ataque 2", "Ataque 3", "Bloqueo preciso / parry"]
const AUDIO_BUSES = ["Master", "Music", "SFX", "Ambience", "IntroVO"]
const RESERVED_KEYS = [KEY_ESCAPE, KEY_SPACE, KEY_F1, KEY_F2, KEY_R, KEY_TAB, KEY_ENTER, KEY_KP_ENTER, KEY_ALT, KEY_CTRL, KEY_SHIFT, KEY_META, KEY_CAPSLOCK, KEY_UNKNOWN]
var values: Dictionary = defaults()
var storage_path: String = FILE_PATH

static func defaults() -> Dictionary:
	return {"display": {"resolution": Vector2i(1280, 720), "fullscreen": false, "vsync": true},
		"audio": {"Master": 80, "Music": 70, "SFX": 80, "Ambience": 70, "IntroVO": 100, "mute": false},
		"keys": DEFAULT_KEYS.duplicate(true), "pads": [DEFAULT_PAD.duplicate(), DEFAULT_PAD.duplicate()]}

static func valid_key(code: int) -> bool:
	return code > 0 and code not in RESERVED_KEYS and not OS.get_keycode_string(code).is_empty()

static func valid_pad(code: int) -> bool:
	return code >= 0 and code < JOY_BUTTON_MAX and code not in [JOY_BUTTON_BACK, JOY_BUTTON_GUIDE, JOY_BUTTON_START, JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT]

static func binding_conflict(bindings: Array, player: int, index: int, code: int, keyboard: bool) -> String:
	for p in range(2):
		if not keyboard and p != player:
			continue
		for i in range(bindings[p].size()):
			if (p != player or i != index) and bindings[p][i] == code:
				return "Ya se usa en J%d · %s." % [p + 1, ACTION_NAMES[i if keyboard else i + 2]]
	return ""

static func valid_bindings(bindings: Variant, keyboard: bool, legacy: bool = false) -> bool:
	if not bindings is Array or bindings.size() != 2:
		return false
	for p in range(2):
		if not bindings[p] is Array or bindings[p].size() != (9 if keyboard else 7) - int(legacy):
			return false
	for p in range(2):
		for i in range(bindings[p].size()):
			var code: Variant = bindings[p][i]
			if not code is int or not (valid_key(code) if keyboard else valid_pad(code)):
				return false
			if not binding_conflict(bindings, p, i, code, keyboard).is_empty():
				return false
	return true

static func migrate_bindings(bindings: Variant, keyboard: bool) -> Variant:
	if not valid_bindings(bindings, keyboard, true):
		return bindings
	var migrated: Array = bindings.duplicate(true)
	for p in range(2):
		var candidates: Array = [DEFAULT_KEYS[p][-1]] if keyboard else [DEFAULT_PAD[-1]]
		candidates.append_array(range(KEY_A, KEY_Z + 1) if keyboard else range(JOY_BUTTON_MAX))
		for code in candidates:
			if (valid_key(code) if keyboard else valid_pad(code)) and binding_conflict(migrated, p, migrated[p].size(), code, keyboard).is_empty():
				migrated[p].append(code)
				break
	return migrated

func load_settings(path: String = "") -> void:
	values = defaults()
	var config := ConfigFile.new()
	if config.load(storage_path if path.is_empty() else path) != OK:
		return
	for section in ["display", "audio"]:
		for key in values[section]:
			var value: Variant = config.get_value(section, key, values[section][key])
			if typeof(value) != typeof(values[section][key]):
				continue
			if section == "display" and key == "resolution" and value not in RESOLUTIONS:
				continue
			if section == "audio" and key != "mute":
				value = clampi(value, 0, 100)
			values[section][key] = value
	for group in ["keys", "pads"]:
		var bindings: Variant = config.get_value("controls", group, values[group])
		bindings = migrate_bindings(bindings, group == "keys")
		if valid_bindings(bindings, group == "keys"):
			values[group] = bindings.duplicate(true)

func save_settings(path: String = "") -> Error:
	var config := ConfigFile.new()
	for section in ["display", "audio"]:
		for key in values[section]:
			config.set_value(section, key, values[section][key])
	for group in ["keys", "pads"]:
		config.set_value("controls", group, values[group])
	return config.save(storage_path if path.is_empty() else path)

func apply_all() -> void:
	apply_display(values.display)
	apply_audio(values.audio)
	apply_bindings()

func apply_bindings() -> void:
	for player in range(2):
		for index in range(ACTION_NAMES.size()):
			var action: String = "p%d_%d" % [player, index]
			if not InputMap.has_action(action):
				InputMap.add_action(action)
			InputMap.action_erase_events(action)
			var event := InputEventKey.new()
			event.physical_keycode = values.keys[player][index]
			InputMap.action_add_event(action, event)

static func apply_audio(audio: Dictionary) -> void:
	for bus in AUDIO_BUSES:
		var index: int = AudioServer.get_bus_index(bus)
		if index < 0:
			AudioServer.add_bus()
			index = AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus)
			AudioServer.set_bus_send(index, "Master")
		var level: float = float(audio[bus]) / 100.0
		AudioServer.set_bus_volume_db(index, linear_to_db(maxf(level, 0.0001)))
		AudioServer.set_bus_mute(index, level == 0.0 or (bus == "Master" and audio.mute))

static func apply_display(display: Dictionary) -> void:
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if display.vsync else DisplayServer.VSYNC_DISABLED)
	if display.fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		var usable: Rect2i = DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
		var target: Vector2i = display.resolution
		# Reserve room for the native title bar even on small laptop screens.
		target.x = mini(target.x, usable.size.x)
		target.y = mini(target.y, maxi(360, usable.size.y - 48))
		DisplayServer.window_set_size(target)
		DisplayServer.window_set_position(usable.position + (usable.size - target) / 2)
	# Assign both native window icons after applying window mode and resolution.
	# The ICO embedded in the executable is independent of the running window.
	DisplayServer.set_icon(preload("res://art/branding/maai-icon.png").get_image())

static func key_name(code: int) -> String:
	var names := {KEY_LEFT: "←", KEY_RIGHT: "→", KEY_UP: "↑", KEY_DOWN: "↓"}
	if names.has(code):
		return names[code]
	var mapped: int = code if DisplayServer.get_name() == "headless" else DisplayServer.keyboard_get_keycode_from_physical(code)
	return OS.get_keycode_string(mapped)

static func pad_name(code: int) -> String:
	var names := {JOY_BUTTON_A: "A / inferior", JOY_BUTTON_B: "B / derecho", JOY_BUTTON_X: "X / izquierdo", JOY_BUTTON_Y: "Y / superior", JOY_BUTTON_LEFT_SHOULDER: "LB / L1", JOY_BUTTON_RIGHT_SHOULDER: "RB / R1", JOY_BUTTON_LEFT_STICK: "L3", JOY_BUTTON_RIGHT_STICK: "R3"}
	return names.get(code, "Botón %d" % (code + 1))

func control_hint(player: int) -> String:
	var names: Array = []
	for code in values.keys[player]:
		names.append(key_name(code))
	return "J%d   %s / %s mover    %s salto    %s sprint    %s esquiva    %s / %s / %s ataques    %s parry" % ([player + 1] + names)
