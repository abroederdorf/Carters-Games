extends Node2D

const FISH_SCENE = preload("res://scenes/Fish.tscn")
const PELICAN_SCENE = preload("res://scenes/Pelican.tscn")
const SHARK_SCENE = preload("res://scenes/Shark.tscn")
const OCTOPUS_SCENE = preload("res://scenes/Octopus.tscn")

const MAX_FISH = 5
const CAST_DURATION = 0.5

@onready var fish_layer: Node2D = $FishLayer
@onready var predator_layer: Node2D = $PredatorLayer
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
var _predator_timer: Timer

func _ready() -> void:
	hook.area_entered.connect(_on_hook_area_entered)
	ui.time_up.connect(_on_time_up)
	ui.difficulty_selected.connect(func(d: int) -> void: _difficulty = d)
	ui.timer_selected.connect(_start_game)
	
	_predator_timer = Timer.new()
	_predator_timer.wait_time = randf_range(8.0, 15.0)
	_predator_timer.timeout.connect(_on_predator_timer_timeout)
	add_child(_predator_timer)
	
	_spawn_fish()

func _start_game(duration: float) -> void:
	game_active = true
	score = 0
	fish_caught = 0
	ui.update_score(score, fish_caught)
	ui.start_timer(duration)
	
	if _difficulty == 2:
		_spawn_octopus()
		_predator_timer.start()

func _on_predator_timer_timeout() -> void:
	if not game_active or _difficulty != 2:
		return
		
	if randf() > 0.5:
		_spawn_pelican()
	else:
		_spawn_shark()
	
	_predator_timer.wait_time = randf_range(10.0, 20.0)
	_predator_timer.start()

func _spawn_pelican() -> void:
	var fishes = fish_layer.get_children()
	if fishes.is_empty():
		return
	var target = fishes.pick_random()
	var pelican = PELICAN_SCENE.instantiate()
	predator_layer.add_child(pelican)
	pelican.start_swoop(target)

func _spawn_shark() -> void:
	var shark = SHARK_SCENE.instantiate()
	predator_layer.add_child(shark)

func _spawn_octopus() -> void:
	var octopus = OCTOPUS_SCENE.instantiate()
	predator_layer.add_child(octopus)
	octopus.setup([Vector2(300, 745), Vector2(950, 755)])

func _on_time_up() -> void:
	game_active = false
	hook.monitoring = false
	line_2d.clear_points()
	_predator_timer.stop()
	# Clear predators
	for p in predator_layer.get_children():
		p.queue_free()
	ui.show_end_screen(score, fish_caught)
