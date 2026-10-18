extends Control
signal closed
const Style = preload("res://scripts/interface_style.gd")
const EMAIL = "jorgecintra2@gmail.com"
var pages: Array = []
var page_index: int = 0
var buttons: Array = []
var next_button: Button

func setup() -> void:
	size = Vector2(1600, 900)
	theme = Style.control_theme()
	Style.label(self, "M A A I   /   YASSPER DESIGN", Rect2(80, 55, 1400, 38), 22, true)
	for i in range(2):
		var page := Control.new()
		page.size = size
		page.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(page)
		pages.append(page)
	Style.label(pages[0], "Quienes dieron forma al encuentro.", Rect2(80, 130, 1430, 80), 48, true)
	Style.label(pages[0], "Una visión compartida. Oficios que se encuentran en el mismo trazo.", Rect2(85, 220, 1350, 35), 23, false, Style.MUTED)
	name_block(pages[0], 85, "Jorge Ricardo\nCintra Rad", "DIRECCIÓN Y DISEÑO", "Game Designer · Dirección creativa\nProgramación · Diseño de interfaces\nNarrativa · Dirección de arte\nConcepto y dirección de la composición musical")
	name_block(pages[0], 835, "Jesus Luis\nPerez Martinez", "DESARROLLO Y SISTEMAS", "Programación · Sistemas de juego\nIntegración técnica · Herramientas\nPruebas y revisión técnica\nProducción y desarrollo, en colaboración")
	var anonymous := Style.label(pages[0], "Agradecemos a quienes aportaron al juego, incluida la ilustración, y prefieren permanecer en el anonimato.", Rect2(85, 702, 1300, 62), 18, false, Style.MUTED)
	anonymous.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	anonymous.size = Vector2(1300, 62)
	Style.label(pages[1], "El trazo, la voz y el sonido.", Rect2(80, 130, 1430, 80), 48, true)
	Style.label(pages[1], "Recursos, herramientas y agradecimientos", Rect2(85, 220, 1350, 35), 23, false, Style.MUTED)
	Style.label(pages[1], "EFECTOS DE COMBATE · FUENTES CC0", Rect2(85, 302, 700, 32), 18, false, Style.RED)
	link(pages[1], "Kenney · Impact Sounds / RPG Audio ↗", "https://kenney.nl/assets/impact-sounds", Vector2(85, 354))
	link(pages[1], "StarNinjas · Sword Sound Effects ↗", "https://opengameart.org/content/20-sword-sound-effects-attacks-and-clashes", Vector2(85, 407))
	link(pages[1], "Vehicle / Jan Schupke · Fantasy Weapons ↗", "https://opengameart.org/content/fantasy-weapons-and-apparel-sfx-library", Vector2(85, 460))
	link(pages[1], "artisticdude · Swishes Sound Pack ↗", "https://opengameart.org/content/swishes-sound-pack", Vector2(85, 513))
	paragraph(pages[1], "Grabaciones editadas, combinadas y sincronizadas para las armas y los pasos de cada personaje.", Rect2(85, 575, 640, 76), 20)
	Style.label(pages[1], "MÚSICA Y NARRACIÓN", Rect2(835, 302, 650, 32), 18, false, Style.RED)
	paragraph(pages[1], "Ink Resolve · Prólogo\nInk Duel · Presentación y menús\nInk Duel — Dojo · Entrenamiento\nBanda sonora 2 y 3 · Duelos", Rect2(835, 350, 650, 168), 25)
	paragraph(pages[1], "Selección, dirección y montaje musical del proyecto. Música generada con Suno; narración creada con ElevenLabs.", Rect2(835, 535, 650, 85), 19)
	link(pages[1], "Godot Engine · Motor y licencia MIT ↗", "https://godotengine.org/license/", Vector2(835, 636))
	paragraph(pages[1], "Cada encuentro reúne el trabajo de sus creadores y de quienes compartieron sus recursos con el proyecto.", Rect2(85, 702, 1380, 65), 18)
	var back := Style.button(self, "← Volver al menú")
	back.position = Vector2(80, 815)
	back.size = Vector2(320, 48)
	back.pressed.connect(func(): closed.emit())
	next_button = Style.button(self, "Recursos y herramientas →")
	next_button.position = Vector2(430, 815)
	next_button.size = Vector2(380, 48)
	next_button.pressed.connect(func(): show_page(1 - page_index))
	var contact := link(self, "Feedback · " + EMAIL + " ↗", "mailto:" + EMAIL, Vector2(880, 830))
	buttons = [back, next_button, contact]
	link(self, "Un café para Jorge ↗", "https://jorge-coffee.onrender.com/", Vector2(1190, 70), 16)
	show_page(0)

func name_block(parent: Control, x: float, name: String, role: String, details: String) -> void:
	Style.label(parent, role, Rect2(x, 310, 650, 30), 18, false, Style.RED)
	Style.label(parent, name, Rect2(x, 357, 640, 130), 44, true)
	Style.label(parent, details, Rect2(x, 515, 650, 150), 22, false, Style.INK)

func paragraph(parent: Control, text: String, rect: Rect2, font_size: int) -> void:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.position = rect.position
	label.size = rect.size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Style.MUTED)
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)

func link(parent: Control, text: String, uri: String, pos: Vector2, font_size: int = 21) -> LinkButton:
	var node := LinkButton.new()
	node.text = text
	node.uri = uri
	node.position = pos
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", Style.MUTED)
	parent.add_child(node)
	return node

func show_page(index: int) -> void:
	page_index = index
	for i in range(pages.size()): pages[i].visible = i == index
	if next_button != null: next_button.text = "Recursos y herramientas →" if index == 0 else "← Equipo creador"
