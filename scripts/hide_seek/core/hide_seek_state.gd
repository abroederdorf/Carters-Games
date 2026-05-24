extends Node

const SAVE_PATH = "user://find_it_progress.json"

const SCENE_ORDER: Array[String] = [
	"pet_shop",
	"circus",
	"dinosaur_land",
	"monster_truck_jam",
	"mountains",
	"jungle",
	"construction_site",
	"airport",
	"space",
	"fire_station",
	"ocean",
]

const DISPLAY_NAMES: Dictionary = {
	"mountains": "Mountains",
	"ocean": "Ocean",
	"jungle": "Jungle",
	"airport": "Airport",
	"space": "Space",
	"dinosaur_land": "Dinosaur Land",
	"fire_station": "Fire Station",
	"monster_truck_jam": "Monster Truck Jam",
	"construction_site": "Construction Site",
	"pet_shop": "Pet Shop",
	"circus": "Circus",
}

var current_scene_name: String = ""
var current_scene_list_page: int = 0
var hint_stars: int = 0
var _progress: Dictionary = {}

func _ready() -> void:
	_load()

func _load() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
		var parsed: Variant = JSON.parse_string(f.get_as_text())
		f.close()
		if parsed is Dictionary:
			var data: Dictionary = parsed as Dictionary
			if data.has("scenes"):
				var scenes: Variant = data["scenes"]
				if scenes is Dictionary:
					_progress = scenes as Dictionary
				hint_stars = data.get("hint_stars", 0)
			else:
				_progress = data  # legacy format
	_ensure_defaults()

func _ensure_defaults() -> void:
	for i in SCENE_ORDER.size():
		var sname := SCENE_ORDER[i]
		if not _progress.has(sname):
			_progress[sname] = {"stars": 0, "completed": false, "unlocked": i == 0}
	var first: Dictionary = _progress[SCENE_ORDER[0]]
	first["unlocked"] = true

func save() -> void:
	var save_data := {"hint_stars": hint_stars, "scenes": _progress}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(save_data))
	f.close()

func is_unlocked(sname: String) -> bool:
	if not _progress.has(sname):
		return false
	var entry: Dictionary = _progress[sname]
	return entry.get("unlocked", false)

func is_completed(sname: String) -> bool:
	if not _progress.has(sname):
		return false
	var entry: Dictionary = _progress[sname]
	return entry.get("completed", false)

func get_stars(sname: String) -> int:
	if not _progress.has(sname):
		return 0
	var entry: Dictionary = _progress[sname]
	return entry.get("stars", 0)

func complete_scene(sname: String, stars: int) -> void:
	if not _progress.has(sname):
		return
	var entry: Dictionary = _progress[sname]
	var prev_stars: int = entry.get("stars", 0)
	var was_completed: bool = entry.get("completed", false)
	entry["stars"] = max(prev_stars, stars)
	entry["completed"] = true
	if not was_completed:
		hint_stars += stars
	elif stars > prev_stars:
		hint_stars += stars - prev_stars
	elif prev_stars == 3:
		hint_stars += 1
	var idx := SCENE_ORDER.find(sname)
	if idx >= 0 and idx + 1 < SCENE_ORDER.size():
		var next: Dictionary = _progress[SCENE_ORDER[idx + 1]]
		next["unlocked"] = true
	save()
