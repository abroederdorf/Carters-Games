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
		var parsed = JSON.parse_string(f.get_as_text())
		f.close()
		if parsed is Dictionary:
			_progress = parsed
	_ensure_defaults()

func _ensure_defaults() -> void:
	for i in SCENE_ORDER.size():
		var sname := SCENE_ORDER[i]
		if not _progress.has(sname):
			_progress[sname] = {"stars": 0, "completed": false, "unlocked": i == 0}
	_progress[SCENE_ORDER[0]]["unlocked"] = true

func save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(_progress))
	f.close()

func is_unlocked(sname: String) -> bool:
	return _progress.get(sname, {}).get("unlocked", false)

func is_completed(sname: String) -> bool:
	return _progress.get(sname, {}).get("completed", false)

func get_stars(sname: String) -> int:
	return _progress.get(sname, {}).get("stars", 0)

func complete_scene(sname: String, stars: int) -> void:
	if not _progress.has(sname):
		return
	_progress[sname]["stars"] = max(_progress[sname].get("stars", 0), stars)
	_progress[sname]["completed"] = true
	var idx := SCENE_ORDER.find(sname)
	if idx >= 0 and idx + 1 < SCENE_ORDER.size():
		_progress[SCENE_ORDER[idx + 1]]["unlocked"] = true
	save()
