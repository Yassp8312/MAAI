extends Control
## Display existing masters; cropping and motion belong to the UI, not the PNG.
var texture: Texture2D
var head_only: bool = false
var mirrored: bool = false
var elapsed: float = 0
var reveal: float = 1

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ink := ShaderMaterial.new()
	ink.shader = preload("res://art/characters/tsukiyo/ink.gdshader")
	material = ink

func set_character(id: String) -> void:
	texture = load("res://art/characters/%s/v01/reference.png" % id)
	if id == "tsukiyo":
		# Full-resolution transparent master, kept separate from combat cels.
		texture = load("res://art/characters/tsukiyo/ui-master.png")
	reveal = 0
	queue_redraw()

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	elapsed += delta
	reveal = minf(1, reveal + delta * 5)
	queue_redraw()

func _draw() -> void:
	if texture == null:
		return
	var source := Rect2(Vector2.ZERO, texture.get_size())
	if head_only:
		source = Rect2(texture.get_size() * Vector2(0.17, 0.01), texture.get_size() * Vector2(0.68, 0.38))
	var ratio: float = minf(size.x / source.size.x, size.y / source.size.y)
	var extent: Vector2 = source.size * ratio
	var origin: Vector2 = (size - extent) * 0.5
	if not head_only:
		origin.y += sin(elapsed * 1.1) * 2.5 + (1 - reveal) * 12
	if mirrored:
		draw_set_transform(Vector2(size.x, 0), 0, Vector2(-1, 1))
	draw_texture_rect_region(texture, Rect2(origin, extent), source, Color(1, 1, 1, reveal))
	draw_set_transform(Vector2.ZERO)
