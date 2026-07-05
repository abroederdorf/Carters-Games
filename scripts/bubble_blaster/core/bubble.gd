class_name Bubble
extends Node2D

# Placeholder visuals: solid circle + white highlight ring.
# Replace with TextureRect sprites once art assets are ready.

const PALETTE: Array[Color] = [
	Color(0.90, 0.20, 0.20),  # 0 red
	Color(0.20, 0.50, 0.90),  # 1 blue
	Color(0.20, 0.78, 0.30),  # 2 green
	Color(0.95, 0.80, 0.10),  # 3 yellow
	Color(0.70, 0.20, 0.90),  # 4 purple
]

const RADIUS: float = HexGrid.BUBBLE_R

var color_index: int = 0:
	set(v):
		color_index = v
		queue_redraw()

func _draw() -> void:
	var c: Color = PALETTE[color_index % PALETTE.size()]
	draw_circle(Vector2.ZERO, RADIUS, c)
	# subtle highlight to help distinguish touching bubbles
	draw_arc(Vector2.ZERO, RADIUS - 2.0, 0.0, TAU, 32, Color(1, 1, 1, 0.35), 2.0)
