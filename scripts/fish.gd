class_name Fish
extends Area2D

signal caught

enum FishClass { LARGE, MEDIUM, SMALL }

var fish_class: FishClass = FishClass.LARGE
var difficulty: int = 1
var speed: float
var direction: float
var points: int
var velocity_y: float = 0.0
var _change_timer: float = 0.0

const CLASS_DATA = {
	FishClass.LARGE:  { "scale": 1.5,  "speed_min": 60.0,  "speed_max": 110.0, "points": 1, "textures": ["res://assets/sprites/fish_large.svg", "res://assets/sprites/fish_large_2.svg"] },
	FishClass.MEDIUM: { "scale": 1.0,  "speed_min": 120.0, "speed_max": 170.0, "points": 2, "textures": ["res://assets/sprites/fish_medium.svg", "res://assets/sprites/fish_medium_2.svg"] },
	FishClass.SMALL:  { "scale": 0.65, "speed_min": 180.0, "speed_max": 250.0, "points": 3, "textures": ["res://assets/sprites/fish_small.svg", "res://assets/sprites/fish_small_2.svg"] },
}

const SPEED_MULTIPLIER = [0.65, 1.0, 1.0]

func _ready() -> void:
	var data: Dictionary = CLASS_DATA[fish_class]
	scale = Vector2.ONE * data["scale"]
	speed = randf_range(data["speed_min"], data["speed_max"]) * SPEED_MULTIPLIER[difficulty]
	points = data["points"]

	$Sprite2D.texture = load(data["textures"].pick_random())

	direction = 1.0 if randf() > 0.5 else -1.0
	var vp := get_viewport_rect()
	position.y = randf_range(vp.size.y * 0.45, vp.size.y * 0.9)
	position.x = -80.0 if direction > 0 else vp.size.x + 80.0
	$Sprite2D.flip_h = direction > 0

	if difficulty == 2:
		velocity_y = randf_range(-60.0, 60.0)
		_change_timer = randf_range(1.0, 2.5)

func _process(delta: float) -> void:
	var vp := get_viewport_rect()

	if difficulty == 2:
		_change_timer -= delta
		if _change_timer <= 0.0:
			_randomize_movement(vp)
			_change_timer = randf_range(1.5, 3.5)

		position.y += velocity_y * delta
		var water_top := vp.size.y * 0.42
		var water_bottom := vp.size.y * 0.92
		if position.y < water_top or position.y > water_bottom:
			velocity_y = -velocity_y
			position.y = clamp(position.y, water_top, water_bottom)

	position.x += speed * direction * delta

	if position.x > vp.size.x + 150.0 or position.x < -150.0:
		caught.emit()
		queue_free()

func _randomize_movement(vp: Rect2) -> void:
	if randf() < 0.35 and position.x > 150.0 and position.x < vp.size.x - 150.0:
		direction = -direction
		$Sprite2D.flip_h = direction > 0
	velocity_y = randf_range(-80.0, 80.0)
func get_caught() -> void:
	caught.emit()
	set_process(false)

	# Pop effect
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", scale * 1.5, 0.1)
	tween.tween_property(self, "modulate:a", 0.0, 0.1)
	tween.chain().tween_callback(queue_free)

func get_eaten() -> void:
	set_process(false)
	# Shrink effect
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.2)
	tween.tween_property(self, "modulate", Color.RED, 0.1)
	tween.chain().tween_callback(queue_free)

