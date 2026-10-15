extends RefCounted
var previous_pad: Array = [{}, {}]
const KEYS = [[KEY_A, KEY_D, KEY_W, KEY_S, KEY_Q, KEY_F, KEY_G, KEY_H],
	[KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN, KEY_K, KEY_U, KEY_I, KEY_O]]
const COMMANDS = ["jump", "sprint", "dodge", "attack0", "attack1", "attack2"]

func _init():
	for player in range(2):
		for i in range(8):
			var action: String = "p%d_%d" % [player, i]
			if not InputMap.has_action(action):
				InputMap.add_action(action)
				var event := InputEventKey.new()
				event.physical_keycode = KEYS[player][i]
				InputMap.action_add_event(action, event)

func sample(player: int) -> Dictionary:
	var prefix: String = "p%d_" % player
	var axis: int = int(Input.is_action_pressed(prefix + "1")) - int(Input.is_action_pressed(prefix + "0"))
	var pressed: Dictionary = {}
	for i in range(6):
		pressed[COMMANDS[i]] = Input.is_action_just_pressed(prefix + str(i + 2))
	var pads: Array = Input.get_connected_joypads()
	if pads.size() > player:
		var device: int = pads[player]
		var stick: float = Input.get_joy_axis(device, JOY_AXIS_LEFT_X)
		var pad_axis: int = int(Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_RIGHT)) - int(Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_LEFT))
		if absf(stick) > 0.35:
			pad_axis = 1 if stick > 0 else -1
		if pad_axis != 0:
			axis = pad_axis
		var buttons: Array = [JOY_BUTTON_A, JOY_BUTTON_RIGHT_SHOULDER, JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_X, JOY_BUTTON_Y, JOY_BUTTON_B]
		for i in range(6):
			var held: bool = Input.is_joy_button_pressed(device, buttons[i])
			pressed[COMMANDS[i]] = pressed[COMMANDS[i]] or (held and not previous_pad[player].get(COMMANDS[i], false))
			previous_pad[player][COMMANDS[i]] = held
	else:
		previous_pad[player].clear()
	# Explicit tie-break for simultaneous commands. No repeated held attacks.
	for command in ["attack0", "attack1", "attack2", "dodge", "sprint", "jump"]:
		if pressed[command]:
			return {"axis": axis, "action": command}
	return {"axis": axis, "action": ""}

