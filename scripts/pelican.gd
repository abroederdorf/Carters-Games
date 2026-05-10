extends Sprite2D

@export var fly_speed: float = 150.0
@export var swoop_speed: float = 1.2
@export var swoop_interval: float = 4.0

var direction: float = 1.0
var is_swooping: bool = false
var _swoop_timer: float = 0.0
var _fish_layer: Node2D = null

func _ready() -> void:
	texture = preload("res://assets/sprites/pelican.svg")
	var vp := get_viewport_rect()
	direction = 1.0 if randf() > 0.5 else -1.0
	position.x = -100.0 if direction > 0 else vp.size.x + 100.0
	position.y = 100.0
	flip_h = direction < 0
	_swoop_timer = randf_range(2.0, swoop_interval)

func setup(fish_layer: Node2D) -> void:
	_fish_layer = fish_layer

func _process(delta: float) -> void:
	if is_swooping:
		return
		
	position.x += fly_speed * direction * delta
	
	var vp := get_viewport_rect()
	if (direction > 0 and position.x > vp.size.x + 150.0) or (direction < 0 and position.x < -150.0):
		# Wrap around instead of queue_free to keep it persistent
		position.x = -150.0 if direction > 0 else vp.size.x + 150.0

func trigger_attack() -> bool:
	if is_swooping or not _fish_layer:
		return false
		
	var fishes = _fish_layer.get_children()
	if fishes.is_empty():
		return false
		
	var target = fishes.pick_random()
	_perform_swoop(target)
	return true

func _perform_swoop(target: Node2D) -> void:
	is_swooping = true
	var target_pos = target.global_position
	
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	# Dive
	tween.tween_property(self, "global_position", target_pos, swoop_speed).set_ease(Tween.EASE_IN)
	tween.tween_callback(_on_swoop_hit.bind(target))
	# Recover
	tween.tween_property(self, "global_position", Vector2(target_pos.x + (direction * 200.0), 100.0), swoop_speed * 1.5).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_on_swoop_finished)

func _on_swoop_hit(target) -> void:
	if is_instance_valid(target) and target.has_method("get_eaten"):
		AudioManager.play_sfx("bite")
		target.get_eaten()

func _on_swoop_finished() -> void:
	is_swooping = false
