class_name AimLine
extends Node2D

const _LINE_COLOR: Color = Color(0.0, 0.0, 0.0, 0.82)
const _GHOST_COLOR: Color = Color(0.0, 0.0, 0.0, 0.30)
const _LINE_W: float = 5.0
const _DASH: float = 18.0

var _waypoints: Array[Vector2] = []
var _snap_world: Vector2 = Vector2.ZERO
var _has_snap: bool = false

func show_path(waypoints: Array, snap_world: Vector2, has_snap: bool) -> void:
	_waypoints.assign(waypoints)
	_snap_world = snap_world
	_has_snap = has_snap
	visible = true
	queue_redraw()

func hide_path() -> void:
	_waypoints.clear()
	_has_snap = false
	visible = false

func _draw() -> void:
	if _waypoints.size() < 2:
		return
	for i in range(_waypoints.size() - 1):
		draw_dashed_line(_waypoints[i], _waypoints[i + 1], _LINE_COLOR, _LINE_W, _DASH)
	if _has_snap:
		draw_circle(_snap_world, HexGrid.BUBBLE_R, _GHOST_COLOR)
