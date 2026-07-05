extends Node2D

enum State { AIMING, FIRING, RESOLVING }

const BUBBLE_SCENE = preload("res://scenes/bubble_blaster/Bubble.tscn")
const SLINGSHOT_TEX = preload("res://assets/sprites/bubble_blaster/sling_shot.png")

const RIGHT_ANCHOR_X: float = 1920.0
const GRID_TOP_Y: float = 60.0
const SLINGSHOT_POS: Vector2 = Vector2(130.0, 760.0)
const PROJECTILE_SPEED: float = 1400.0
const SUBSTEP_PX: float = HexGrid.BUBBLE_R * 0.5
const BOUNCE_TOP_Y: float = HexGrid.BUBBLE_R
const BOUNCE_BOT_Y: float = 1080.0 - HexGrid.BUBBLE_R
const MAX_BOUNCES: int = 4

# Queue display layout
const QUEUE_POS: Array[Vector2] = [
	Vector2(90.0, 945.0),   # current bubble (large)
	Vector2(215.0, 968.0),  # next 1 (smaller)
	Vector2(315.0, 968.0),  # next 2 (smaller)
]
const QUEUE_SCALE: Array[float] = [1.0, 0.72, 0.72]
const QUEUE_SWAP_RADIUS: float = HexGrid.BUBBLE_R

# The leftmost x-coordinate a bubble may reach before it's game over.
# Col 20 is roughly x=210 (< 280), so this is only triggered by stacking many missed shots.
const DEATH_LINE_X: float = SLINGSHOT_POS.x + 150.0

@onready var grid_root: Node2D = $GridRoot

var _grid: HexGrid
var cells: Dictionary = {}    # Vector2i → color index (int)
var sprites: Dictionary = {}  # Vector2i → Bubble node
var _level_data: BubbleLevelData
var _state: State = State.AIMING

var _cluster_count: int = 0      # x: distinct same-color clusters at round start (par base)
var _shots_fired: int = 0        # for par rating in step 8
var _next_reserve_col: int = 0   # next hidden column index to reveal

var _slingshot: Sprite2D
var _aim_line: AimLine
var _touch_id: int = -1
var _aim_dir: Vector2 = Vector2.RIGHT

var _projectile: Bubble = null
var _proj_vel: Vector2 = Vector2.RIGHT  # live direction during flight (may bounce)
var _proj_bounces: int = 0

# Bubble queue: queue[0] fires next; visual hopper shows first 3.
var _queue: Array[int] = []
var _queue_display: Array[Bubble] = []
var _ammo_total: int = 0    # 2 × cluster_count; refills add to this (step 8)
var _shots_total_gen: int = 0  # total bubbles ever generated into the queue

func _ready() -> void:
	_grid = HexGrid.new()
	_grid.setup(RIGHT_ANCHOR_X, GRID_TOP_Y)
	_level_data = _make_level_data(1)
	_generate_blob_board(_level_data)
	_compute_cluster_count()
	_next_reserve_col = _level_data.visible_cols
	_spawn_bubble_sprites()
	_build_slingshot()
	_build_aim_line()
	_init_queue()
	_build_queue_display()

# ─── Slingshot + aim line ─────────────────────────────────────────────────────

func _build_slingshot() -> void:
	_slingshot = Sprite2D.new()
	_slingshot.texture = SLINGSHOT_TEX
	var tex_size := _slingshot.texture.get_size()
	_slingshot.scale = Vector2.ONE * (140.0 / maxf(tex_size.x, tex_size.y))
	_slingshot.position = SLINGSHOT_POS
	add_child(_slingshot)

func _build_aim_line() -> void:
	_aim_line = AimLine.new()
	_aim_line.visible = false
	add_child(_aim_line)

# ─── Bubble queue ─────────────────────────────────────────────────────────────

func _init_queue() -> void:
	_ammo_total = 2 * _cluster_count
	_queue.clear()
	_shots_total_gen = mini(3, _ammo_total)
	for _i in _shots_total_gen:
		_queue.append(_weighted_color())

func _build_queue_display() -> void:
	_queue_display.clear()
	for _i in 3:
		var b: Bubble = BUBBLE_SCENE.instantiate()
		b.visible = false
		add_child(b)
		_queue_display.append(b)
	_update_queue_display()

func _update_queue_display() -> void:
	for i in 3:
		var node: Bubble = _queue_display[i]
		if i < _queue.size():
			node.color_index = _queue[i]
			node.position = QUEUE_POS[i]
			node.scale = Vector2.ONE * QUEUE_SCALE[i]
			node.visible = true
		else:
			node.visible = false

# Returns a color index weighted proportionally to colors remaining on the board.
func _weighted_color() -> int:
	if cells.is_empty():
		return randi() % _level_data.num_colors
	var pool: Array[int] = cells.values()
	return pool[randi() % pool.size()]

# Returns true if touch_pos hit a swappable preview slot and the swap was done.
func _try_swap(touch_pos: Vector2) -> bool:
	for i in range(1, QUEUE_POS.size()):
		if touch_pos.distance_to(QUEUE_POS[i]) < QUEUE_SWAP_RADIUS and i < _queue.size():
			var tmp := _queue[0]
			_queue[0] = _queue[i]
			_queue[i] = tmp
			_update_queue_display()
			return true
	return false

# ─── Input ────────────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if _state != State.AIMING:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			if _try_swap(event.position):
				return
			_touch_id = event.index
			_update_aim(event.position)
		elif event.index == _touch_id:
			_aim_line.hide_path()
			_touch_id = -1
			_fire()
	elif event is InputEventScreenDrag and event.index == _touch_id:
		_update_aim(event.position)

func _update_aim(touch_pos: Vector2) -> void:
	var raw := touch_pos - SLINGSHOT_POS
	if raw.x < 10.0:
		raw.x = 10.0
	_aim_dir = raw.normalized()
	var result := HexGrid.march_ray(
		SLINGSHOT_POS, _aim_dir,
		BOUNCE_TOP_Y, BOUNCE_BOT_Y, RIGHT_ANCHOR_X,
		MAX_BOUNCES, SUBSTEP_PX,
		cells, _grid
	)
	var has_snap: bool = result["snap_cell"] != Vector2i(-1, -1)
	_aim_line.show_path(result["waypoints"], result["snap_world"], has_snap)

# ─── Fire ─────────────────────────────────────────────────────────────────────

func _fire() -> void:
	if _queue.is_empty():
		return
	_state = State.FIRING
	_proj_vel = _aim_dir
	_proj_bounces = 0
	_projectile = BUBBLE_SCENE.instantiate()
	_projectile.color_index = _queue[0]
	_projectile.position = SLINGSHOT_POS
	add_child(_projectile)

# ─── Projectile movement ──────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if _state != State.FIRING or not is_instance_valid(_projectile):
		return
	var travel := PROJECTILE_SPEED * delta
	while travel > 0.0:
		var step := minf(travel, SUBSTEP_PX)
		travel -= step
		_projectile.position += _proj_vel * step
		_apply_bounce()
		if _check_hit():
			return

func _apply_bounce() -> void:
	if _proj_bounces >= MAX_BOUNCES:
		return
	var pos := _projectile.position
	if pos.y < BOUNCE_TOP_Y:
		_projectile.position.y = 2.0 * BOUNCE_TOP_Y - pos.y
		_proj_vel.y = absf(_proj_vel.y)
		_proj_bounces += 1
	elif pos.y > BOUNCE_BOT_Y:
		_projectile.position.y = 2.0 * BOUNCE_BOT_Y - pos.y
		_proj_vel.y = -absf(_proj_vel.y)
		_proj_bounces += 1

func _check_hit() -> bool:
	var pos := _projectile.position

	if pos.x >= RIGHT_ANCHOR_X - HexGrid.BUBBLE_R:
		var cell := _grid.world_to_grid(pos)
		cell.x = 0
		_snap(cell)
		return true

	if pos.x < -HexGrid.BUBBLE_R:
		_discard_projectile()
		return true

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
	sprites[cell] = _projectile
	_projectile = null
	_shots_fired += 1
	_queue.pop_front()
	if _shots_total_gen < _ammo_total:
		_queue.append(_weighted_color())
		_shots_total_gen += 1
	_update_queue_display()
	await _resolve(cell)
	_check_column_reveal()
	if _check_death_line():
		_on_game_over()
		return
	if _queue.is_empty():
		_on_out_of_ammo()
	else:
		_state = State.AIMING

func _discard_projectile() -> void:
	_projectile.queue_free()
	_projectile = null
	_state = State.AIMING

# ─── Match + cascade (step 4) ─────────────────────────────────────────────────

func _resolve(landed: Vector2i) -> void:
	# A. Same-color match from the landed cell.
	var group := _bfs_same_color(landed)
	if group.size() < 3:
		return  # no match — stay as-is

	# Pop animation: shrink + fade all matched bubbles in parallel.
	var pop_tween := create_tween().set_parallel(true)
	for cell in group:
		var s: Bubble = sprites.get(cell)
		if s:
			pop_tween.tween_property(s, "scale", Vector2.ZERO, 0.22)
			pop_tween.tween_property(s, "modulate:a", 0.0, 0.18)
	await pop_tween.finished

	for cell in group:
		cells.erase(cell)
		var s: Bubble = sprites.get(cell)
		if s:
			s.queue_free()
		sprites.erase(cell)

	# B. Floating drop: any cell not reachable from col 0 falls.
	var floating := _find_floating()
	if not floating.is_empty():
		var drop_tween := create_tween().set_parallel(true)
		for cell in floating:
			var s: Bubble = sprites.get(cell)
			if s:
				drop_tween.tween_property(s, "position:y", s.position.y + 700.0, 0.45)
				drop_tween.tween_property(s, "modulate:a", 0.0, 0.35)
		await drop_tween.finished

		for cell in floating:
			cells.erase(cell)
			var s: Bubble = sprites.get(cell)
			if s:
				s.queue_free()
			sprites.erase(cell)

	# Win check.
	if cells.is_empty():
		_on_win()

# BFS: collect all cells connected to `start` that share its color.
func _bfs_same_color(start: Vector2i) -> Array[Vector2i]:
	var color: int = cells.get(start, -1)
	var visited: Dictionary = {}
	var queue: Array[Vector2i] = [start]
	visited[start] = true
	var group: Array[Vector2i] = []
	while not queue.is_empty():
		var curr: Vector2i = queue.pop_front()
		group.append(curr)
		for n in _grid.neighbors(curr):
			if not visited.has(n) and cells.get(n, -1) == color:
				visited[n] = true
				queue.append(n)
	return group

# BFS from col 0 anchor; returns cells NOT reachable (floating).
func _find_floating() -> Array[Vector2i]:
	var reachable: Dictionary = {}
	var queue: Array[Vector2i] = []
	for cell: Vector2i in cells:
		if cell.x == 0 and not reachable.has(cell):
			reachable[cell] = true
			queue.append(cell)
	while not queue.is_empty():
		var curr: Vector2i = queue.pop_front()
		for n in _grid.neighbors(curr):
			if not reachable.has(n) and cells.has(n):
				reachable[n] = true
				queue.append(n)
	var floating: Array[Vector2i] = []
	for cell: Vector2i in cells:
		if not reachable.has(cell):
			floating.append(cell)
	return floating

# Connected-components pass at round start to compute x (par base).
func _compute_cluster_count() -> void:
	var visited: Dictionary = {}
	_cluster_count = 0
	for cell: Vector2i in cells:
		if visited.has(cell):
			continue
		var color: int = cells[cell]
		var queue: Array[Vector2i] = [cell]
		visited[cell] = true
		while not queue.is_empty():
			var curr: Vector2i = queue.pop_front()
			for n in _grid.neighbors(curr):
				if not visited.has(n) and cells.get(n, -1) == color:
					visited[n] = true
					queue.append(n)
		_cluster_count += 1

func _on_win() -> void:
	# Placeholder — step 8 adds the overlay and star calculation.
	print("Level cleared! shots=%d  clusters=%d" % [_shots_fired, _cluster_count])

func _on_out_of_ammo() -> void:
	# Placeholder — step 8 adds the refill modal.
	print("Out of ammo! shots=%d" % _shots_fired)

func _on_game_over() -> void:
	# Placeholder — step 8 adds the game-over overlay.
	print("Game over! shots=%d" % _shots_fired)

# ─── Column reveal + death line (step 7) ─────────────────────────────────────

# If the leftmost visible column is now clear, animate the next reserve column in.
func _check_column_reveal() -> void:
	if _next_reserve_col >= _level_data.total_cols:
		return
	var leftmost := _next_reserve_col - 1
	for cell: Vector2i in cells:
		if cell.x == leftmost:
			return  # still occupied
	_reveal_column(_next_reserve_col)
	_next_reserve_col += 1

func _reveal_column(col: int) -> void:
	var tween := create_tween().set_parallel(true)
	for cell: Vector2i in cells:
		if cell.x != col:
			continue
		var sprite: Bubble = sprites.get(cell)
		if not sprite or sprite.visible:
			continue
		var target_x := sprite.position.x
		sprite.position.x = target_x - 240.0  # start just off-screen to the left
		sprite.visible = true
		tween.tween_property(sprite, "position:x", target_x, 0.45)

# Returns true when any bubble has crossed the death line (game over).
func _check_death_line() -> bool:
	for cell: Vector2i in cells:
		if _grid.grid_to_world(cell).x < DEATH_LINE_X:
			return true
	return false

# ─── Level data factory ───────────────────────────────────────────────────────

func _make_level_data(difficulty: int) -> BubbleLevelData:
	var d := BubbleLevelData.new()
	match difficulty:
		0:
			d.num_colors = 3
			d.visible_cols = 8
			d.total_cols = 8
			d.bubbles_per_col = 10
			d.blob_size_min = 6
			d.blob_size_max = 8
		1:
			d.num_colors = 4
			d.visible_cols = 10
			d.total_cols = 14
			d.bubbles_per_col = 10
			d.blob_size_min = 4
			d.blob_size_max = 6
		2:
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
	sprites.clear()
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
	sprites.clear()
	for cell: Vector2i in cells:
		var bubble: Bubble = BUBBLE_SCENE.instantiate()
		bubble.color_index = cells[cell]
		bubble.position = _grid.grid_to_world(cell)
		bubble.visible = cell.x < _next_reserve_col
		grid_root.add_child(bubble)
		sprites[cell] = bubble
