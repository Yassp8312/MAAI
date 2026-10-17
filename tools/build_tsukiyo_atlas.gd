extends SceneTree
## Extracts render geometry from alpha; original generated PNGs are never edited.
const ROOT = "res://art/characters/tsukiyo/v01/"
const SPECS = {
	"guard": {"file": "01-guard-walk.png", "scale": 0.584,
		"seeds": [[220,200],[665,200],[1120,200],[1565,200],[230,650],[675,650],[1120,650],[1565,650]],
		"pivots": [[232,438],[678,438],[1135,437],[1580,437],[235,879],[690,868],[1135,872],[1575,879]]},
	"thrust": {"file": "02-thrust.png", "scale": 0.73,
		"seeds": [[260,190],[890,190],[270,510],[900,510],[285,820],[915,820],[290,1120],[900,1120]],
		"pivots": [[270,350],[897,351],[270,663],[897,664],[270,957],[897,957],[270,1249],[897,1251]]},
	"cuts": {"file": "03-cuts.png", "scale": 0.895,
		"seeds": [[330,170],[930,170],[320,480],[920,480],[310,810],[950,810],[320,1120],[910,1120]],
		"pivots": [[327,299],[936,300],[327,616],[936,617],[310,922],[930,919],[327,1238],[936,1237]]},
	"air": {"file": "04-air.png", "scale": 0.70,
		"seeds": [[320,180],[930,200],[300,500],[940,490],[290,800],[950,810],[300,1110],[960,1110]],
		"pivots": [[320,365],[930,379],[310,667],[940,667],[310,970],[940,987],[310,1290],[940,1290]]},
	"motion": {"file": "05-motion-defeat.png", "scale": 0.66,
		"seeds": [[370,200],[1000,200],[320,560],[940,560],[320,870],[950,900],[320,1160],[950,1160]],
		"pivots": [[330,361],[960,370],[315,686],[930,677],[315,1010],[930,1003],[315,1225],[930,1211]]},
	"sprint": {"file": "06-sprint-v02.png", "scale": 0.532,
		"seeds": [[280,250],[840,250],[1350,250],[285,750],[842,750],[1340,750]],
		"pivots": [[278,504],[840,498],[1350,500],[285,988],[842,990],[1340,992]]}
}
var errors: int = 0

func area(polygon: PackedVector2Array) -> float:
	var value: float = 0
	for i in range(polygon.size()):
		value += polygon[i].cross(polygon[(i + 1) % polygon.size()])
	return absf(value) / 2

func _initialize() -> void:
	var output: Dictionary = {"sheets": {}, "clips": make_clips()}
	for id in SPECS:
		var spec: Dictionary = SPECS[id]
		var source := Image.load_from_file(ROOT + spec.file)
		var mask := BitMap.new()
		mask.create_from_image_alpha(source, 0.08)
		var contours: Array = mask.opaque_to_polygons(Rect2i(Vector2i.ZERO, source.get_size()), 0.8)
		var polygons: Array = []
		for contour in contours:
			if area(contour) < 5000:
				continue
			# Two touching cels in the source have interleaved feet/hair. This
			# registration boundary separates them without cutting off either foot.
			if id == "thrust" and Geometry2D.is_point_in_polygon(Vector2(915,820), contour):
				var upper := PackedVector2Array([Vector2(627,630),Vector2(1254,630),Vector2(1254,962),Vector2(1000,962),Vector2(960,944),Vector2(815,944),Vector2(780,962),Vector2(627,962)])
				var lower := PackedVector2Array([Vector2(627,962),Vector2(780,962),Vector2(815,944),Vector2(960,944),Vector2(1000,962),Vector2(1254,962),Vector2(1254,1254),Vector2(627,1254)])
				polygons.append_array(Geometry2D.intersect_polygons(contour, upper))
				polygons.append_array(Geometry2D.intersect_polygons(contour, lower))
			else:
				polygons.append(contour)
		var cels: Array = []
		for i in range(spec.seeds.size()):
			var seed := Vector2(spec.seeds[i][0], spec.seeds[i][1])
			var found: PackedVector2Array = []
			for polygon in polygons:
				if Geometry2D.is_point_in_polygon(seed, polygon):
					found = polygon
					break
			if found.is_empty() or Geometry2D.triangulate_polygon(found).is_empty():
				push_error("Cannot extract %s cel %d" % [id, i])
				errors += 1
				continue
			var points: Array = []
			for point in found:
				points.append([point.x, point.y])
			cels.append({"outline": points, "pivot": spec.pivots[i]})
		output.sheets[id] = {"file": spec.file, "scale": spec.scale, "cels": cels}
	if errors == 0:
		var file := FileAccess.open(ROOT + "atlas.json", FileAccess.WRITE)
		file.store_string(JSON.stringify(output))
		print("Tsukiyo: 46 cels extracted (44 used, 2 legacy sprint), source PNGs unchanged")
	quit(1 if errors else 0)

func clip(frames: Array, fps: float = 8.0, phases: Array = []) -> Dictionary:
	var result := {"frames": frames, "fps": fps}
	if not phases.is_empty():
		result.phases = phases
	return result

func make_clips() -> Dictionary:
	return {
		"idle": clip([["guard",0],["guard",1]], 1.5),
		"walk": clip([["guard",2],["guard",3],["guard",4],["guard",5],["guard",6],["guard",7]], 10),
		"backstep": clip([["guard",7],["guard",6],["guard",5],["guard",4],["guard",3],["guard",2]], 10),
		"sprint": clip([["sprint",0],["sprint",1],["sprint",2],["sprint",3],["sprint",4],["sprint",5]], 20),
		"dodge": clip([["motion",2],["motion",3],["motion",4]]),
		"jump": clip([["air",0]]),
		"fall": clip([["air",1]]),
		"dead": clip([["motion",5],["motion",6],["motion",7]]),
		"TEST_GROUND_A1": clip([["thrust",0],["thrust",1],["thrust",2],["thrust",3],["thrust",4],["thrust",5],["thrust",6],["thrust",7]], 12, [[0,1,2,3],[4,5],[5,6,7]]),
		"TEST_GROUND_A2": clip([["guard",0],["cuts",0],["cuts",1],["cuts",2],["cuts",3]], 12, [[0,1],[2,3],[3,4,0]]),
		"TEST_GROUND_A3": clip([["guard",0],["cuts",4],["cuts",5],["cuts",6],["cuts",7]], 12, [[0,1],[2,3],[3,4,0]]),
		"TEST_AIR_A1": clip([["air",0],["air",2],["air",3],["air",1]], 12, [[0,1],[2],[2,1,3]]),
		"TEST_AIR_A2": clip([["air",0],["air",4],["air",5],["air",1]], 12, [[0,1],[2],[2,3]]),
		"TEST_AIR_A3": clip([["air",0],["air",6],["air",7],["air",1]], 12, [[0,1],[2],[2,3]])
	}
