extends Node2D

# Step 2: static grid render.
# Populates cells via blob generator and spawns Bubble sprites at correct hex positions.
# No interactivity — just verifies hex offsets look right before building game logic.

const BUBBLE_SCENE = preload("res://scenes/bubble_blaster/Bubble.tscn")

# Right wall is the right edge of the 1920-wide viewport.
# grid_to_world(col=0) → x = RIGHT_ANCHOR_X - BUBBLE_R = 1920 - 48 = 1872 (right-wall flush).
const RIGHT_ANCHOR_X: float = 1920.0
# origin_y chosen so row-0 even-col center lands at y=108 (comfortable top margin).
const GRID_TOP_Y: float = 60.0

@onready var grid_root: Node2D = $GridRoot

var _grid: HexGrid
var cells: Dictionary = {}  # Vector2i(col, row) → color index (int)
var _level_data: BubbleLevelData

func _ready() -> void:
	_grid = HexGrid.new()
	_grid.setup(RIGHT_ANCHOR_X, GRID_TOP_Y)

	_level_data = _make_level_data(1)  # medium — change to 0 or 2 to test Easy/Hard
	_generate_blob_board(_level_data)
	_spawn_bubble_sprites()

# ─── Level data factory ────────────────────────────────────────────────────────

func _make_level_data(difficulty: int) -> BubbleLevelData:
	var d := BubbleLevelData.new()
	match difficulty:
		0:  # Easy
			d.num_colors = 3
			d.visible_cols = 8
			d.total_cols = 8
			d.bubbles_per_col = 10
			d.blob_size_min = 6
			d.blob_size_max = 8
		1:  # Medium
			d.num_colors = 4
			d.visible_cols = 10
			d.total_cols = 14
			d.bubbles_per_col = 10
			d.blob_size_min = 4
			d.blob_size_max = 6
		2:  # Hard
			d.num_colors = 5
			d.visible_cols = 12
			d.total_cols = 20
			d.bubbles_per_col = 10
			d.blob_size_min = 3
			d.blob_size_max = 4
	return d

# ─── Blob board generator ──────────────────────────────────────────────────────
# Picks a random empty cell, grows a same-color blob of blob_size_min..max into
# adjacent empties, repeats until full. Guarantees every cluster >= blob_size_min.

func _generate_blob_board(data: BubbleLevelData) -> void:
	cells.clear()

	# All valid positions start in the pool.
	var pool: Dictionary = {}
	for col in data.total_cols:
		for row in data.bubbles_per_col:
			pool[Vector2i(col, row)] = true

	var next_color := 0

	while not pool.is_empty():
		# Grab the first available seed cell.
		var start: Vector2i
		for k in pool:
			start = k
			break

		var target_size := randi_range(data.blob_size_min, data.blob_size_max)
		var blob: Array[Vector2i] = []
		var frontier: Array[Vector2i] = [start]

		while blob.size() < target_size and not frontier.is_empty():
			var idx := randi() % frontier.size()
			var curr: Vector2i = frontier[idx]
			frontier.remove_at(idx)
			if not pool.has(curr):
				continue
			blob.append(curr)
			pool.erase(curr)
			if blob.size() < target_size:
				for n in _grid.neighbors(curr):
					if pool.has(n) and not frontier.has(n):
						frontier.append(n)

		for c in blob:
			cells[c] = next_color

		next_color = (next_color + 1) % data.num_colors

# ─── Sprite spawning ───────────────────────────────────────────────────────────

func _spawn_bubble_sprites() -> void:
	for child in grid_root.get_children():
		child.queue_free()

	for cell: Vector2i in cells:
		var bubble: Bubble = BUBBLE_SCENE.instantiate()
		bubble.color_index = cells[cell]
		bubble.position = _grid.grid_to_world(cell)
		grid_root.add_child(bubble)
