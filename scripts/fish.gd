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

var math_value: int = 0
var is_correct: bool = false
var spawn_y: float = -1.0
var spell_letter: String = ""
var bounces: bool = false

const FISH_TEXTURES = [
	"res://assets/sprites/fishing/fish_angel.png",
	"res://assets/sprites/fishing/fish_beta.png",
	"res://assets/sprites/fishing/fish_butterfly.png",
	"res://assets/sprites/fishing/fish_catfish.png",
	"res://assets/sprites/fishing/fish_plain_green.png",
	"res://assets/sprites/fishing/fish_plain_orange.png",
	"res://assets/sprites/fishing/fish_plain_purple.png",
	"res://assets/sprites/fishing/fish_plain_red.png",
	"res://assets/sprites/fishing/fish_plain_white.png",
	"res://assets/sprites/fishing/fish_plain_yellow.png",
	"res://assets/sprites/fishing/fish_puffer.png",
	"res://assets/sprites/fishing/fish_rainbow.png",
	"res://assets/sprites/fishing/fish_sunfish.png",
	"res://assets/sprites/fishing/fish_sword.png",
	"res://assets/sprites/fishing/fish_tetra.png",
]

const CLASS_DATA = {
	FishClass.LARGE:  { "scale": 1.5,  "speed_min": 60.0,  "speed_max": 110.0, "points": 1 },
	FishClass.MEDIUM: { "scale": 1.0,  "speed_min": 120.0, "speed_max": 170.0, "points": 2 },
	FishClass.SMALL:  { "scale": 0.65, "speed_min": 180.0, "speed_max": 250.0, "points": 3 },
}

func _ready() -> void:
	var data: Dictionary = CLASS_DATA[fish_class]
	scale = Vector2.ONE * data["scale"]
	speed = randf_range(data["speed_min"], data["speed_max"])
	points = data["points"]

	$Sprite2D.texture = load(FISH_TEXTURES.pick_random())

	direction = 1.0 if randf() > 0.5 else -1.0
	var vp := get_viewport_rect()
	# Ensure fish stay in the water (starts at 250.0)
	var water_start = 320.0 + 50.0 # Some margin from the top
	var water_end = vp.size.y - 50.0 # Some margin from the bottom
	position.y = spawn_y if spawn_y >= 0.0 else randf_range(water_start, water_end)
	position.x = -80.0 if direction > 0 else vp.size.x + 80.0
	$Sprite2D.flip_h = direction > 0

	if difficulty >= 1:
		velocity_y = randf_range(-60.0, 60.0)
		_change_timer = randf_range(1.0, 2.5)

	if math_value > 0:
		_add_math_label()
	if spell_letter != "":
		_add_spell_label()

func _add_spell_label() -> void:
	var label := Label.new()
	label.text = spell_letter.to_upper()
	label.add_theme_font_size_override("font_size", 32)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 3)
	label.add_theme_constant_override("shadow_offset_y", 3)
	label.size = Vector2(60, 40)
	label.position = Vector2(-30, -20)
	add_child(label)

func _add_math_label() -> void:
	var label := Label.new()
	label.text = str(math_value)
	label.add_theme_font_size_override("font_size", 28)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 3)
	label.add_theme_constant_override("shadow_offset_y", 3)
	label.size = Vector2(80, 40)
	label.position = Vector2(-40, -20)
	add_child(label)

func _process(delta: float) -> void:
	var vp := get_viewport_rect()

	if difficulty >= 1:
		_change_timer -= delta
		if _change_timer <= 0.0:
			_randomize_movement(vp)
			_change_timer = randf_range(1.5, 3.5)

		position.y += velocity_y * delta
		var water_top := 320.0 + 30.0
		var water_bottom := vp.size.y - 30.0
		if position.y < water_top or position.y > water_bottom:
			velocity_y = -velocity_y
			position.y = clamp(position.y, water_top, water_bottom)

	position.x += speed * direction * delta

	if position.x > vp.size.x + 150.0 or position.x < -150.0:
		if bounces:
			direction = -direction
			$Sprite2D.flip_h = direction > 0
			position.x = clamp(position.x, -140.0, vp.size.x + 140.0)
		else:
			caught.emit()
			queue_free()

func _randomize_movement(vp: Rect2) -> void:
	if randf() < 0.35 and position.x > 150.0 and position.x < vp.size.x - 150.0:
		direction = -direction
		$Sprite2D.flip_h = direction > 0
	velocity_y = randf_range(-80.0, 80.0)
func get_caught() -> void:
	AudioManager.play_sfx("pop")
	caught.emit()
	set_process(false)

	# Pop effect
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", scale * 1.5, 0.1)
	tween.tween_property(self, "modulate:a", 0.0, 0.1)
	tween.chain().tween_callback(queue_free)

func get_eaten() -> void:
	AudioManager.play_sfx("pop")
	caught.emit()
	set_process(false)
	# Shrink effect
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.2)
	tween.tween_property(self, "modulate", Color.RED, 0.1)
	tween.chain().tween_callback(queue_free)
