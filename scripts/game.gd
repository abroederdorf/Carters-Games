extends Node2D

const FISH_SCENE = preload("res://scenes/Fish.tscn")
const PELICAN_SCENE = preload("res://scenes/Pelican.tscn")
const SHARK_SCENE = preload("res://scenes/Shark.tscn")
const OCTOPUS_SCENE = preload("res://scenes/Octopus.tscn")

const SAND_TEX = preload("res://assets/sprites/sand.svg")
const ROCK_TEX = preload("res://assets/sprites/rock_gray.svg")
const SW_G_TEX = preload("res://assets/sprites/seaweed_green.svg")
const SW_P_TEX = preload("res://assets/sprites/seaweed_purple.svg")
const SW_PK_TEX = preload("res://assets/sprites/seaweed_pink.svg")
const SWAY_SCRIPT = preload("res://scripts/sway.gd")
const CLAM_SCRIPT = preload("res://scripts/clam.gd")

const CAST_DURATION = 0.5

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
@export var water_y_start: float = 250.0

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
var _math_pelican: Node2D = null

func _ready() -> void:
	get_viewport().size_changed.connect(_on_window_resized)
	_on_window_resized()

	hook.area_entered.connect(_on_hook_area_entered)
	ui.time_up.connect(_on_time_up)
	ui.mode_selected.connect(func(m: int) -> void: _game_mode = m)
	ui.difficulty_selected.connect(func(d: int) -> void: _difficulty = d)
	ui.timer_selected.connect(_start_game)

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
	_timer_duration = int(duration)
	ui.update_score(0, 0)
	ui.start_timer(duration)

	for fish in fish_layer.get_children():
		fish.queue_free()
	await get_tree().process_frame

	if _game_mode == GameMode.MATH:
		_max_fish = 6
		_spawn_math_fish()
		_spawn_math_pelican()
	else:
		_spawn_fish()
		if _difficulty == 2:
			_spawn_persistent_predators()
			_predator_timer.start()

func _spawn_math_pelican() -> void:
	if is_instance_valid(_math_pelican):
		_math_pelican.queue_free()
	_math_pelican = PELICAN_SCENE.instantiate()
	predator_layer.add_child(_math_pelican)
	_math_pelican.setup(fish_layer)
	_math_pelican.set_process(false)
	_math_pelican.swoop_speed = 0.4
	_math_pelican.position = Vector2(get_viewport_rect().size.x / 2.0, -200.0)

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
		call_deferred("_new_math_round")
	else:
		AudioManager.play_sfx("bite")
		if is_instance_valid(_math_pelican) and not _math_pelican.is_swooping:
			_math_pelican.attack_target(area)
		else:
			area.get_eaten()

func _new_math_round() -> void:
	await get_tree().process_frame
	for fish in fish_layer.get_children():
		fish.queue_free()
	await get_tree().process_frame
	_spawn_math_fish()

func _spawn_fish() -> void:
	while fish_layer.get_child_count() < _max_fish:
		var fish := FISH_SCENE.instantiate()
		fish.fish_class = [Fish.FishClass.LARGE, Fish.FishClass.MEDIUM, Fish.FishClass.SMALL].pick_random()
		fish.difficulty = _difficulty
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

	var distractors := _generate_distractors(problem.answer, 5, problem.distractor_min, problem.distractor_max)
	var numbers: Array = distractors + [problem.answer]
	numbers.shuffle()

	var vp := get_viewport_rect()
	var water_top := 300.0
	var water_bottom := vp.size.y - 50.0
	var slot := (water_bottom - water_top) / 6.0
	var y_slots: Array = []
	for i in 6:
		y_slots.append(water_top + slot * i + slot * 0.5 + randf_range(-8.0, 8.0))
	y_slots.shuffle()

	for i in numbers.size():
		var fish := FISH_SCENE.instantiate()
		fish.fish_class = Fish.FishClass.LARGE
		fish.difficulty = 0
		fish.math_value = numbers[i]
		fish.is_correct = (numbers[i] == problem.answer)
		fish.spawn_y = y_slots[i]
		fish_layer.add_child(fish)

func _generate_math_problem() -> Dictionary:
	match _difficulty:
		0: return _make_problem_easy()
		1: return _make_problem_medium()
		2: return _make_problem_hard()
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
	for p in predator_layer.get_children():
		p.queue_free()
	_math_pelican = null
	if _game_mode == GameMode.MATH:
		var rank := Leaderboard.save_score(_game_mode, _difficulty, _timer_duration, _problems_solved, _problems_solved)
		ui.show_end_screen(_problems_solved, _problems_solved, _difficulty, _timer_duration, rank)
	else:
		var rank := Leaderboard.save_score(_game_mode, _difficulty, _timer_duration, score, fish_caught)
		ui.show_end_screen(score, fish_caught, _difficulty, _timer_duration, rank)

func _on_window_resized() -> void:
	var size = get_viewport_rect().size
	if environment:
		environment.position.y = size.y - 800.0
		_populate_environment()

	var water_area = size.x * (size.y - 250.0)
	if _game_mode == GameMode.MATH:
		_max_fish = 6
	else:
		_max_fish = clamp(int(water_area / 110000.0) + 2, 4, 12)
	_spawn_fish()

	if is_instance_valid(_octopus):
		_octopus.rock_positions = _rock_positions

func _populate_environment() -> void:
	if not environment: return

	for child in environment.get_children():
		child.queue_free()
	_rock_positions.clear()

	var width = get_viewport_rect().size.x

	var sand_count = int(width / 150.0) + 2
	for i in sand_count:
		var s = Sprite2D.new()
		s.texture = SAND_TEX
		s.position = Vector2(i * 150.0 + randf_range(-50, 50), 745 + randf_range(-10, 10))
		s.scale = Vector2(randf_range(0.8, 1.6), randf_range(0.6, 1.3))
		environment.add_child(s)

	var rock_count = int(width / 400.0) + 1
	for i in rock_count:
		var r = Sprite2D.new()
		r.texture = ROCK_TEX
		r.position = Vector2(i * 400.0 + randf_range(50, 350), 750 + randf_range(-5, 15))
		r.scale = Vector2.ONE * randf_range(1.5, 2.5)
		if randf() > 0.5: r.scale.x *= -1
		environment.add_child(r)
		_rock_positions.append(r.position + environment.position)

	var sw_count = int(width / 100.0) + 2
	var sw_textures = [SW_G_TEX, SW_P_TEX, SW_PK_TEX]
	for i in sw_count:
		var sw = Sprite2D.new()
		sw.texture = sw_textures.pick_random()
		sw.position = Vector2(i * 100.0 + randf_range(-30, 30), 740 + randf_range(-10, 15))
		sw.scale = Vector2.ONE * randf_range(0.7, 1.3)
		sw.set_script(SWAY_SCRIPT)
		environment.add_child(sw)

	var clam_count = int(width / 600.0) + 1
	for i in clam_count:
		var c = Sprite2D.new()
		c.position = Vector2(i * 600.0 + randf_range(100, 500), 760)
		c.scale = Vector2.ONE * randf_range(0.8, 1.2)
		c.set_script(CLAM_SCRIPT)
		environment.add_child(c)
