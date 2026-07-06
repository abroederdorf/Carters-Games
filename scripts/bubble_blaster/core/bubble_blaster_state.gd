extends Node

const SAVE_PATH := "user://bubble_blaster_progress.json"

var star_bank: int = 0
var tutorial_seen: bool = false
var current_difficulty: int = 1  # 0=Easy, 1=Medium, 2=Hard; set by main screen

func _ready() -> void:
	_load()

func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if parsed is Dictionary:
		var data: Dictionary = parsed
		star_bank = data.get("star_bank", 0)
		tutorial_seen = data.get("tutorial_seen", false)

func save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify({"star_bank": star_bank, "tutorial_seen": tutorial_seen}))
	f.close()

func earn_stars(n: int) -> void:
	star_bank += n
	save()

# Deducts 1 star and returns true; returns false if the bank is empty.
func spend_star() -> bool:
	if star_bank <= 0:
		return false
	star_bank -= 1
	save()
	return true
