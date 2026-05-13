extends Sprite2D

const TEX_CLOSED = preload("res://assets/sprites/fishing/clam_closed.png")
const TEX_OPEN = preload("res://assets/sprites/fishing/clam_open.png")

const BUBBLE_TEX = preload("res://assets/sprites/bubble.svg")

@export var open_duration: float = 2.0
@export var closed_duration: float = 4.0

var _is_open: bool = false
var _timer: Timer

func _ready() -> void:
	texture = TEX_CLOSED
	_timer = Timer.new()
	_timer.wait_time = randf_range(1.0, closed_duration)
	_timer.one_shot = true
	_timer.timeout.connect(_toggle_clam)
	add_child(_timer)
	_timer.start()

func _toggle_clam() -> void:
	_is_open = !_is_open
	if _is_open:
		texture = TEX_OPEN
		_timer.wait_time = open_duration
		_spawn_bubbles()
	else:
		texture = TEX_CLOSED
		_timer.wait_time = randf_range(2.0, closed_duration)
	
	_timer.start()

func _spawn_bubbles() -> void:
	var count = randi_range(6, 10)
	for i in count:
		# Wait a random amount of time for each bubble to create a stream effect
		await get_tree().create_timer(randf_range(0.0, 1.0)).timeout
		
		# Double check the clam is still open before spawning the next bubble in the stream
		if not _is_open:
			break
			
		var b = Sprite2D.new()
		b.texture = BUBBLE_TEX
		b.scale = Vector2.ONE * randf_range(0.6, 1.2)
		b.global_position = global_position + Vector2(0, -10)
		get_parent().add_child(b)
		
		var tween = create_tween()
		var target_y = 250.0 + randf_range(-10, 20)
		var drift_x = b.position.x + randf_range(-80, 80)
		
		var distance = b.position.y - target_y
		var duration = distance / randf_range(100.0, 150.0)
		
		tween.set_parallel(true)
		tween.tween_property(b, "position:y", target_y, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tween.tween_property(b, "position:x", drift_x, duration).set_trans(Tween.TRANS_SINE)
		tween.chain().tween_property(b, "modulate:a", 0.0, 0.2)
		tween.tween_callback(b.queue_free)
