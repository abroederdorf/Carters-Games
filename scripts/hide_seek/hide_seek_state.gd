extends Node

const SAVE_PATH = "user://find_it_progress.json"

const SCENE_ORDER: Array[String] = [
	"mountains",
	"ocean",
	"jungle",
	"space",
	"dinosaur_land",
	"fire_station",
	"monster_truck_jam",
	"construction_site",
]

var current_scene_name: String = ""
var _progress: Dictionary = {}

func _ready() -> void:
	_load()

func _load() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
		var parsed: Variant = JSON.parse_string(f.get_as_text())
		f.close()
		if parsed is Dictionary:
			_progress = parsed as Dictionary
	_ensure_defaults()

func _ensure_defaults() -> void:
	for i in SCENE_ORDER.size():
		var sname := SCENE_ORDER[i]
		if not _progress.has(sname):
			_progress[sname] = {"stars": 0, "completed": false, "unlocked": i == 0}
	var first: Dictionary = _progress[SCENE_ORDER[0]]
	first["unlocked"] = true

func save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(_progress))
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
	entry["stars"] = max(entry.get("stars", 0), stars)
	entry["completed"] = true
	var idx := SCENE_ORDER.find(sname)
	if idx >= 0 and idx + 1 < SCENE_ORDER.size():
		var next: Dictionary = _progress[SCENE_ORDER[idx + 1]]
		next["unlocked"] = true
	save()
