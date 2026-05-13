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

var math_value: int = -1:
	set(v):
		math_value = v
		if is_inside_tree(): _setup_labels()
var is_correct: bool = false
var spawn_y: float = -1.0
var spell_letter: String = "":
	set(v):
		spell_letter = v
		if is_inside_tree(): _setup_labels()
var bounces: bool = false
var _faces_right: bool = false
var water_y: float = 400.0

const CLASS_DATA = {
	FishClass.LARGE:  { "scale": 0.4,  "speed_min": 60.0,  "speed_max": 110.0, "points": 1, "textures": ["res://assets/sprites/fishing/fish_rainbow.png", "res://assets/sprites/fishing/fish_puffer.png", "res://assets/sprites/fishing/fish_angel.png"] },
	FishClass.MEDIUM: { "scale": 0.25, "speed_min": 120.0, "speed_max": 170.0, "points": 2, "textures": ["res://assets/sprites/fishing/fish_beta.png", "res://assets/sprites/fishing/fish_sunfish.png", "res://assets/sprites/fishing/fish_butterfly.png"] },
	FishClass.SMALL:  { "scale": 0.16, "speed_min": 180.0, "speed_max": 250.0, "points": 3, "textures": ["res://assets/sprites/fishing/fish_tetra.png", "res://assets/sprites/fishing/fish_catfish.png", "res://assets/sprites/fishing/fish_sword.png"] },
}

const PLAIN_FISH_TEXTURES: Array[String] = [
	"res://assets/sprites/fishing/fish_plain_green.png",
	"res://assets/sprites/fishing/fish_plain_orange.png",
	"res://assets/sprites/fishing/fish_plain_purple.png",
	"res://assets/sprites/fishing/fish_plain_red.png",
	"res://assets/sprites/fishing/fish_plain_white.png",
	"res://assets/sprites/fishing/fish_plain_yellow.png",
]

# Sprites that face RIGHT by default (need flip_h inverted vs the others)
const FLIPPED_TEXTURES: Array[String] = [
	"res://assets/sprites/fishing/fish_puffer.png",
	"res://assets/sprites/fishing/fish_beta.png",
	"res://assets/sprites/fishing/fish_angel.png",
	"res://assets/sprites/fishing/fish_tetra.png",
	"res://assets/sprites/fishing/fish_plain_green.png",
	"res://assets/sprites/fishing/fish_plain_orange.png",
	"res://assets/sprites/fishing/fish_plain_purple.png",
	"res://assets/sprites/fishing/fish_plain_red.png",
	"res://assets/sprites/fishing/fish_plain_white.png",
	"res://assets/sprites/fishing/fish_plain_yellow.png",
	"res://assets/sprites/fishing/fish_sword.png",
	"res://assets/sprites/fishing/fish_butterfly.png",
]


func _ready() -> void:
	var data: Dictionary = CLASS_DATA[fish_class]
	var base_scale: float = data["scale"]
	points = data["points"]
	speed = randf_range(data["speed_min"], data["speed_max"])

	var tex_path: String
	var is_high_res: bool = false
	
	if math_value != -1 or spell_letter != "":
		tex_path = PLAIN_FISH_TEXTURES.pick_random()
		is_high_res = true
	else:
		tex_path = data["textures"].pick_random()
		# Check if it's one of the new high-res PNGs
		if "fish_sword" in tex_path or "fish_butterfly" in tex_path:
			is_high_res = true
	
	$Sprite2D.texture = load(tex_path)
	
	# High-res PNGs are 10x larger than the old SVGs.
	# We want them to end up at the 'base_scale' size.
	if is_high_res:
		# If the swordfish is too small, 0.1 was too much. 
		# Let's try 0.25 (which is 1/4 the raw PNG size)
		$Sprite2D.scale = Vector2.ONE * 0.25
	else:
		$Sprite2D.scale = Vector2.ONE * 1.0 
	
	# The Area2D itself gets the 'base_scale' (Large: 0.4, Medium: 0.25, Small: 0.16)
	scale = Vector2.ONE * base_scale

	_faces_right = tex_path in FLIPPED_TEXTURES
	direction = 1.0 if randf() > 0.5 else -1.0
	
	var vp := get_viewport_rect()
	var water_start = water_y + 50.0
	var water_end = vp.size.y - 125.0
	position.y = spawn_y if spawn_y >= 0.0 else randf_range(water_start, water_end)
	position.x = -80.0 if direction > 0 else vp.size.x + 80.0
	$Sprite2D.flip_h = (direction > 0) != _faces_right

	if difficulty >= 1:
		velocity_y = randf_range(-60.0, 60.0)
		_change_timer = randf_range(1.0, 2.5)

	_setup_labels()

func _setup_labels() -> void:
	var text_to_show = ""
	if math_value != -1:
		text_to_show = str(math_value)
	elif spell_letter != "":
		text_to_show = spell_letter.to_upper()
	
	if text_to_show == "":
		return

	var label := Label.new()
	label.text = text_to_show
	
	# Large, clear font size
	label.add_theme_font_size_override("font_size", 110)
	label.add_theme_color_override("font_color", Color.BLACK)
	label.add_theme_color_override("font_outline_color", Color.WHITE)
	label.add_theme_constant_override("outline_size", 12)
	
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Size and position
	label.custom_minimum_size = Vector2(200, 150)
	label.position = Vector2(-100, -75)
	
	add_child(label)
	label.z_index = 10
	label.show()

func _process(delta: float) -> void:
	var vp := get_viewport_rect()

	if difficulty >= 1:
		_change_timer -= delta
		if _change_timer <= 0.0:
			_randomize_movement(vp)
			_change_timer = randf_range(1.5, 3.5)

		position.y += velocity_y * delta
		var water_top := water_y + 30.0
		var water_bottom := vp.size.y - 105.0
		if position.y < water_top or position.y > water_bottom:
			velocity_y = -velocity_y
			position.y = clamp(position.y, water_top, water_bottom)

	position.x += speed * direction * delta

	if position.x > vp.size.x + 150.0 or position.x < -150.0:
		if bounces:
			direction = -direction
			$Sprite2D.flip_h = (direction > 0) != _faces_right
			position.x = clamp(position.x, -140.0, vp.size.x + 140.0)
		else:
			caught.emit()
			queue_free()

func _randomize_movement(vp: Rect2) -> void:
	if randf() < 0.35 and position.x > 150.0 and position.x < vp.size.x - 150.0:
		direction = -direction
		$Sprite2D.flip_h = (direction > 0) != _faces_right
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
