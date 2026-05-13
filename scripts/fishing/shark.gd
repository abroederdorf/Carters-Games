extends Area2D

@export var patrol_speed: float = 140.0
@export var attack_speed: float = 2.2
@export var attack_interval: float = 5.0

var direction: float = 1.0
var is_attacking: bool = false
var _attack_timer: float = 0.0
var _fish_layer: Node2D = null
var _water_y: float = 400.0

@onready var sprite: Sprite2D = $Sprite2D

var shark_tex := preload("res://assets/sprites/fishing/shark.png")
var fin_tex := preload("res://assets/sprites/fishing/shark_fin.png")

func setup(fish_layer: Node2D) -> void:
	_fish_layer = fish_layer

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	_set_to_fin()
	
	# Determine water level from parent if possible, otherwise default
	if get_parent() and "water_y_start" in get_parent():
		_water_y = get_parent().water_y_start
	
	var vp := get_viewport_rect()
	direction = 1.0 if randf() > 0.5 else -1.0
	position.x = randf_range(200, vp.size.x - 200)
	position.y = _water_y - 95.0 # 150px higher than previous -20.0
	sprite.flip_h = direction > 0
	
	_attack_timer = randf_range(2.0, attack_interval)
	monitoring = false

func _set_to_fin() -> void:
	sprite.texture = fin_tex
	sprite.scale = Vector2.ONE * 0.4
	sprite.modulate.a = 1.0
	sprite.offset.y = 0

func _set_to_shark() -> void:
	sprite.texture = shark_tex
	sprite.scale = Vector2.ONE * 0.54 # 20% bigger than 0.45
	sprite.modulate.a = 1.0
	# Adjust offset if needed to make the shark "head" emerge from the fin's position
	sprite.offset.y = 20

func _process(delta: float) -> void:
	if is_attacking:
		return
		
	position.x += patrol_speed * direction * delta
	
	var vp := get_viewport_rect()
	if position.x > vp.size.x - 100.0:
		direction = -1.0
		sprite.flip_h = false
	elif position.x < 100.0:
		direction = 1.0
		sprite.flip_h = true

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
	var start_pos = global_position

	# Switch to shark and dive
	_set_to_shark()
	sprite.flip_h = target_pos.x > position.x
	monitoring = true

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	
	# Dive down (Lunge)
	tween.tween_property(self, "global_position", target_pos, attack_speed).set_ease(Tween.EASE_IN)
	tween.tween_callback(_on_attack_hit.bind(target))
	
	# Move past/return and sink away
	var exit_pos = Vector2(target_pos.x + (direction * 150.0), target_pos.y + 100.0)
	tween.tween_property(self, "global_position", exit_pos, attack_speed * 0.8).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, attack_speed * 0.8)
	
	tween.tween_callback(_on_attack_finished)

func _on_attack_hit(target) -> void:
	if is_instance_valid(target) and target.has_method("get_eaten"):
		AudioManager.play_sfx("bite")
		target.get_eaten()

func _on_attack_finished() -> void:
	is_attacking = false
	monitoring = false
	# Reposition to surface before becoming fin
	position.y = _water_y - 95.0 # Match the new higher patrol height
	_set_to_fin()
	sprite.flip_h = direction > 0
	
	# Fade fin back in
	sprite.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 1.0, 0.5)

func _on_area_entered(area: Area2D) -> void:
	if is_attacking and area.has_method("get_eaten"):
		AudioManager.play_sfx("bite")
		area.get_eaten()
