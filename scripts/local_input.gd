extends RefCounted
const Settings = preload("res://scripts/game_settings.gd")
var settings: RefCounted
var previous_pad: Array = [{}, {}]
var blocked: Array = [true, true]
var device_slots: Array = []
const COMMANDS = ["jump", "sprint", "dodge", "attack0", "attack1", "attack2", "parry"]

func _init(preferences: RefCounted):
	settings = preferences

func block_until_release() -> void:
	blocked = [true, true]
	previous_pad = [{}, {}]

func set_devices(slots: Array) -> void:
	device_slots = slots.duplicate()
	block_until_release()

func sample(player: int) -> Dictionary:
	var prefix: String = "p%d_" % player
	var axis: int = int(Input.is_action_pressed(prefix + "1")) - int(Input.is_action_pressed(prefix + "0"))
	var pressed: Dictionary = {}
	var any_held: bool = axis != 0
	for i in range(Settings.ACTION_NAMES.size()):
		any_held = any_held or Input.is_action_pressed(prefix + str(i))
	for i in range(COMMANDS.size()):
		pressed[COMMANDS[i]] = Input.is_action_just_pressed(prefix + str(i + 2))
	var pads: Array = Input.get_connected_joypads()
	var device: int = device_slots[player] if device_slots.size() == 2 else (pads[player] if pads.size() > player else -1)
	if device in pads:
		var stick: float = Input.get_joy_axis(device, JOY_AXIS_LEFT_X)
		var pad_axis: int = int(Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_RIGHT)) - int(Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_LEFT))
		if absf(stick) > 0.35:
			pad_axis = 1 if stick > 0 else -1
		if pad_axis != 0:
			axis = pad_axis
		var buttons: Array = settings.values.pads[player]
		for i in range(COMMANDS.size()):
			var held: bool = Input.is_joy_button_pressed(device, buttons[i])
			any_held = any_held or held
			pressed[COMMANDS[i]] = pressed[COMMANDS[i]] or (held and not previous_pad[player].get(COMMANDS[i], false))
			previous_pad[player][COMMANDS[i]] = held
	else:
		previous_pad[player].clear()
	if blocked[player]:
		if not any_held and axis == 0:
			blocked[player] = false
		return {"axis": 0, "action": ""}
	# Explicit tie-break for simultaneous commands. No repeated held attacks.
	for command in ["parry", "attack0", "attack1", "attack2", "dodge", "sprint", "jump"]:
		if pressed[command]:
			return {"axis": axis, "action": command}
	return {"axis": axis, "action": ""}

