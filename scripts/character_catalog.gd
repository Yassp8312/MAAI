extends RefCounted
## Only characters with an integrated atlas appear in the playable selector.
const ENTRIES = [
	{"id": "tsukiyo", "name": "Tsukiyo", "weapon": "Tachi"},
	{"id": "ren", "name": "Ren", "weapon": "Tachi"},
	{"id": "daichi", "name": "Daichi", "weapon": "Yari"},
	{"id": "nao", "name": "Nao", "weapon": "Tantō dobles"},
	{"id": "sayo", "name": "Sayo", "weapon": "Tessen"}
]

static func available() -> Array:
	var result: Array = []
	for entry in ENTRIES:
		if FileAccess.file_exists("res://art/characters/%s/v01/atlas.json" % entry.id):
			result.append(entry)
	return result

static func display_name(id: String) -> String:
	for entry in ENTRIES:
		if entry.id == id:
			return entry.name
	return id.capitalize()
