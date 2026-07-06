extends Node2D

enum State { AIMING, FIRING, RESOLVING, OVERLAY }

const BUBBLE_SCENE = preload("res://scenes/bubble_blaster/Bubble.tscn")
const SLINGSHOT_TEX = preload("res://assets/sprites/bubble_blaster/sling_shot.png")
const BTN_HOME_TEX = preload("res://assets/sprites/ui/button_home.png")
const BTN_NEXT_TEX = preload("res://assets/sprites/ui/button_next.png")

const RIGHT_ANCHOR_X: float = 1920.0
const GRID_TOP_Y: float = 60.0
const SLINGSHOT_POS: Vector2 = Vector2(280.0, 760.0)
const PROJECTILE_SPEED: float = 1400.0
const SUBSTEP_PX: float = HexGrid.BUBBLE_R * 0.5
const BOUNCE_TOP_Y: float = HexGrid.BUBBLE_R
const BOUNCE_BOT_Y: float = 1080.0 - HexGrid.BUBBLE_R
const MAX_BOUNCES: int = 4

# Current (loaded) ball — sits between the slingshot prong tips.
# Prong tip world positions derived from the 2048×2048 sprite at scale 140/2048.
const QUEUE_POS_CURRENT: Vector2 = SLINGSHOT_POS + Vector2(0.0, -114.0)
const QUEUE_SCALE_CURRENT: float = 1.0
const SLING_PRONG_L: Vector2 = SLINGSHOT_POS + Vector2(-111.0, -183.0)
const SLING_PRONG_R: Vector2 = SLINGSHOT_POS + Vector2(111.0, -183.0)

# Hopper row: next N balls displayed below the slingshot.
const HOPPER_Y: float = 965.0
const HOPPER_X_START: float = 52.0
const HOPPER_SPACING: float = 58.0
const HOPPER_SCALE: float = 0.52
const HOPPER_MAX: int = 10
const QUEUE_SWAP_RADIUS: float = HexGrid.BUBBLE_R * 0.7

const EMPTY_COLS: int = 6  # open columns between visible grid and death line

@onready var grid_root: Node2D = $GridRoot
@onready var _bbs := get_node("/root/BubbleBlasterState")

var _grid: HexGrid
var cells: Dictionary = {}    # Vector2i → color index (int)
var sprites: Dictionary = {}  # Vector2i → Bubble node
var _level_data: BubbleLevelData
var _state: State = State.AIMING

var _cluster_count: int = 0      # x: distinct same-color clusters at round start (par base)
var _shots_fired: int = 0
var _death_line_x: float = 0.0  # computed per difficulty; 6 empty cols left of visible grid

# Reserve columns hidden to the right, queued as {row→color} dicts, pop front on scroll.
var _reserve_queue: Array = []
var _reserve_queue_snapshot: Array = []

var _cells_snapshot: Dictionary = {}  # saved at round start for retry
var _ui: BubbleBlasterUI

var _slingshot: Sprite2D
var _band_l: Line2D
var _band_r: Line2D
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

var _tutorial_active: bool = false
var _tutorial_hud: CanvasLayer = null
var _tut_phase: int = 0  # 0 = swap hint, 1 = aim hint
var _tut_hint_visible: bool = true
var _tut_ring_scale: float = 1.0
var _tut_ring_tween: Tween = null
var _tut_arrow: Line2D = null
var _tut_arrowhead: Polygon2D = null

func _ready() -> void:
	_grid = HexGrid.new()
	_grid.setup(RIGHT_ANCHOR_X, GRID_TOP_Y)
	_level_data = _make_level_data(_bbs.current_difficulty)
	_generate_blob_board(_level_data)
	_cells_snapshot = cells.duplicate(false)
	_reserve_queue_snapshot = _copy_reserve_queue(_reserve_queue)
	_compute_cluster_count()
	_death_line_x = RIGHT_ANCHOR_X - (_level_data.visible_cols + EMPTY_COLS) * HexGrid.COL_W - HexGrid.BUBBLE_R
	_spawn_bubble_sprites()
	_build_slingshot()
	_build_aim_line()
	_init_queue()
	_build_queue_display()
	_build_ui()
	if not _bbs.tutorial_seen:
		_start_tutorial()
	queue_redraw()

# ─── Slingshot + aim line ─────────────────────────────────────────────────────

func _build_slingshot() -> void:
	_slingshot = Sprite2D.new()
	_slingshot.texture = SLINGSHOT_TEX
	var tex_size := _slingshot.texture.get_size()
	_slingshot.scale = Vector2.ONE * (420.0 / maxf(tex_size.x, tex_size.y))
	_slingshot.position = SLINGSHOT_POS
	add_child(_slingshot)

	# Rubber bands — drawn on top of slingshot, behind the bubble.
	for band_pts: Array in [[SLING_PRONG_L], [SLING_PRONG_R]]:
		var band := Line2D.new()
		band.default_color = Color(0.95, 0.40, 0.65, 1.0)
		band.width = 18.0
		band.end_cap_mode = Line2D.LINE_CAP_ROUND
		band.begin_cap_mode = Line2D.LINE_CAP_ROUND
		band.visible = false
		band.add_point(band_pts[0])
		band.add_point(QUEUE_POS_CURRENT)
		add_child(band)
		if _band_l == null:
			_band_l = band
		else:
			_band_r = band

func _build_aim_line() -> void:
	_aim_line = AimLine.new()
	_aim_line.visible = false
	add_child(_aim_line)

# ─── Bubble queue ─────────────────────────────────────────────────────────────

func _init_queue() -> void:
	_ammo_total = 2 * _cluster_count
	_queue.clear()
	var initial := mini(HOPPER_MAX + 1, _ammo_total)
	_shots_total_gen = initial
	for _i in initial:
		_queue.append(_weighted_color())

func _build_queue_display() -> void:
	_queue_display.clear()
	# Index 0 = current (loaded) bubble at slingshot; indices 1..HOPPER_MAX = hopper row.
	for _i in HOPPER_MAX + 1:
		var b: Bubble = BUBBLE_SCENE.instantiate()
		b.visible = false
		add_child(b)
		_queue_display.append(b)
	_update_queue_display()

func _update_queue_display() -> void:
	# Current ball — sits loaded in the slingshot fork.
	var cur: Bubble = _queue_display[0]
	if not _queue.is_empty():
		cur.color_index = _queue[0]
		cur.position = QUEUE_POS_CURRENT
		cur.scale = Vector2.ONE * QUEUE_SCALE_CURRENT
		cur.z_index = 1  # draw on top of bands
		cur.visible = true
	else:
		cur.visible = false

	# Hopper row — next balls queued up below.
	for i in HOPPER_MAX:
		var node: Bubble = _queue_display[i + 1]
		var qi := i + 1
		if qi < _queue.size():
			node.color_index = _queue[qi]
			node.position = Vector2(HOPPER_X_START + i * HOPPER_SPACING, HOPPER_Y)
			node.scale = Vector2.ONE * HOPPER_SCALE
			node.visible = true
		else:
			node.visible = false

func _weighted_color() -> int:
	if cells.is_empty():
		return randi() % _level_data.num_colors
	var vals := cells.values()
	return vals[randi() % vals.size()]

# Returns true if touch_pos hit a hopper bubble and the swap was done.
func _try_swap(touch_pos: Vector2) -> bool:
	for i in mini(2, _queue.size() - 1):  # only the next 2 hopper balls are swappable
		var hpos := Vector2(HOPPER_X_START + i * HOPPER_SPACING, HOPPER_Y)
		if touch_pos.distance_to(hpos) < QUEUE_SWAP_RADIUS:
			var qi := i + 1
			var tmp := _queue[0]
			_queue[0] = _queue[qi]
			_queue[qi] = tmp
			_update_queue_display()
			return true
	return false

# ─── UI overlay ───────────────────────────────────────────────────────────────

func _build_ui() -> void:
	_ui = BubbleBlasterUI.new()
	add_child(_ui)
	_ui.retry_same.connect(_on_retry_same)
	_ui.new_game.connect(_on_new_game)
	_ui.refill_requested.connect(_on_refill)
	_ui.go_home.connect(_on_go_difficulty_select)

	# Persistent home button (top-left corner, always visible during play)
	var hud := CanvasLayer.new()
	hud.layer = 5
	add_child(hud)
	var home_btn := Button.new()
	home_btn.flat = true
	home_btn.expand_icon = true
	home_btn.focus_mode = Control.FOCUS_NONE
	home_btn.icon = BTN_HOME_TEX
	home_btn.anchors_preset = Control.PRESET_TOP_LEFT
	home_btn.custom_minimum_size = Vector2(80, 80)
	home_btn.offset_left = 12
	home_btn.offset_top = 12
	home_btn.offset_right = 92
	home_btn.offset_bottom = 92
	home_btn.pressed.connect(_on_go_home)
	hud.add_child(home_btn)

func _calc_stars() -> int:
	if _shots_fired * 4 <= _cluster_count * 3:  # ≤ 0.75x
		return 3
	elif _shots_fired <= _cluster_count:         # ≤ x
		return 2
	return 1

# ─── Hopper tray background ───────────────────────────────────────────────────

func _draw() -> void:
	const PAD_X := 32.0
	const PAD_Y := 38.0

	var tray_left := HOPPER_X_START - PAD_X
	var tray_top := HOPPER_Y - PAD_Y
	var tray_w := (HOPPER_MAX - 1) * HOPPER_SPACING + PAD_X * 2.0
	var tray_h := PAD_Y * 2.0

	# Full tray background — dark panel behind all 10 queue slots.
	draw_rect(Rect2(tray_left, tray_top, tray_w, tray_h), Color(0.04, 0.04, 0.20, 0.85))

	# Swap-zone highlight (amber-yellow) — first 2 hopper slots are the only swappable picks.
	# Divider sits halfway between ball[1] and ball[2] centres.
	var swap_w := PAD_X + HOPPER_SPACING * 1.5  # ends between slot 2 and slot 3
	draw_rect(Rect2(tray_left, tray_top, swap_w, tray_h), Color(0.95, 0.78, 0.05, 0.72))

	# Vertical divider line.
	var div_x := tray_left + swap_w
	draw_line(
		Vector2(div_x, tray_top + 5.0),
		Vector2(div_x, tray_top + tray_h - 5.0),
		Color(1.0, 1.0, 1.0, 0.80),
		3.0
	)

	# Danger zone — dashed red vertical line showing how far left bubbles can reach.
	if _death_line_x > 0.0:
		draw_dashed_line(
			Vector2(_death_line_x, GRID_TOP_Y),
			Vector2(_death_line_x, tray_top),
			Color(0.95, 0.15, 0.15, 0.65),
			4.0, 22.0
		)

	if _tutorial_active and _tut_hint_visible:
		if _tut_phase == 0:
			# Phase 0: ring around the red bubble in the hopper (second slot — tap to swap).
			var hopper_red_pos := Vector2(HOPPER_X_START + HOPPER_SPACING, HOPPER_Y)
			var r := HexGrid.BUBBLE_R * HOPPER_SCALE * _tut_ring_scale
			draw_arc(hopper_red_pos, r, 0.0, TAU, 48, Color(1.0, 0.95, 0.1, 0.9), 5.0)
		else:
			# Phase 1: ring around the loaded slingshot bubble.
			var r := HexGrid.BUBBLE_R * 2.0 * _tut_ring_scale
			draw_arc(QUEUE_POS_CURRENT, r, 0.0, TAU, 64, Color(1.0, 0.95, 0.1, 0.9), 6.0)

# ─── Input ────────────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if _state != State.AIMING:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			if _try_swap(event.position):
				if _tutorial_active and _tut_phase == 0:
					_advance_to_aim_hint()
				return
			_touch_id = event.index
			_update_aim(event.position)
		elif event.index == _touch_id:
			_aim_line.hide_path()
			_band_l.visible = false
			_band_r.visible = false
			_queue_display[0].position = QUEUE_POS_CURRENT
			_touch_id = -1
			_fire()
	elif event is InputEventScreenDrag and event.index == _touch_id:
		_update_aim(event.position)

func _update_aim(touch_pos: Vector2) -> void:
	if _tutorial_active:
		_hide_tutorial_hint()
	var raw := touch_pos - QUEUE_POS_CURRENT
	if raw.x < 10.0:
		raw.x = 10.0
	_aim_dir = raw.normalized()
	var result := HexGrid.march_ray(
		QUEUE_POS_CURRENT, _aim_dir,
		BOUNCE_TOP_Y, BOUNCE_BOT_Y, RIGHT_ANCHOR_X,
		MAX_BOUNCES, SUBSTEP_PX,
		cells, _grid
	)
	var has_snap: bool = result["snap_cell"] != Vector2i(-1, -1)
	_aim_line.show_path(result["waypoints"], result["snap_world"], has_snap)

	# Rubber bands — stretch from prong tips to the loaded-ball position.
	# A small pull-back offset (opposite to aim) adds a tension feel.
	var ball_pos := QUEUE_POS_CURRENT - _aim_dir * 20.0
	_band_l.set_point_position(1, ball_pos)
	_band_r.set_point_position(1, ball_pos)
	_band_l.visible = true
	_band_r.visible = true
	# Keep the loaded bubble in sync with the slight pull-back.
	_queue_display[0].position = ball_pos

# ─── Fire ─────────────────────────────────────────────────────────────────────

func _fire() -> void:
	if _queue.is_empty():
		return
	_state = State.FIRING
	_proj_vel = _aim_dir
	_proj_bounces = 0
	_projectile = BUBBLE_SCENE.instantiate()
	_projectile.color_index = _queue[0]
	_projectile.position = QUEUE_POS_CURRENT
	add_child(_projectile)

# ─── Projectile movement ──────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if _tutorial_active and _tut_hint_visible:
		queue_redraw()
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

	# Find the closest bubble within collision range.
	var hit_cell := Vector2i(-1, -1)
	var hit_dist := INF
	for cell: Vector2i in cells:
		var d := pos.distance_to(_grid.grid_to_world(cell))
		if d < HexGrid.BUBBLE_D and d < hit_dist:
			hit_dist = d
			hit_cell = cell

	if hit_cell == Vector2i(-1, -1):
		return false

	# Attach to the closest empty neighbour of the bubble we actually touched.
	var snap_cell := _nearest_empty_neighbor(hit_cell)
	if snap_cell.x >= 0:
		_snap(snap_cell)
	else:
		_discard_projectile()
	return true

func _nearest_empty_neighbor(cell: Vector2i) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_dist := INF
	var pos := _projectile.position
	for n in _grid.neighbors(cell):
		if not cells.has(n) and n.x >= 0 and n.y >= 0:
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
	while _shots_total_gen < _ammo_total and _queue.size() < HOPPER_MAX + 1:
		_queue.append(_weighted_color())
		_shots_total_gen += 1
	_update_queue_display()
	await _resolve(cell)
	if _state == State.OVERLAY:  # win was triggered inside _resolve
		return
	await _check_scroll()
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
	_state = State.OVERLAY
	if _tutorial_active:
		_complete_tutorial()
		return
	var stars := _calc_stars()
	_bbs.earn_stars(stars)
	_bbs.record_win(_bbs.current_difficulty)
	_ui.show_win(stars, _bbs.star_bank)

func _on_out_of_ammo() -> void:
	_state = State.OVERLAY
	var refill_amt := _cluster_count
	_ui.show_out_of_ammo(_bbs.star_bank, refill_amt)

func _on_game_over() -> void:
	_state = State.OVERLAY
	_ui.show_game_over()

# ─── Overlay callbacks ────────────────────────────────────────────────────────

func _on_retry_same() -> void:
	cells = _cells_snapshot.duplicate(false)
	_reserve_queue = _copy_reserve_queue(_reserve_queue_snapshot)
	_compute_cluster_count()
	_shots_fired = 0
	_spawn_bubble_sprites()
	_init_queue()
	_update_queue_display()
	_state = State.AIMING

func _on_new_game() -> void:
	_generate_blob_board(_level_data)
	_cells_snapshot = cells.duplicate(false)
	_reserve_queue_snapshot = _copy_reserve_queue(_reserve_queue)
	_compute_cluster_count()
	_shots_fired = 0
	_spawn_bubble_sprites()
	_init_queue()
	_update_queue_display()
	_state = State.AIMING

func _on_refill() -> void:
	if _bbs.spend_star():
		_ammo_total += _cluster_count
		while _shots_total_gen < _ammo_total and _queue.size() < HOPPER_MAX + 1:
			_queue.append(_weighted_color())
			_shots_total_gen += 1
		_update_queue_display()
		_state = State.AIMING

func _on_go_home() -> void:
	get_tree().change_scene_to_file("res://scenes/bubble_blaster/BubbleBlasterMain.tscn")

func _on_go_difficulty_select() -> void:
	get_tree().change_scene_to_file("res://scenes/bubble_blaster/BubbleBlasterMain.tscn")

# ─── Scroll + death line ──────────────────────────────────────────────────────

# Scroll the grid left if leftmost visible col AND extended zone are fully cleared.
# Each scroll shifts all bubbles left one column-width and pops a reserve column from
# the right. Multiple consecutive empty cols are handled in one batched scroll.
func _check_scroll() -> void:
	if _reserve_queue.is_empty():
		return
	var left_col := _level_data.visible_cols - 1
	# Extended zone (left of visible window) must be clear.
	for cell: Vector2i in cells:
		if cell.x > left_col:
			return
	# Count consecutive empty cols from leftmost visible rightward.
	var scroll_count := 0
	for i in mini(_reserve_queue.size(), _level_data.visible_cols):
		var col_check := left_col - i
		var occupied := false
		for cell: Vector2i in cells:
			if cell.x == col_check:
				occupied = true
				break
		if occupied:
			break
		scroll_count += 1
	if scroll_count > 0:
		await _do_scroll(scroll_count)

func _do_scroll(count: int) -> void:
	# Re-index all current cells/sprites: col += count (shift left in world).
	var new_cells: Dictionary = {}
	var new_sprites: Dictionary = {}
	for cell: Vector2i in cells:
		new_cells[Vector2i(cell.x + count, cell.y)] = cells[cell]
	for cell: Vector2i in sprites:
		new_sprites[Vector2i(cell.x + count, cell.y)] = sprites[cell]
	cells = new_cells
	sprites = new_sprites

	# Animate existing sprites sliding left.
	var tween := create_tween().set_parallel(true)
	for nc: Vector2i in sprites:
		var s: Bubble = sprites[nc]
		if s:
			tween.tween_property(s, "position", _grid.grid_to_world(nc), 0.35)\
				.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	# Add `count` new columns from reserve, sliding in from the right wall.
	for i in count:
		if _reserve_queue.is_empty():
			break
		var col_data: Dictionary = _reserve_queue.pop_front()
		for row: int in col_data:
			var nc := Vector2i(i, row)
			var bubble: Bubble = BUBBLE_SCENE.instantiate()
			bubble.color_index = col_data[row]
			bubble.position = Vector2(RIGHT_ANCHOR_X - HexGrid.BUBBLE_R, _grid.grid_to_world(nc).y)
			grid_root.add_child(bubble)
			cells[nc] = col_data[row]
			sprites[nc] = bubble
			tween.tween_property(bubble, "position", _grid.grid_to_world(nc), 0.5)\
				.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)

	await tween.finished

func _check_death_line() -> bool:
	for cell: Vector2i in cells:
		# Trigger when left edge of bubble touches or crosses the death line.
		if _grid.grid_to_world(cell).x - HexGrid.BUBBLE_R <= _death_line_x:
			return true
	return false

func _copy_reserve_queue(src: Array) -> Array:
	var out: Array = []
	for d: Dictionary in src:
		out.append(d.duplicate())
	return out

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
			d.visible_cols = 8
			d.total_cols = 14
			d.bubbles_per_col = 10
			d.blob_size_min = 4
			d.blob_size_max = 6
		2:
			d.num_colors = 5
			d.visible_cols = 8
			d.total_cols = 20
			d.bubbles_per_col = 10
			d.blob_size_min = 3
			d.blob_size_max = 4
	return d

# ─── Blob board generator ─────────────────────────────────────────────────────

func _generate_blob_board(data: BubbleLevelData) -> void:
	cells.clear()
	sprites.clear()
	_reserve_queue.clear()

	var pool: Dictionary = {}
	for col in data.total_cols:
		for row in data.bubbles_per_col:
			pool[Vector2i(col, row)] = true

	# Generate blobs into a temporary dict, then split visible vs reserve.
	var all_cells: Dictionary = {}
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
			all_cells[c] = next_color
		next_color = (next_color + 1) % data.num_colors

	# Visible columns go into cells; reserve columns queue up for later scroll-in.
	var num_reserve := data.total_cols - data.visible_cols
	for _i in num_reserve:
		_reserve_queue.append({})
	for cell: Vector2i in all_cells:
		if cell.x < data.visible_cols:
			cells[cell] = all_cells[cell]
		else:
			_reserve_queue[cell.x - data.visible_cols][cell.y] = all_cells[cell]

# ─── Sprite spawning ──────────────────────────────────────────────────────────

func _spawn_bubble_sprites() -> void:
	for child in grid_root.get_children():
		child.queue_free()
	sprites.clear()
	for cell: Vector2i in cells:
		var bubble: Bubble = BUBBLE_SCENE.instantiate()
		bubble.color_index = cells[cell]
		bubble.position = _grid.grid_to_world(cell)
		grid_root.add_child(bubble)
		sprites[cell] = bubble

# ─── Tutorial ─────────────────────────────────────────────────────────────────

func _start_tutorial() -> void:
	_tutorial_active = true
	_setup_tutorial_board()
	_build_tutorial_hint()
	_build_tutorial_hud()

func _setup_tutorial_board() -> void:
	cells = {}
	_reserve_queue = []
	_reserve_queue_snapshot = []
	for row in [3, 4, 5, 6]:
		cells[Vector2i(0, row)] = 0  # red
	_cells_snapshot = cells.duplicate(false)
	_compute_cluster_count()
	_spawn_bubble_sprites()
	# Slingshot: blue. Hopper[0]: green. Hopper[1]: red (what they should tap to swap).
	# Rest: red — refills via _weighted_color() are also red since all grid cells are red.
	_ammo_total = 99
	_shots_total_gen = HOPPER_MAX + 1
	_queue.clear()
	_queue.append(1)  # blue — loaded in slingshot
	_queue.append(2)  # green — first hopper slot
	_queue.append(0)  # red — second hopper slot (tap to swap)
	for _i in 8:
		_queue.append(0)  # red fill
	_update_queue_display()

func _build_tutorial_hint() -> void:
	var target := _grid.grid_to_world(Vector2i(0, 4))
	var dir := (target - QUEUE_POS_CURRENT).normalized()
	var arrow_start := QUEUE_POS_CURRENT + dir * (HexGrid.BUBBLE_R + 12.0)
	var arrow_end := QUEUE_POS_CURRENT + dir * 300.0

	_tut_arrow = Line2D.new()
	_tut_arrow.default_color = Color(1.0, 0.95, 0.1, 0.9)
	_tut_arrow.width = 12.0
	_tut_arrow.end_cap_mode = Line2D.LINE_CAP_NONE
	_tut_arrow.add_point(arrow_start)
	_tut_arrow.add_point(arrow_end)
	_tut_arrow.visible = false  # hidden until phase 1
	add_child(_tut_arrow)

	var perp := Vector2(-dir.y, dir.x)
	_tut_arrowhead = Polygon2D.new()
	_tut_arrowhead.color = Color(1.0, 0.95, 0.1, 0.9)
	_tut_arrowhead.polygon = PackedVector2Array([
		arrow_end + dir * 34.0,
		arrow_end + perp * 20.0,
		arrow_end - perp * 20.0,
	])
	_tut_arrowhead.visible = false  # hidden until phase 1
	add_child(_tut_arrowhead)

	_tut_ring_tween = create_tween().set_loops()
	_tut_ring_tween.tween_property(self, "_tut_ring_scale", 1.5, 0.75)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tut_ring_tween.tween_property(self, "_tut_ring_scale", 1.0, 0.75)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _build_tutorial_hud() -> void:
	_tutorial_hud = CanvasLayer.new()
	_tutorial_hud.layer = 8
	add_child(_tutorial_hud)

	var btn := Button.new()
	btn.flat = true
	btn.expand_icon = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.icon = BTN_NEXT_TEX
	btn.custom_minimum_size = Vector2(80, 80)
	btn.anchors_preset = Control.PRESET_TOP_RIGHT
	btn.offset_right = -12
	btn.offset_top = 12
	btn.offset_left = -92
	btn.offset_bottom = 92
	btn.pressed.connect(_complete_tutorial)
	_tutorial_hud.add_child(btn)

func _advance_to_aim_hint() -> void:
	_tut_phase = 1
	_tut_hint_visible = true  # re-show if drag had hidden it during phase 0
	_tut_ring_scale = 1.0
	if _tut_ring_tween:
		_tut_ring_tween.kill()
	if _tut_arrow:
		_tut_arrow.visible = true
	if _tut_arrowhead:
		_tut_arrowhead.visible = true
	_tut_ring_tween = create_tween().set_loops()
	_tut_ring_tween.tween_property(self, "_tut_ring_scale", 1.5, 0.75)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tut_ring_tween.tween_property(self, "_tut_ring_scale", 1.0, 0.75)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _hide_tutorial_hint() -> void:
	if not _tut_hint_visible:
		return
	_tut_hint_visible = false
	if _tut_arrow:
		_tut_arrow.visible = false
	if _tut_arrowhead:
		_tut_arrowhead.visible = false
	if _tut_ring_tween:
		_tut_ring_tween.kill()
	queue_redraw()

func _complete_tutorial() -> void:
	_state = State.OVERLAY  # Block input immediately during transition
	_tutorial_active = false
	_tut_hint_visible = false
	_bbs.tutorial_seen = true
	_bbs.save()
	if _tut_ring_tween:
		_tut_ring_tween.kill()
	if _tut_arrow:
		_tut_arrow.queue_free()
	if _tut_arrowhead:
		_tut_arrowhead.queue_free()
	if _tutorial_hud:
		_tutorial_hud.queue_free()
	_tutorial_hud = null
	_tut_arrow = null
	_tut_arrowhead = null
	queue_redraw()
	call_deferred("_on_new_game")
