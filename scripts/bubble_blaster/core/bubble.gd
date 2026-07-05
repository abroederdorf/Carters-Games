class_name Bubble
extends Node2D

# color_index → PNG sprite. Indices 0–4 map to the 5 gameplay colors.
# Extra textures (indices 5–9) are available for specials / future use.
const TEXTURES: Array[Texture2D] = [
	preload("res://assets/sprites/bubble_blaster/bubble_red.png"),
	preload("res://assets/sprites/bubble_blaster/bubble_blue.png"),
	preload("res://assets/sprites/bubble_blaster/bubble_green.png"),
	preload("res://assets/sprites/bubble_blaster/bubble_gold.png"),
	preload("res://assets/sprites/bubble_blaster/bubble_purple.png"),
	preload("res://assets/sprites/bubble_blaster/bubble_orange.png"),
	preload("res://assets/sprites/bubble_blaster/bubble_pink.png"),
	preload("res://assets/sprites/bubble_blaster/bubble_light_blue.png"),
	preload("res://assets/sprites/bubble_blaster/bubble_silver.png"),
	preload("res://assets/sprites/bubble_blaster/bubble_rainbow.png"),
]

var color_index: int = 0:
	set(v):
		color_index = v
		_update_texture()

var _sprite: Sprite2D

func _ready() -> void:
	_sprite = Sprite2D.new()
	add_child(_sprite)
	_update_texture()

func _update_texture() -> void:
	if not _sprite:
		return
	var tex: Texture2D = TEXTURES[color_index % TEXTURES.size()]
	_sprite.texture = tex
	# Scale so the sprite fills exactly one BUBBLE_D × BUBBLE_D cell.
	var s := tex.get_size()
	_sprite.scale = Vector2.ONE * (HexGrid.BUBBLE_D / maxf(s.x, s.y))
