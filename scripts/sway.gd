extends Sprite2D

@export var sway_speed: float = 1.0
@export var sway_amount: float = 0.1
var random_offset: float = 0.0

func _ready() -> void:
	random_offset = randf() * PI * 2.0
	# Set pivot to bottom center for better swaying
	centered = true
	if texture:
		offset.y = -texture.get_height() / 2.0

func _process(delta: float) -> void:
	rotation = sin(Time.get_ticks_msec() * 0.001 * sway_speed + random_offset) * sway_amount
