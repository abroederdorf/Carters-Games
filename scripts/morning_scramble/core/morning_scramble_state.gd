extends Node

## Morning Scramble State Manager
## Handles randomization, room tracking, and game progress.

signal room_completed(room_id: String)
signal item_collected(item_id: String)
signal game_started
signal game_finished

enum RoomID {
	TOY_ROOM,
	BEDROOM,
	BATHROOM,
	KITCHEN,
	DINING_ROOM,
	LIVING_ROOM,
	MUD_ROOM
}

const ROOM_NAMES = {
	RoomID.TOY_ROOM: "Toy Room",
	RoomID.BEDROOM: "Bedroom",
	RoomID.BATHROOM: "Bathroom",
	RoomID.KITCHEN: "Kitchen",
	RoomID.DINING_ROOM: "Dining Room",
	RoomID.LIVING_ROOM: "Living Room",
	RoomID.MUD_ROOM: "Mud Room"
}

const ITEMS = [
	"backpack",
	"lunchbox",
	"homework",
	"water_bottle",
	"library_book",
	"pencil_case",
	"jacket"
]

const HARD_PUZZLES = [
	RoomID.TOY_ROOM,      # Mastermind
	RoomID.LIVING_ROOM    # Pipe Builder
]

# Session State
var target_items: Array[String] = []
var collected_items: Array[String] = []
var room_to_item_map: Dictionary = {} # RoomID -> item_id
var completed_rooms: Array[RoomID] = []
var start_time: int = 0
var end_time: int = 0

func start_new_game() -> void:
	target_items.clear()
	collected_items.clear()
	room_to_item_map.clear()
	completed_rooms.clear()
	
	# 1. Choose 3 target items randomly
	var shuffled_items = ITEMS.duplicate()
	shuffled_items.shuffle()
	for i in range(3):
		target_items.append(shuffled_items[i])
	
	# 2. Seed items to rooms
	var shuffled_rooms = RoomID.values()
	shuffled_rooms.shuffle()
	
	# Difficulty Balancing: Ensure target items aren't all in HARD_PUZZLES
	_balance_difficulty(shuffled_items, shuffled_rooms)
	
	for i in range(ITEMS.size()):
		room_to_item_map[shuffled_rooms[i]] = shuffled_items[i]
	
	start_time = Time.get_ticks_msec()
	game_started.emit()

func _balance_difficulty(shuffled_items: Array, shuffled_rooms: Array) -> void:
	# Check if all target items are in hard puzzles
	var targets_in_hard_count = 0
	for i in range(3):
		var item = shuffled_items[i]
		var room_idx = i # Initial mapping is 1:1 with shuffled lists
		if shuffled_rooms[room_idx] in HARD_PUZZLES:
			targets_in_hard_count += 1
	
	# If all 3 are in hard puzzles (or more than we want), swap one target's room with a non-target's room
	if targets_in_hard_count >= 2: # Let's say max 1 hard puzzle for targets for "balance"
		# Find a target in a hard room
		for i in range(3):
			if shuffled_rooms[i] in HARD_PUZZLES:
				# Find a non-target (index 3-6) in a non-hard room
				for j in range(3, ITEMS.size()):
					if not shuffled_rooms[j] in HARD_PUZZLES:
						# Swap rooms
						var temp = shuffled_rooms[i]
						shuffled_rooms[i] = shuffled_rooms[j]
						shuffled_rooms[j] = temp
						break
				break

func complete_room(room_id: RoomID) -> void:
	if room_id in completed_rooms:
		return
		
	completed_rooms.append(room_id)
	var item_id = room_to_item_map[room_id]
	
	if item_id in target_items:
		collected_items.append(item_id)
		item_collected.emit(item_id)
	
	room_completed.emit(ROOM_NAMES[room_id])
	
	if is_game_ready_to_finish():
		# Logic for showing "Head to School" button will be in UI
		pass

func is_game_ready_to_finish() -> bool:
	return collected_items.size() == target_items.size()

func finish_game() -> void:
	end_time = Time.get_ticks_msec()
	var elapsed_seconds = (end_time - start_time) / 1000.0
	game_finished.emit(elapsed_seconds)

func get_elapsed_time() -> float:
	if end_time > 0:
		return (end_time - start_time) / 1000.0
	return (Time.get_ticks_msec() - start_time) / 1000.0
