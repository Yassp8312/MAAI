extends Control
const Style = preload("res://scripts/interface_style.gd")
const Catalog = preload("res://scripts/character_catalog.gd")
var game
var titles: Array = []
var notes: Array = []
var move_titles: Array = [[], []]
var move_roles: Array = [[], []]
var close_button: Button

func setup(owner_game: Node) -> void:
	game = owner_game
	size = Vector2(1600, 900)
	theme = Style.control_theme()
	var shade := ColorRect.new()
	shade.size = size
	shade.color = Color(0.035, 0.055, 0.045, 0.88)
	add_child(shade)
	Style.paper(self, Rect2(64, 64, 1472, 772))
	Style.label(self, "Cada arma, una intención.", Rect2(104, 90, 1200, 60), 42, true)
	Style.label(self, "El alcance cambia con la técnica. Un paso de ataque también te expone.", Rect2(108, 153, 1300, 28), 19, false, Style.MUTED)
	for player in range(2):
		var x: float = 108 + 722 * player
		titles.append(Style.label(self, "", Rect2(x, 207, 630, 40), 29, true))
		var note := Style.label(self, "", Rect2(x, 251, 620, 56), 18, false, Style.MUTED)
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		notes.append(note)
		for move in range(6):
			var y: float = 320 + move * 67
			move_titles[player].append(Style.label(self, "", Rect2(x, y, 630, 28), 20, false, Style.RED))
			var role := Style.label(self, "", Rect2(x, y + 28, 630, 38), 17)
			role.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			move_roles[player].append(role)
	Style.label(self, "Los botones de ataque son los mismos en tierra y en el aire. Parry: pulsa al recibir; mantener no protege.", Rect2(108, 739, 1360, 28), 17, false, Style.MUTED)
	close_button = Style.button(self, "Volver a la pausa")
	close_button.position = Vector2(1156, 778)
	close_button.size = Vector2(330, 44)
	close_button.pressed.connect(close)
	hide()

func open() -> void:
	game.paused = true
	game.frame_step = false
	for player in range(2):
		var f: Dictionary = game.sim.fighters[player]
		titles[player].text = "J%d · %s" % [player + 1, Catalog.display_name(f.character_id)]
		notes[player].text = game.sim.combat_profile(f).style_note
		for move in range(6):
			var data: Resource = game.sim.attack_data(f, move)
			var key: String = game.settings.key_name(game.settings.values.keys[player][5 + move % 3])
			var pad: String = game.settings.pad_name(game.settings.values.pads[player][3 + move % 3]).split(" / ")[0]
			move_titles[player][move].text = "%s / %s%s · %s" % [key, pad, " en aire" if move >= 3 else "", data.display_name]
			move_roles[player][move].text = data.role
	game.pause_menu.hide()
	show()
	close_button.grab_focus()
	game.refresh()

func close() -> void:
	hide()
	game.pause_menu.show()
	game.pause_menu.techniques_button.grab_focus()
	game.refresh()
