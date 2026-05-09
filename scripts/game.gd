extends Node2D

const FISH_SCENE = preload("res://scenes/Fish.tscn")
const MAX_FISH = 5
const CAST_DURATION = 0.5

@onready var fish_layer: Node2D = $FishLayer
@onready var hook: Area2D = $Rod/Hook
@onready var line_2d: Line2D = $Rod/Line2D
@onready var rod: Node2D = $Rod
@onready var ui = $UI

@export var rod_tip_offset: Vector2 = Vector2(120, -10)
@export var water_y_start: float = 350.0

var score: int = 0
var fish_caught: int = 0
var game_active: bool = false
var cast_tween: Tween
var hook_active: bool = false

func _ready() -> void:
	hook.area_entered.connect(_on_hook_area_entered)
	ui.time_up.connect(_on_time_up)
	ui.timer_selected.connect(_start_game)
	_spawn_fish()

func _start_game(duration: float) -> void:
	game_active = true
	score = 0
	fish_caught = 0
	ui.update_score(score, fish_caught)
	ui.start_timer(duration)

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
	hook.monitoring = false
	line_2d.clear_points()

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
		hook_active = true
		hook.monitoring = true
	)

func _redraw_line(start: Vector2, control: Vector2, end: Vector2, t_end: float) -> void:
	line_2d.clear_points()
	for i in 13:
		var t := float(i) / 12.0 * t_end
		line_2d.add_point(rod.to_local(_quadratic_bezier(start, control, end, t)))

func _on_hook_area_entered(area: Area2D) -> void:
	if not hook_active:
		return
	if area.has_method("get_caught"):
		area.get_caught()
		score += area.points
		fish_caught += 1
		ui.update_score(score, fish_caught)
		hook_active = false
		hook.monitoring = false
		line_2d.clear_points()
		_spawn_fish()

func _spawn_fish() -> void:
	while fish_layer.get_child_count() < MAX_FISH:
		var fish := FISH_SCENE.instantiate()
		fish.fish_class = [fish.FishClass.LARGE, fish.FishClass.MEDIUM, fish.FishClass.SMALL].pick_random()
		fish_layer.add_child(fish)
		fish.caught.connect(func() -> void:
			await get_tree().create_timer(0.5).timeout
			if is_instance_valid(self) and game_active:
				_spawn_fish()
		)

func _on_time_up() -> void:
	game_active = false
	hook.monitoring = false
	line_2d.clear_points()
	ui.show_end_screen(score, fish_caught)
