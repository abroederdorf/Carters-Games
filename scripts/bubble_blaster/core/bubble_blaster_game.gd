extends Node2D

enum State { AIMING, FIRING, RESOLVING }

const BUBBLE_SCENE = preload("res://scenes/bubble_blaster/Bubble.tscn")
const SLINGSHOT_TEX = preload("res://assets/sprites/bubble_blaster/sling_shot.png")

const RIGHT_ANCHOR_X: float = 1920.0
const GRID_TOP_Y: float = 60.0
# Slingshot sits lower-left so kids aim rightward and upward naturally.
const SLINGSHOT_POS: Vector2 = Vector2(130.0, 760.0)
const PROJECTILE_SPEED: float = 1400.0   # px/s
const SUBSTEP_PX: float = HexGrid.BUBBLE_R * 0.5  # 24 px — avoids tunneling through bubbles

@onready var grid_root: Node2D = $GridRoot

var _grid: HexGrid
var cells: Dictionary = {}  # Vector2i(col, row) → color index (int)
var _level_data: BubbleLevelData
var _state: State = State.AIMING

var _slingshot: Sprite2D
var _aim_line: Line2D
var _touch_id: int = -1
var _aim_dir: Vector2 = Vector2.RIGHT

var _projectile: Bubble = null
var _next_color: int = 0  # cycles 0-4; replaced by queue in step 6

func _ready() -> void:
	_grid = HexGrid.new()
	_grid.setup(RIGHT_ANCHOR_X, GRID_TOP_Y)
	_level_data = _make_level_data(1)
	_generate_blob_board(_level_data)
	_spawn_bubble_sprites()
	_build_slingshot()
	_build_aim_line()

# ─── Slingshot + aim line setup ───────────────────────────────────────────────

func _build_slingshot() -> void:
	_slingshot = Sprite2D.new()
	_slingshot.texture = SLINGSHOT_TEX
	var tex_size := _slingshot.texture.get_size()
	_slingshot.scale = Vector2.ONE * (140.0 / maxf(tex_size.x, tex_size.y))
	_slingshot.position = SLINGSHOT_POS
	add_child(_slingshot)

func _build_aim_line() -> void:
	_aim_line = Line2D.new()
	_aim_line.default_color = Color(1, 1, 1, 0.55)
	_aim_line.width = 4.0
	_aim_line.visible = false
	add_child(_aim_line)

# ─── Input ────────────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if _state != State.AIMING:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_id = event.index
			_update_aim(event.position)
		elif event.index == _touch_id:
			_aim_line.visible = false
			_touch_id = -1
			_fire()
	elif event is InputEventScreenDrag and event.index == _touch_id:
		_update_aim(event.position)

func _update_aim(touch_pos: Vector2) -> void:
	var raw := touch_pos - SLINGSHOT_POS
	# Force x > 0 so the shot always travels toward the grid on the right.
	if raw.x < 10.0:
		raw.x = 10.0
	_aim_dir = raw.normalized()
	_aim_line.clear_points()
	_aim_line.add_point(SLINGSHOT_POS)
	_aim_line.add_point(SLINGSHOT_POS + _aim_dir * 400.0)
	_aim_line.visible = true

# ─── Fire ─────────────────────────────────────────────────────────────────────

func _fire() -> void:
	_state = State.FIRING
	_projectile = BUBBLE_SCENE.instantiate()
	_projectile.color_index = _next_color
	_projectile.position = SLINGSHOT_POS
	add_child(_projectile)

# ─── Projectile movement (manual substep, no physics engine) ─────────────────

func _process(delta: float) -> void:
	if _state != State.FIRING or not is_instance_valid(_projectile):
		return
	var travel := PROJECTILE_SPEED * delta
	while travel > 0.0:
		var step := minf(travel, SUBSTEP_PX)
		travel -= step
		_projectile.position += _aim_dir * step
		if _check_hit():
			return

func _check_hit() -> bool:
	var pos := _projectile.position

	# Back wall: projectile reached col 0's x band — snap there.
	if pos.x >= RIGHT_ANCHOR_X - HexGrid.BUBBLE_R:
		var cell := _grid.world_to_grid(pos)
		cell.x = 0
		_snap(cell)
		return true

	# Safety: went off-screen to the left.
	if pos.x < -HexGrid.BUBBLE_R:
		_discard_projectile()
		return true

	# Bubble collision: check every occupied cell.
	for cell: Vector2i in cells:
		if pos.distance_to(_grid.grid_to_world(cell)) < HexGrid.BUBBLE_D:
			var snap_cell := _grid.world_to_grid(pos)
			if cells.has(snap_cell):
				snap_cell = _nearest_empty_neighbor(snap_cell)
			if snap_cell.x >= 0:
				_snap(snap_cell)
			else:
				_discard_projectile()
			return true

	return false

# Fallback when world_to_grid lands on an already-occupied cell.
func _nearest_empty_neighbor(cell: Vector2i) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_dist := INF
	var pos := _projectile.position
	for n in _grid.neighbors(cell):
		if not cells.has(n) and n.x >= 0:
			var d := pos.distance_to(_grid.grid_to_world(n))
			if d < best_dist:
				best_dist = d
				best = n
	return best

func _snap(cell: Vector2i) -> void:
	_state = State.RESOLVING
	cells[cell] = _projectile.color_index
	_projectile.reparent(grid_root)
	_projectile.position = _grid.grid_to_world(cell)
	_projectile = null
	_next_color = (_next_color + 1) % 5
	# Step 4 will insert match/cascade here before returning to AIMING.
	_state = State.AIMING

func _discard_projectile() -> void:
	_projectile.queue_free()
	_projectile = null
	_state = State.AIMING

# ─── Level data factory ───────────────────────────────────────────────────────

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

# ─── Blob board generator ─────────────────────────────────────────────────────

func _generate_blob_board(data: BubbleLevelData) -> void:
	cells.clear()
	var pool: Dictionary = {}
	for col in data.total_cols:
		for row in data.bubbles_per_col:
			pool[Vector2i(col, row)] = true

	var next_color := 0
	while not pool.is_empty():
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

# ─── Sprite spawning ──────────────────────────────────────────────────────────

func _spawn_bubble_sprites() -> void:
	for child in grid_root.get_children():
		child.queue_free()
	for cell: Vector2i in cells:
		var bubble: Bubble = BUBBLE_SCENE.instantiate()
		bubble.color_index = cells[cell]
		bubble.position = _grid.grid_to_world(cell)
		grid_root.add_child(bubble)
