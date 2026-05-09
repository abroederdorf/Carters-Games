class_name Fish
extends Area2D

signal caught

enum FishClass { LARGE, MEDIUM, SMALL }

var fish_class: FishClass = FishClass.LARGE
var speed: float
var direction: float
var points: int

const CLASS_DATA = {
	FishClass.LARGE:  { "scale": 1.5,  "speed_min": 60.0,  "speed_max": 110.0, "points": 1, "texture": "res://assets/sprites/fish_large.svg" },
	FishClass.MEDIUM: { "scale": 1.0,  "speed_min": 120.0, "speed_max": 170.0, "points": 2, "texture": "res://assets/sprites/fish_medium.svg" },
	FishClass.SMALL:  { "scale": 0.65, "speed_min": 180.0, "speed_max": 250.0, "points": 3, "texture": "res://assets/sprites/fish_small.svg" },
}

func _ready() -> void:
	var data: Dictionary = CLASS_DATA[fish_class]
	scale = Vector2.ONE * data["scale"]
	speed = randf_range(data["speed_min"], data["speed_max"])
	points = data["points"]
	
	$Sprite2D.texture = load(data["texture"])

	direction = 1.0 if randf() > 0.5 else -1.0
	var vp := get_viewport_rect()
	position.y = randf_range(vp.size.y * 0.45, vp.size.y * 0.9)
	position.x = -80.0 if direction > 0 else vp.size.x + 80.0
	$Sprite2D.flip_h = direction < 0

func _process(delta: float) -> void:
	position.x += speed * direction * delta
	var vp := get_viewport_rect()
	if position.x > vp.size.x + 150.0 or position.x < -150.0:
		caught.emit()
		queue_free()

func get_caught() -> void:
	caught.emit()
	set_process(false)
	
	# Pop effect
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", scale * 1.5, 0.1)
	tween.tween_property(self, "modulate:a", 0.0, 0.1)
	tween.chain().tween_callback(queue_free)
