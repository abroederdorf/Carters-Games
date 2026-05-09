extends Node

const MAX_ENTRIES := 5
const SAVE_PATH := "user://leaderboard.cfg"

var _config: ConfigFile

func _ready() -> void:
	_config = ConfigFile.new()
	_config.load(SAVE_PATH)

func save_score(difficulty: int, timer_secs: int, score: int, fish: int) -> int:
	var key := "%d_%d" % [difficulty, timer_secs]
	var entries: Array = _config.get_value("lb", key, [])
	var now := Time.get_unix_time_from_system()
	var new_entry := {"score": score, "fish": fish, "time": now}

	entries.append(new_entry)
	entries.sort_custom(func(a, b):
		if a["score"] != b["score"]: return a["score"] > b["score"]
		if a["fish"] != b["fish"]: return a["fish"] > b["fish"]
		return a.get("time", 0) > b.get("time", 0)
	)

	var rank := -1
	for i in min(entries.size(), MAX_ENTRIES):
		if entries[i].get("time", 0) == now:
			rank = i + 1
			break

	if entries.size() > MAX_ENTRIES:
		entries.resize(MAX_ENTRIES)

	_config.set_value("lb", key, entries)
	_config.save(SAVE_PATH)
	return rank

func get_scores(difficulty: int, timer_secs: int) -> Array:
	return _config.get_value("lb", "%d_%d" % [difficulty, timer_secs], [])

func save_settings(difficulty: int, timer_secs: int) -> void:
	_config.set_value("settings", "difficulty", difficulty)
	_config.set_value("settings", "timer_secs", timer_secs)
	_config.save(SAVE_PATH)

func load_settings() -> Dictionary:
	return {
		"difficulty": _config.get_value("settings", "difficulty", 0),
		"timer_secs": _config.get_value("settings", "timer_secs", 60)
	}
