extends Node2D

const FISH_SCENE = preload("res://scenes/fishing/fish.tscn")
const PELICAN_SCENE = preload("res://scenes/fishing/pelican.tscn")
const SHARK_SCENE = preload("res://scenes/fishing/shark.tscn")
const OCTOPUS_SCENE = preload("res://scenes/fishing/octopus.tscn")

const CLAM_SCRIPT = preload("res://scripts/fishing/clam.gd")

const FISH_TEXTURES = [
	"res://assets/sprites/fishing/fish_angel.png",
	"res://assets/sprites/hide_seek/shared/beta_fish.png",
	"res://assets/sprites/fishing/fish_catfish.png",
	"res://assets/sprites/fishing/fish_puffer.png",
	"res://assets/sprites/fishing/fish_rainbow.png",
	"res://assets/sprites/fishing/fish_sunfish.png",
	"res://assets/sprites/hide_seek/shared/tetra_fish.png",
	"res://assets/sprites/fishing/fish_butterfly.png",
	"res://assets/sprites/fishing/fish_sword.png"
]

const CAST_DURATION = 0.5

const SPELL_3_PICTURE: Array[String] = [
	"bag", "bat", "bay", "bed", "bee", "big", "bin", "bit", "boo",
	"bow", "box", "bug", "bun", "can", "cap", "cat", "cow", "cub",
	"day", "dig", "dog", "dot", "fan", "fat", "fed", "fin", "fog",
	"fox", "fun", "goo", "ham", "hat", "hay", "hen", "hit", "hog",
	"hop", "hot", "hug", "jam", "jaw", "jet", "log", "lot", "man",
	"map", "mat", "men", "moo", "mop", "mug", "nap", "net", "not",
	"paw", "pen", "pet", "pig", "pin", "pop", "pot", "ram", "ran",
	"rat", "ray", "red", "row", "rub", "rug", "run", "sat", "saw",
	"sit", "sow", "sun", "tag", "tap", "tee", "ten", "top", "tub",
	"van", "wag", "wet", "win", "yam", "zoo"
]
const SPELL_4_PICTURE: Array[String] = [
	"back", "bake", "bale", "bell", "bike", "bite", "boat", "bone",
	"book", "bore", "buck", "cake", "cane", "cart", "chest", "coat",
	"cone", "cook", "cool", "cope", "core", "dart", "date", "dent",
	"dice", "dine", "dock", "dome", "duck", "face", "fake", "fart",
	"fate", "fine", "fool", "game", "gate", "goat", "hide", "hike",
	"hole", "home", "hope", "hose", "huck", "kick", "king", "kite",
	"lace", "lake", "lane", "late", "lick", "like", "line", "lock",
	"lone", "look", "luck", "mail", "make", "mane", "mate", "mice",
	"mine", "mite", "mole", "mope", "more", "muck", "nail", "name",
	"nice", "nine", "nose", "pace", "pack", "pail", "pale", "pick",
	"pine", "pole", "pool", "pose", "puck", "race", "rack", "rake",
	"rate", "rice", "ride", "ring", "rink", "rock", "rope", "rose",
	"sack", "sail", "same", "sick", "side", "sink", "site", "sock",
	"some", "sore", "tail", "take", "tale", "tart", "tent", "tick",
	"tone", "tool", "tuck", "vent", "vest", "vine", "wake", "well",
	"wide", "wine", "wing", "wool", "wore", "yell", "yuck", "zone"
]
const SPELL_2_SIGHT: Array[String] = [
	"be", "by", "do", "go", "he", "hi", "is", "it", "me", "my",
	"no", "of", "on", "so", "to", "up", "we"
]
const SPELL_3_SIGHT: Array[String] = [
	"all", "and", "any", "are", "ask", "but", "did", "for", "get",
	"got", "has", "her", "him", "his", "how", "its", "let", "may",
	"new", "now", "off", "own", "put", "see", "she", "the", "too",
	"try", "two", "use", "was", "who", "why", "you"
]
const SPELL_4_SIGHT: Array[String] = [
	"also", "away", "been", "both", "come", "down", "each", "even",
	"find", "from", "give", "good", "have", "here", "into", "just",
	"kind", "know", "many", "most", "much", "next", "once", "only",
	"over", "said", "soon", "stay", "than", "that", "them", "then",
	"they", "this", "time", "told", "very", "well", "went", "were",
	"what", "when", "will", "with", "your"
]

enum GameMode { FREE_PLAY, MATH, SPELLING }

@onready var fish_layer: Node2D = $FishLayer
@onready var predator_layer: Node2D = $PredatorLayer
@onready var environment: Node2D = $Environment
@onready var hook: Area2D = $Rod/Hook
@onready var hook_sprite: Sprite2D = $Rod/Hook/HookSprite
@onready var line_2d: Line2D = $Rod/Line2D
@onready var rod: Node2D = $Rod
@onready var ui = $UI

@export var rod_tip_offset: Vector2 = Vector2(135, -35)
@export var water_y_start: float = 400.0

var score: int = 0
var fish_caught: int = 0
var game_active: bool = false
var cast_tween: Tween
var hook_active: bool = false
var _difficulty: int = 1
var _timer_duration: int = 60
var _predator_timer: Timer

var _pelican: Node2D = null
var _shark: Node2D = null
var _octopus: Node2D = null
var _rock_positions: Array[Vector2] = []
var _max_fish: int = 5

var _game_mode: int = GameMode.FREE_PLAY
var _math_correct_answer: int = 0
var _problems_solved: int = 0
var _math_octopus: Node2D = null
var _math_round_resetting: bool = false

var _spell_current_word: String = ""
var _spell_missing_indices: Array[int] = []
var _spell_filled: Dictionary = {}
var _spell_held_letter: String = ""
var _words_completed: int = 0

func _ready() -> void:
	get_viewport().size_changed.connect(_on_window_resized)
	_on_window_resized()
	AudioManager.start_music()

	hook.area_entered.connect(_on_hook_area_entered)
	ui.time_up.connect(_on_time_up)
	ui.mode_selected.connect(func(m: int) -> void: _game_mode = m)
	ui.difficulty_selected.connect(func(d: int) -> void: _difficulty = d)
	ui.timer_selected.connect(_start_game)
	ui.spelling_slot_tapped.connect(_on_spelling_slot_tapped)
	ui.spelling_audio_requested.connect(func() -> void: AudioManager.play_word(_spell_current_word))
	ui.back_to_game_select.connect(func() -> void:
		AudioManager.stop_music()
		get_tree().change_scene_to_file("res://scenes/GameSelect.tscn")
	)

	_predator_timer = Timer.new()
	_predator_timer.wait_time = 4.0
	_predator_timer.one_shot = true
	_predator_timer.timeout.connect(_on_predator_timer_timeout)
	add_child(_predator_timer)

	_spawn_fish()

func _start_game(duration: float) -> void:
	game_active = true
	score = 0
	fish_caught = 0
	_problems_solved = 0
	_words_completed = 0
	_timer_duration = int(duration)
	ui.update_score(0, 0)
	ui.start_timer(duration)

	for fish in fish_layer.get_children():
		fish.queue_free()
	await get_tree().process_frame

	if _game_mode == GameMode.MATH:
		_max_fish = 5
		_spawn_math_fish()
		_spawn_math_octopus()
	elif _game_mode == GameMode.SPELLING:
		_max_fish = 8 if _difficulty == 2 else 5
		_spawn_math_octopus()
		_new_spelling_round()
	else:
		_spawn_fish()
		if _difficulty == 2:
			_spawn_persistent_predators()
			_predator_timer.start()

func _spawn_math_octopus() -> void:
	if is_instance_valid(_math_octopus):
		_math_octopus.queue_free()
	_math_octopus = OCTOPUS_SCENE.instantiate()
	predator_layer.add_child(_math_octopus)
	_math_octopus.lunge_speed = 0.6
	_math_octopus.setup(_rock_positions, fish_layer)

func _on_predator_timer_timeout() -> void:
	if not game_active or _difficulty != 2:
		return

	var attackers = []
	if is_instance_valid(_pelican): attackers.append(_pelican)
	if is_instance_valid(_shark): attackers.append(_shark)
	if is_instance_valid(_octopus): attackers.append(_octopus)

	if not attackers.is_empty():
		var success = false
		var attempts = 0
		while not success and attempts < 3:
			var attacker = attackers.pick_random()
			if attacker.has_method("trigger_attack"):
				success = attacker.trigger_attack()
			attempts += 1

	_predator_timer.wait_time = randf_range(4.0, 7.0)
	_predator_timer.start()

func _spawn_persistent_predators() -> void:
	for p in predator_layer.get_children():
		p.queue_free()

	_pelican = PELICAN_SCENE.instantiate()
	predator_layer.add_child(_pelican)
	_pelican.setup(fish_layer)

	_shark = SHARK_SCENE.instantiate()
	predator_layer.add_child(_shark)
	_shark.setup(fish_layer)

	_octopus = OCTOPUS_SCENE.instantiate()
	predator_layer.add_child(_octopus)
	_octopus.setup(_rock_positions, fish_layer)

func _input(event: InputEvent) -> void:
	if not game_active:
		return
	if event is InputEventScreenTouch and event.pressed:
		if event.position.y >= water_y_start:
			_cast_to(event.position)

func _quadratic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, t: float) -> Vector2:
	return (1.0 - t) * (1.0 - t) * p0 + 2.0 * (1.0 - t) * t * p1 + t * t * p2

func _cast_to(target_global: Vector2) -> void:
	if cast_tween:
		cast_tween.kill()
	hook_active = false
	hook.set_deferred("monitoring", false)
	line_2d.clear_points()
	hook_sprite.show()

	var start_global := rod.to_global(rod_tip_offset)
	var control_global := Vector2(
		(start_global.x + target_global.x) / 2.0,
		min(start_global.y, target_global.y) - 200.0
	)

	cast_tween = create_tween()
	cast_tween.tween_method(
		func(t: float) -> void:
			var pos := _quadratic_bezier(start_global, control_global, target_global, t)
			hook.global_position = pos
			_redraw_line(start_global, control_global, target_global, t),
		0.0, 1.0, CAST_DURATION
	)
	cast_tween.tween_callback(func() -> void:
		AudioManager.play_sfx("splash")
		hook_active = true
		hook.set_deferred("monitoring", true)
	)

func _redraw_line(start: Vector2, control: Vector2, end: Vector2, t_end: float) -> void:
	line_2d.clear_points()
	for i in 13:
		var t := float(i) / 12.0 * t_end
		line_2d.add_point(rod.to_local(_quadratic_bezier(start, control, end, t)))

func _on_hook_area_entered(area: Area2D) -> void:
	if not hook_active:
		return

	if _game_mode == GameMode.MATH:
		_handle_math_catch(area)
	elif _game_mode == GameMode.SPELLING:
		_handle_spelling_catch(area)
	else:
		_handle_free_play_catch(area)

func _handle_free_play_catch(area: Area2D) -> void:
	if not area.has_method("get_caught"):
		return
	AudioManager.play_sfx("catch")
	area.get_caught()
	score += area.points
	fish_caught += 1
	ui.update_score(score, fish_caught)
	hook_active = false
	hook.set_deferred("monitoring", false)
	hook_sprite.hide()
	line_2d.clear_points()
	call_deferred("_spawn_fish")

func _handle_math_catch(area: Area2D) -> void:
	if not area.has_method("get_caught"):
		return

	hook_active = false
	hook.set_deferred("monitoring", false)
	hook_sprite.hide()
	line_2d.clear_points()

	if area.is_correct:
		AudioManager.play_sfx("catch")
		area.get_caught()
		_problems_solved += 1
		ui.update_score(_problems_solved, _problems_solved)
		_math_round_resetting = true
		call_deferred("_new_math_round")
	else:
		AudioManager.play_sfx("bite")
		if is_instance_valid(_math_octopus):
			_math_octopus.attack_target(area)
		else:
			area.get_eaten()

func _new_math_round() -> void:
	_math_round_resetting = true
	for fish in fish_layer.get_children():
		fish.queue_free()
	await get_tree().process_frame
	_spawn_math_fish()
	_math_round_resetting = false

func _on_math_fish_removed() -> void:
	if not game_active or _game_mode != GameMode.MATH or _math_round_resetting:
		return
	call_deferred("_check_math_board")

func _check_math_board() -> void:
	if _math_round_resetting:
		return
	for fish in fish_layer.get_children():
		if fish.is_correct:
			return
	_new_math_round()

func _new_spelling_round() -> void:
	_spell_held_letter = ""
	_spell_filled.clear()
	ui.show_held_letter("")

	var pool: Array[String] = []
	match _difficulty:
		0:
			pool = SPELL_3_PICTURE.duplicate()
			if not AudioManager.master_mute:
				pool.append_array(SPELL_2_SIGHT)
				pool.append_array(SPELL_3_SIGHT)
		1:
			pool = SPELL_4_PICTURE.duplicate()
			if not AudioManager.master_mute:
				pool.append_array(SPELL_4_SIGHT)
		2:
			pool = SPELL_3_PICTURE.duplicate()
			pool.append_array(SPELL_4_PICTURE)
			if not AudioManager.master_mute:
				pool.append_array(SPELL_3_SIGHT)
				pool.append_array(SPELL_4_SIGHT)

	pool.erase(_spell_current_word)
	_spell_current_word = pool.pick_random()

	var word_len := _spell_current_word.length()
	if _difficulty < 2:
		_spell_missing_indices = [randi_range(0, word_len - 1)]
	else:
		_spell_missing_indices.clear()
		for i in word_len:
			_spell_missing_indices.append(i)

	ui.show_spelling_hud(_spell_current_word, _spell_missing_indices, _spell_filled, _difficulty == 2)
	await get_tree().create_timer(0.5).timeout
	if game_active and _game_mode == GameMode.SPELLING:
		AudioManager.play_word(_spell_current_word)

	for fish in fish_layer.get_children():
		fish.queue_free()
	await get_tree().process_frame
	if not game_active:
		return
	_spawn_spelling_fish()

func _spawn_spelling_fish() -> void:
	var word := _spell_current_word
	var correct_letters: Array[String] = []
	for idx in _spell_missing_indices:
		if not _spell_filled.has(idx):
			correct_letters.append(word[idx].to_upper())

	var distractor_count := _max_fish - correct_letters.size()
	var distractors := _generate_letter_distractors(correct_letters, distractor_count)
	var all_letters: Array[String] = correct_letters.duplicate()
	all_letters.append_array(distractors)
	all_letters.shuffle()

	var vp := get_viewport_rect()
	var water_top := water_y_start + 30.0
	var water_bottom := vp.size.y - 80.0
	var slot_size := (water_bottom - water_top) / float(_max_fish)
	var y_slots: Array[float] = []
	for i in _max_fish:
		y_slots.append(water_top + slot_size * i + slot_size * 0.5)
	y_slots.shuffle()

	var x_step := vp.size.x / float(_max_fish)
	var x_slots: Array[float] = []
	for i in _max_fish:
		x_slots.append(x_step * i + x_step * 0.5)
	x_slots.shuffle()

	for i in all_letters.size():
		var fish := FISH_SCENE.instantiate()
		fish.fish_class = Fish.FishClass.LARGE
		fish.difficulty = 0
		fish.spell_letter = all_letters[i]
		fish.is_correct = all_letters[i] in correct_letters
		fish.bounces = true
		fish.spawn_y = y_slots[i]
		fish.spawn_x = x_slots[i]
		fish.water_y = water_y_start
		fish_layer.add_child(fish)

func _respawn_spelling_letter(letter: String) -> void:
	var fish := FISH_SCENE.instantiate()
	fish.fish_class = Fish.FishClass.LARGE
	fish.difficulty = 0
	fish.spell_letter = letter
	fish.is_correct = true
	fish.bounces = true
	var vp := get_viewport_rect()
	fish.spawn_y = randf_range(water_y_start + 50.0, vp.size.y - 125.0)
	fish.water_y = water_y_start
	fish_layer.add_child(fish)

func _handle_spelling_catch(area: Area2D) -> void:
	if not area.has_method("get_caught"):
		return

	hook_active = false
	hook.set_deferred("monitoring", false)
	hook_sprite.hide()
	line_2d.clear_points()

	if area.is_correct:
		if _difficulty < 2:
			AudioManager.play_sfx("catch")
			area.get_caught()
			_words_completed += 1
			ui.update_score(_words_completed, _words_completed)
			_spell_filled[_spell_missing_indices[0]] = area.spell_letter
			ui.update_spelling_slots(_spell_current_word, _spell_missing_indices, _spell_filled)
			await get_tree().create_timer(0.8).timeout
			if game_active and _game_mode == GameMode.SPELLING:
				_new_spelling_round()
		else:
			if _spell_held_letter != "":
				_respawn_spelling_letter(_spell_held_letter)
			_spell_held_letter = area.spell_letter
			area.get_caught()
			ui.show_held_letter(_spell_held_letter)
	else:
		if is_instance_valid(_math_octopus):
			_math_octopus.attack_target(area)
		else:
			area.get_eaten()

func _on_spelling_slot_tapped(index: int) -> void:
	if not game_active or _game_mode != GameMode.SPELLING or _difficulty != 2:
		return
	if _spell_held_letter == "" or _spell_filled.has(index):
		return

	var expected := _spell_current_word[index].to_upper()
	if _spell_held_letter == expected:
		_spell_filled[index] = _spell_held_letter
		_spell_held_letter = ""
		ui.show_held_letter("")
		ui.update_spelling_slots(_spell_current_word, _spell_missing_indices, _spell_filled)
		AudioManager.play_sfx("catch")

		var complete := true
		for idx in _spell_missing_indices:
			if not _spell_filled.has(idx):
				complete = false
				break

		if complete:
			_words_completed += 1
			ui.update_score(_words_completed, _words_completed)
			await get_tree().create_timer(1.0).timeout
			if game_active and _game_mode == GameMode.SPELLING:
				_new_spelling_round()
	else:
		AudioManager.play_sfx("bite")
		ui.flash_slot_wrong(index)

func _generate_letter_distractors(correct: Array[String], count: int) -> Array[String]:
	var similar_map := {
		"A": ["E", "O"], "B": ["D", "P"], "C": ["G", "K"],
		"D": ["B", "P"], "E": ["A", "I"], "F": ["V"],
		"G": ["C", "J"], "H": ["N"], "I": ["E", "L"],
		"J": ["G"], "K": ["C"], "L": ["I"],
		"M": ["N", "W"], "N": ["M", "H"], "O": ["U", "A"],
		"P": ["B", "Q"], "Q": ["G", "O"], "R": ["L"],
		"S": ["Z", "C"], "T": ["D", "F"], "U": ["O", "V"],
		"V": ["F", "U"], "W": ["M", "V"], "X": ["K"],
		"Y": ["J"], "Z": ["S"]
	}
	var used: Array[String] = correct.duplicate()
	var result: Array[String] = []

	for correct_letter in correct:
		if result.size() >= 2:
			break
		var key := correct_letter.to_upper()
		if similar_map.has(key):
			var candidates: Array = (similar_map[key] as Array).filter(
				func(l: String) -> bool: return not used.has(l)
			)
			if not candidates.is_empty():
				var pick: String = candidates.pick_random()
				result.append(pick)
				used.append(pick)

	var alphabet := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	while result.size() < count:
		var letter := str(alphabet[randi_range(0, 25)])
		if not used.has(letter):
			result.append(letter)
			used.append(letter)

	return result

func _spawn_fish() -> void:
	while fish_layer.get_child_count() < _max_fish:
		var fish := FISH_SCENE.instantiate()
		fish.fish_class = [Fish.FishClass.LARGE, Fish.FishClass.MEDIUM, Fish.FishClass.SMALL].pick_random()
		fish.difficulty = _difficulty
		fish.water_y = water_y_start
		fish_layer.add_child(fish)
		fish.caught.connect(_on_fish_caught)

func _on_fish_caught() -> void:
	await get_tree().create_timer(0.5).timeout
	if is_instance_valid(self) and game_active and _game_mode == GameMode.FREE_PLAY:
		_spawn_fish()

func _spawn_math_fish() -> void:
	var problem := _generate_math_problem()
	_math_correct_answer = problem.answer
	ui.show_math_problem(problem.display)

	var distractors := _generate_distractors(problem.answer, 4, problem.distractor_min, problem.distractor_max)
	var numbers: Array = distractors + [problem.answer]
	numbers.shuffle()

	var vp := get_viewport_rect()
	var water_top := water_y_start + 30.0
	var water_bottom := vp.size.y - 80.0
	var slot := (water_bottom - water_top) / 5.0
	var y_slots: Array = []
	for i in 5:
		y_slots.append(water_top + slot * i + slot * 0.5)
	y_slots.shuffle()

	for i in numbers.size():
		var fish := FISH_SCENE.instantiate()
		fish.fish_class = Fish.FishClass.LARGE
		fish.difficulty = 0
		fish.math_value = numbers[i]
		fish.is_correct = (numbers[i] == problem.answer)
		fish.spawn_y = y_slots[i]
		fish.water_y = water_y_start
		fish_layer.add_child(fish)
		fish.caught.connect(_on_math_fish_removed)

func _generate_math_problem() -> Dictionary:
	match _difficulty:
		0: return _make_problem_easy()
		1: return _make_problem_hard()
		2: return _make_problem_medium()
	return _make_problem_easy()

func _make_problem_easy() -> Dictionary:
	var use_add := randf() < 0.5
	if use_add:
		var result := randi_range(1, 20)
		var a := randi_range(1, max(1, result - 1))
		var b := result - a
		return { "display": "%d + %d = ?" % [a, b], "answer": result, "distractor_min": 1, "distractor_max": 20 }
	else:
		var result := randi_range(1, 20)
		var b := randi_range(1, 20)
		var a := result + b
		return { "display": "%d - %d = ?" % [a, b], "answer": result, "distractor_min": 1, "distractor_max": 20 }

func _make_problem_medium() -> Dictionary:
	var use_add := randf() < 0.5
	if use_add:
		var result := randi_range(41, 100)
		var a := randi_range(1, result - 1)
		var b := result - a
		return { "display": "%d + %d = ?" % [a, b], "answer": result, "distractor_min": max(1, result - 20), "distractor_max": result + 20 }
	else:
		var result := randi_range(41, 100)
		var b := randi_range(1, 50)
		var a := result + b
		return { "display": "%d - %d = ?" % [a, b], "answer": result, "distractor_min": max(1, result - 20), "distractor_max": result + 20 }

func _make_problem_hard() -> Dictionary:
	var type := randi_range(0, 3)
	match type:
		0:
			var c := randi_range(2, 20)
			var b := randi_range(1, c - 1)
			var a := c - b
			return { "display": "? + %d = %d" % [b, c], "answer": a, "distractor_min": 1, "distractor_max": 20 }
		1:
			var c := randi_range(2, 20)
			var a := randi_range(1, c - 1)
			var b := c - a
			return { "display": "%d + ? = %d" % [a, c], "answer": b, "distractor_min": 1, "distractor_max": 20 }
		2:
			var c := randi_range(1, 18)
			var b := randi_range(1, 20 - c)
			var a := c + b
			return { "display": "? - %d = %d" % [b, c], "answer": a, "distractor_min": 1, "distractor_max": 20 }
		3:
			var a := randi_range(2, 20)
			var c := randi_range(1, a - 1)
			var b := a - c
			return { "display": "%d - ? = %d" % [a, c], "answer": b, "distractor_min": 1, "distractor_max": 20 }
	return _make_problem_easy()

func _generate_distractors(correct: int, count: int, min_val: int, max_val: int) -> Array:
	var pool := []
	for i in range(min_val, max_val + 1):
		if i != correct:
			pool.append(i)
	pool.shuffle()
	return pool.slice(0, count)

func _on_time_up() -> void:
	game_active = false
	hook.set_deferred("monitoring", false)
	line_2d.clear_points()
	_predator_timer.stop()
	ui.hide_math_problem()
	ui.hide_spelling_hud()
	for p in predator_layer.get_children():
		p.queue_free()
	_math_octopus = null
	if _game_mode == GameMode.MATH:
		var rank := Leaderboard.save_score(_game_mode, _difficulty, _timer_duration, _problems_solved, _problems_solved)
		ui.show_end_screen(_problems_solved, _problems_solved, _difficulty, _timer_duration, rank)
	elif _game_mode == GameMode.SPELLING:
		var rank := Leaderboard.save_score(_game_mode, _difficulty, _timer_duration, _words_completed, _words_completed)
		ui.show_end_screen(_words_completed, _words_completed, _difficulty, _timer_duration, rank)
	else:
		var rank := Leaderboard.save_score(_game_mode, _difficulty, _timer_duration, score, fish_caught)
		ui.show_end_screen(score, fish_caught, _difficulty, _timer_duration, rank)

func _on_window_resized() -> void:
	var size = get_viewport_rect().size
	if environment:
		environment.position.y = size.y - 800.0
		_populate_environment()

	var water_area = size.x * (size.y - water_y_start)
	if _game_mode == GameMode.MATH or _game_mode == GameMode.SPELLING:
		_max_fish = 8 if (_game_mode == GameMode.SPELLING and _difficulty == 2) else 5
	else:
		_max_fish = clamp(int(water_area / 110000.0) + 2, 4, 12)

	if _game_mode == GameMode.FREE_PLAY:
		_spawn_fish()

	if is_instance_valid(_octopus):
		_octopus.rock_positions = _rock_positions

func _populate_environment() -> void:
	if not environment: return

	for child in environment.get_children():
		child.queue_free()
	_rock_positions.clear()

	var width = get_viewport_rect().size.x

	var rock_count = int(width / 400.0) + 1
	for i in rock_count:
		var pos = Vector2(i * 400.0 + randf_range(50, 350), 750 + randf_range(-5, 15))
		_rock_positions.append(pos + environment.position)

	var clam_count = int(width / 600.0) + 1
	for i in clam_count:
		var c = Sprite2D.new()
		c.position = Vector2(i * 600.0 + randf_range(100, 500), 760)
		c.scale = Vector2.ONE * randf_range(0.14, 0.21)
		c.set_script(CLAM_SCRIPT)
		environment.add_child(c)
