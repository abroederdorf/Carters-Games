extends Area2D

@export var move_interval: float = 8.0
@export var lunge_speed: float = 0.4
var rock_positions: Array[Vector2] = []
var current_rock_index: int = -1
var is_lunging: bool = false
var lunge_cooldown: bool = false
var _fish_layer: Node2D = null

func _ready() -> void:
	$Sprite2D.texture = preload("res://assets/sprites/octopus.svg")
	
	var timer := Timer.new()
	timer.wait_time = move_interval
	timer.autostart = true
	timer.timeout.connect(_scurry_to_next_rock)
	add_child(timer)

func setup(rocks: Array[Vector2], fish_layer: Node2D) -> void:
	rock_positions = rocks
	_fish_layer = fish_layer
	_scurry_to_next_rock()

func _scurry_to_next_rock() -> void:
	if rock_positions.is_empty() or is_lunging:
		return
		
	var next_index = current_rock_index
	while next_index == current_rock_index and rock_positions.size() > 1:
		next_index = randi() % rock_positions.size()
	
	if current_rock_index == -1: # Initial spawn
		global_position = rock_positions[next_index]
		current_rock_index = next_index
	else:
		current_rock_index = next_index
		var tween := create_tween()
		tween.tween_property(self, "global_position", rock_positions[next_index], 1.5).set_trans(Tween.TRANS_SINE)

func trigger_attack() -> bool:
	if is_lunging or lunge_cooldown or not _fish_layer:
		return false
		
	var fishes = _fish_layer.get_children()
	var valid_targets = []
	for f in fishes:
		if global_position.distance_to(f.global_position) < 300.0:
			valid_targets.append(f)
			
	if valid_targets.is_empty():
		return false
		
	_perform_lunge(valid_targets.pick_random())
	return true

func _perform_lunge(target: Area2D) -> void:
	is_lunging = true
	var start_pos = global_position
	var target_pos = target.global_position
	
	var tween := create_tween()
	# Lunge to fish
	tween.tween_property(self, "global_position", target_pos, lunge_speed).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func(): 
		if is_instance_valid(target):
			target.get_eaten()
	)
	# Return to rock
	tween.tween_property(self, "global_position", start_pos, lunge_speed * 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func(): 
		is_lunging = false
		lunge_cooldown = true
		get_tree().create_timer(2.0).timeout.connect(func(): lunge_cooldown = false)
	)
