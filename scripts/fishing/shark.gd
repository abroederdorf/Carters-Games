extends Area2D

@export var patrol_speed: float = 120.0
@export var attack_speed: float = 1.6
@export var attack_interval: float = 5.0

var direction: float = 1.0
var is_attacking: bool = false
var _attack_timer: float = 0.0
var _fish_layer: Node2D = null

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	sprite.texture = preload("res://assets/sprites/fishing/shark.png")
	sprite.scale = Vector2.ONE * 0.15
	
	var vp := get_viewport_rect()
	direction = 1.0 if randf() > 0.5 else -1.0
	position.x = randf_range(200, vp.size.x - 200)
	position.y = 250.0 # Surface
	sprite.flip_h = direction > 0 # PNG faces left, flip if moving right
	
	_attack_timer = randf_range(2.0, attack_interval)
	monitoring = false

func _process(delta: float) -> void:
	if is_attacking:
		return
		
	position.x += patrol_speed * direction * delta
	
	var vp := get_viewport_rect()
	if position.x > vp.size.x - 100.0:
		direction = -1.0
		sprite.flip_h = false # Face left
	elif position.x < 100.0:
		direction = 1.0
		sprite.flip_h = true # Face right

func trigger_attack() -> bool:
	if is_attacking or not _fish_layer:
		return false
		
	var fishes = _fish_layer.get_children()
	if fishes.is_empty():
		return false
		
	var target = fishes.pick_random()
	_perform_attack(target)
	return true

func _perform_attack(target: Node2D) -> void:
	is_attacking = true
	var target_pos = target.global_position
	
	# Attack state
	sprite.flip_h = direction > 0
	monitoring = true
	
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "global_position", target_pos, attack_speed).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(_on_attack_hit.bind(target))
	# Surface
	tween.tween_property(self, "global_position", Vector2(target_pos.x + (direction * 150.0), 250.0), attack_speed * 1.5)
	tween.tween_callback(_on_attack_finished)

func _on_attack_hit(target) -> void:
	if is_instance_valid(target) and target.has_method("get_eaten"):
		AudioManager.play_sfx("bite")
		target.get_eaten()

func _on_attack_finished() -> void:
	is_attacking = false
	monitoring = false
	sprite.flip_h = direction > 0

func _on_area_entered(area: Area2D) -> void:
	if is_attacking and area.has_method("get_eaten"):
		AudioManager.play_sfx("bite")
		area.get_eaten()
