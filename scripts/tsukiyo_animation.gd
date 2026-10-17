extends RefCounted
## Hand-drawn cels are selected by simulation phase, never the other way round.
var asset_root: String
var sheets: Dictionary = {}
var clips: Dictionary = {}
static var cache: Dictionary = {}

func _init(character_id: String = "tsukiyo") -> void:
	asset_root = "res://art/characters/%s/v01/" % character_id
	if cache.has(character_id):
		sheets = cache[character_id].sheets
		clips = cache[character_id].clips
		return
	var file := FileAccess.open(asset_root + "atlas.json", FileAccess.READ)
	if file == null:
		push_error("Missing character atlas manifest: " + character_id)
		return
	var manifest: Dictionary = JSON.parse_string(file.get_as_text())
	for id in manifest.sheets:
		var spec: Dictionary = manifest.sheets[id]
		var texture: Texture2D = load(asset_root + spec.file)
		var cels: Array = []
		for cel in spec.cels:
			var polygon := PackedVector2Array()
			var vertices := PackedVector3Array()
			var uv := PackedVector2Array()
			var pivot := Vector2(cel.pivot[0], cel.pivot[1])
			for point in cel.outline:
				var position := Vector2(point[0], point[1])
				polygon.append(position)
				vertices.append(Vector3(position.x - pivot.x, position.y - pivot.y, 0))
				uv.append(position / texture.get_size())
			var arrays: Array = []
			arrays.resize(Mesh.ARRAY_MAX)
			arrays[Mesh.ARRAY_VERTEX] = vertices
			arrays[Mesh.ARRAY_TEX_UV] = uv
			arrays[Mesh.ARRAY_INDEX] = Geometry2D.triangulate_polygon(polygon)
			var mesh := ArrayMesh.new()
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			cels.append({"texture": texture, "mesh": mesh, "scale": float(cel.get("scale", spec.scale))})
		sheets[id] = cels
	clips = manifest.clips
	cache[character_id] = {"sheets": sheets, "clips": clips}

func clip_name(sim: RefCounted, player: int) -> String:
	var fighter: Dictionary = sim.fighters[player]
	if fighter.state == "attack":
		return sim.config.attacks[fighter.attack].id
	if fighter.state == "idle":
		if sim.airborne(fighter):
			return "jump" if fighter.vy < 0 else "fall"
		if absf(fighter.pos.x - fighter.previous.x) > 0.1:
			return "walk" if (fighter.pos.x - fighter.previous.x) * fighter.facing > 0 else "backstep"
	return fighter.state

func pose(sim: RefCounted, player: int) -> Dictionary:
	var fighter: Dictionary = sim.fighters[player]
	var name: String = clip_name(sim, player)
	var clip: Dictionary = clips.get(name, clips.idle)
	var frames: Array = clip.frames
	var index: int = 0
	if fighter.state == "attack":
		var attack: Resource = sim.config.attacks[fighter.attack]
		var lengths: Array = [attack.startup, attack.active, attack.finish]
		var age: int = fighter.age
		for phase in range(3):
			if age < lengths[phase]:
				var entries: Array = clip.phases[phase]
				index = entries[mini(entries.size() - 1, int(float(age) / lengths[phase] * entries.size()))]
				break
			age -= lengths[phase]
	elif name == "dead":
		# Hold the initial collapse in the air; lying poses start only on landing.
		index = 0 if sim.airborne(fighter) else mini(frames.size() - 1, int(fighter.death_ground_age / 7.0))
	elif name == "dodge":
		# Anticipation, crouch held for invulnerability, then return to guard.
		if fighter.age < sim.config.dodge_start:
			index = 0
		elif fighter.age < sim.config.dodge_end:
			index = 1
		else:
			index = 2
	elif name == "sprint":
		# One launch/glide/settle sequence across the committed dash, never a loop.
		index = clampi(int(float(fighter.age) / sim.config.sprint_ticks * frames.size()), 0, frames.size() - 1)
	else:
		index = int(sim.tick / 60.0 * float(clip.get("fps", 8))) % frames.size()
	var ref: Array = frames[index]
	var result: Dictionary = sheets[ref[0]][int(ref[1])].duplicate()
	result["clip"] = name
	result["frame"] = index
	return result
