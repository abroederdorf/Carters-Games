class_name HexGrid
extends RefCounted

# Flat-top hexagons, column-major layout.
# col 0 = rightmost (anchor wall), col increases leftward.
# Odd columns are shifted DOWN (+Y) by BUBBLE_R — "odd-q" offset.

const BUBBLE_D: float = 96.0
const BUBBLE_R: float = BUBBLE_D / 2.0
const COL_W: float = BUBBLE_D * 0.866  # horizontal pitch between column centers (sqrt(3)/2 * D)

# Odd-q neighbor offsets, odd columns shifted DOWN (+Y).
# Index by (col & 1): _NEIGHBORS[0] = even col, _NEIGHBORS[1] = odd col.
const _NEIGHBORS: Array = [
	# even col
	[Vector2i(-1, -1), Vector2i(-1, 0), Vector2i(1, -1), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)],
	# odd col
	[Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, -1), Vector2i(0, 1)],
]

# Anchor: the world X of the rightmost column center (col 0).
var right_anchor_x: float = 0.0
# World Y of the top of row 0 for even columns (before the +BUBBLE_R center offset).
var origin_y: float = 0.0

func setup(anchor_x: float, top_y: float) -> void:
	right_anchor_x = anchor_x
	origin_y = top_y

# Convert grid cell → world pixel center.
func grid_to_world(cell: Vector2i) -> Vector2:
	var col := cell.x
	var row := cell.y
	var x: float = right_anchor_x - col * COL_W - BUBBLE_R
	var y: float = origin_y + row * BUBBLE_D + (BUBBLE_R if (col & 1) else 0.0) + BUBBLE_R
	return Vector2(x, y)

# Convert world pixel position → nearest grid cell.
# Uses float inversion then checks candidate + neighbors for the closest center.
func world_to_grid(world: Vector2) -> Vector2i:
	# Invert grid_to_world analytically to get a float (col, row) estimate.
	var col_f: float = (right_anchor_x - BUBBLE_R - world.x) / COL_W
	var col_rounded: int = roundi(col_f)

	# For each plausible column, compute the row.
	var best_cell := Vector2i(col_rounded, 0)
	var best_dist := INF

	for dc in [-1, 0, 1]:
		var col_try: int = col_rounded + dc
		if col_try < 0:
			continue
		var odd_offset: float = BUBBLE_R if (col_try & 1) else 0.0
		var row_f: float = (world.y - origin_y - odd_offset - BUBBLE_R) / BUBBLE_D
		var row_try: int = roundi(row_f)

		for dr in [-1, 0, 1]:
			var cell := Vector2i(col_try, row_try + dr)
			if cell.y < 0:
				continue
			var center := grid_to_world(cell)
			var d := world.distance_to(center)
			if d < best_dist:
				best_dist = d
				best_cell = cell

	return best_cell

# Return the 6 neighbors of a cell (as Vector2i offsets applied).
func neighbors(cell: Vector2i) -> Array[Vector2i]:
	var parity: int = cell.x & 1
	var offsets: Array = _NEIGHBORS[parity]
	var result: Array[Vector2i] = []
	for off in offsets:
		result.append(cell + off)
	return result

# ─── Ray-march (shared by trajectory preview and projectile bounce) ───────────

# Simulate the bubble path from `start` in direction `dir`, reflecting off
# top_y and bot_y boundaries, stopping on bubble or right-wall collision.
# Returns { "waypoints": Array[Vector2], "snap_cell": Vector2i, "snap_world": Vector2 }.
# snap_cell == Vector2i(-1,-1) when no valid landing slot was found.
static func march_ray(
		start: Vector2, dir: Vector2,
		top_y: float, bot_y: float, right_x: float,
		max_bounces: int, step_px: float,
		cells: Dictionary, grid: HexGrid
) -> Dictionary:
	var wpts: Array[Vector2] = [start]
	var pos := start
	var vel := dir.normalized()
	var bounces := 0
	var snap_cell := Vector2i(-1, -1)
	var snap_world := start

	for _i in 10000:
		var prev := pos
		pos += vel * step_px
		var stopped := false

		# Top-wall bounce
		if pos.y < top_y:
			var t := (top_y - prev.y) / (pos.y - prev.y)
			wpts.append(prev.lerp(pos, t))
			pos.y = 2.0 * top_y - pos.y
			vel.y = absf(vel.y)
			bounces += 1
			if bounces >= max_bounces:
				wpts.append(pos)
				break
			continue

		# Bottom-wall bounce
		if pos.y > bot_y:
			var t := (bot_y - prev.y) / (pos.y - prev.y)
			wpts.append(prev.lerp(pos, t))
			pos.y = 2.0 * bot_y - pos.y
			vel.y = -absf(vel.y)
			bounces += 1
			if bounces >= max_bounces:
				wpts.append(pos)
				break
			continue

		# Right-wall snap
		if pos.x >= right_x - BUBBLE_R:
			var cell := grid.world_to_grid(pos)
			cell.x = 0
			snap_cell = cell
			snap_world = grid.grid_to_world(cell)
			wpts.append(snap_world)
			stopped = true

		# Bubble-collision snap
		if not stopped:
			for cell: Vector2i in cells:
				if pos.distance_to(grid.grid_to_world(cell)) < BUBBLE_D:
					var sc := grid.world_to_grid(pos)
					if cells.has(sc):
						var best := Vector2i(-1, -1)
						var best_d := INF
						for n in grid.neighbors(sc):
							if not cells.has(n) and n.x >= 0:
								var nd := pos.distance_to(grid.grid_to_world(n))
								if nd < best_d:
									best_d = nd
									best = n
						sc = best
					snap_cell = sc
					snap_world = grid.grid_to_world(sc) if sc != Vector2i(-1, -1) else pos
					wpts.append(pos)
					stopped = true
					break

		if stopped:
			break

	# Safety: ensure path always ends somewhere
	if wpts.size() < 2:
		wpts.append(pos)

	return {"waypoints": wpts, "snap_cell": snap_cell, "snap_world": snap_world}

# ─── Self-test: print round-trips for a handful of known cells ───────────────
# Call this once from a debug scene or _ready() in a test node.
static func run_round_trip_test(anchor_x: float, top_y: float) -> void:
	var g := HexGrid.new()
	g.setup(anchor_x, top_y)

	var test_cells: Array[Vector2i] = [
		Vector2i(0, 0), Vector2i(0, 3),
		Vector2i(1, 0), Vector2i(1, 3),
		Vector2i(2, 0), Vector2i(2, 5),
		Vector2i(3, 1), Vector2i(4, 4),
	]

	print("=== HexGrid round-trip verification ===")
	print("anchor_x=%.1f  origin_y=%.1f  BUBBLE_D=%.1f  COL_W=%.3f" % [
		anchor_x, top_y, BUBBLE_D, COL_W])
	print("%-18s  %-22s  %-18s  %s" % ["cell", "world_center", "roundtrip", "ok?"])

	for cell in test_cells:
		var world := g.grid_to_world(cell)
		var back := g.world_to_grid(world)
		var ok := "OK" if back == cell else ("FAIL (got %s)" % str(back))
		print("%-18s  %-22s  %-18s  %s" % [
			str(cell), "(%.1f, %.1f)" % [world.x, world.y], str(back), ok])

	print("")
	print("Neighbor test for (0,0) [even col], expect offsets matching even-col table:")
	var even_neighbors := g.neighbors(Vector2i(0, 0))
	for n in even_neighbors:
		print("  ", n)

	print("")
	print("Neighbor test for (1,0) [odd col], expect offsets matching odd-col table:")
	var odd_neighbors := g.neighbors(Vector2i(1, 0))
	for n in odd_neighbors:
		print("  ", n)

	print("=== end ===")
