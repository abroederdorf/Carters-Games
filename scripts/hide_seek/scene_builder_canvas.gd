class_name SceneBuilderCanvas
extends Control

signal item_tapped(index: int)
signal empty_tapped(scene_pos: Vector2)

enum Mode { ITEMS, ANCHORS }

var _zoom: float = 1.0
var _offset: Vector2 = Vector2.ZERO
var _scene_data: HideSeekSceneData
var _selected_index: int = -1
var _mode: int = Mode.ITEMS

var _touches: Dictionary = {}
var _drag_starts: Dictionary = {}
var _pinch_init_dist: float = -1.0
var _pinch_init_zoom: float = 1.0
var _pinch_midpoint: Vector2 = Vector2.ZERO

const TAP_THRESHOLD := 8.0

func setup(scene_data: HideSeekSceneData, selected: int, mode: int = -1) -> void:
	_scene_data = scene_data
	_selected_index = selected
	if mode != -1:
		_mode = mode
	queue_redraw()

func set_mode(mode: int) -> void:
	_mode = mode
	queue_redraw()

func fit_background() -> void:
	if not _scene_data or not _scene_data.background_image:
		return
	var img_size := _scene_data.background_image.get_size()
	if img_size.x <= 0 or img_size.y <= 0:
		return
	var scale_x := size.x / img_size.x
	var scale_y := size.y / img_size.y
	_zoom = minf(scale_x, scale_y)
	_offset = (size - img_size * _zoom) * 0.5
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.15, 0.15, 0.15))

	if _scene_data and _scene_data.background_image:
		var img_size := _scene_data.background_image.get_size()
		draw_texture_rect(_scene_data.background_image, Rect2(_offset, img_size * _zoom), false)
	else:
		var msg := "Load a background image, then tap to place items"
		draw_string(ThemeDB.fallback_font, size * 0.5 - Vector2(160, 0), msg,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.GRAY)

	if not _scene_data:
		return
		
	# Draw Items
	for i in _scene_data.items.size():
		var item: HideSeekItemData = _scene_data.items[i]
		var sp := _to_screen(item.position)
		var sr := item.radius * _zoom
		var is_sel := (i == _selected_index and _mode == Mode.ITEMS)
		var color := Color(1.0, 1.0, 0.0) if is_sel else Color(0.0, 1.0, 0.0)
		draw_circle(sp, sr, color * Color(1, 1, 1, 0.2))
		draw_arc(sp, sr, 0, TAU, 48, color, 2.5)
		draw_string(ThemeDB.fallback_font, sp + Vector2(-5, 5), str(i + 1),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)

	# Draw Anchors
	for i in _scene_data.anchors.size():
		var anchor: HideSeekAnchor = _scene_data.anchors[i]
		var sp := _to_screen(anchor.position)
		var sr := anchor.radius * _zoom
		var is_sel := (i == _selected_index and _mode == Mode.ANCHORS)
		var color := Color(0.0, 1.0, 1.0) if is_sel else Color(0.2, 0.4, 1.0)
		draw_circle(sp, sr, color * Color(1, 1, 1, 0.2))
		draw_arc(sp, sr, 0, TAU, 48, color, 1.5 if not is_sel else 3.0)
		draw_string(ThemeDB.fallback_font, sp + Vector2(-15, -15), "A%d" % (i + 1),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 11, color)

func _to_screen(p: Vector2) -> Vector2:
	return p * _zoom + _offset

func _to_scene(p: Vector2) -> Vector2:
	return (p - _offset) / _zoom

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_on_touch(event)
	elif event is InputEventScreenDrag:
		_on_screen_drag(event)
	elif event is InputEventMouseButton:
		_on_mouse_button(event)
	elif event is InputEventMouseMotion:
		_on_mouse_motion(event)

func _on_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		_touches[event.index] = event.position
		_drag_starts[event.index] = event.position
		if _touches.size() == 2:
			_begin_pinch()
	else:
		if _touches.size() == 1 and event.index in _drag_starts:
			if event.position.distance_to(_drag_starts[event.index]) < TAP_THRESHOLD:
				_handle_tap(event.position)
		_touches.erase(event.index)
		_drag_starts.erase(event.index)
		_pinch_init_dist = -1.0

func _on_screen_drag(event: InputEventScreenDrag) -> void:
	if event.index not in _touches:
		return
	_touches[event.index] = event.position
	if _touches.size() == 1:
		_offset += event.relative
		queue_redraw()
	elif _touches.size() == 2:
		_update_pinch()

func _begin_pinch() -> void:
	var vals := _touches.values()
	_pinch_init_dist = (vals[0] as Vector2).distance_to(vals[1] as Vector2)
	_pinch_init_zoom = _zoom
	_pinch_midpoint = ((vals[0] as Vector2) + (vals[1] as Vector2)) * 0.5

func _update_pinch() -> void:
	var vals := _touches.values()
	var dist := (vals[0] as Vector2).distance_to(vals[1] as Vector2)
	if _pinch_init_dist <= 0:
		return
	var new_zoom := clampf(_pinch_init_zoom * dist / _pinch_init_dist, 0.1, 10.0)
	var scene_mid := _to_scene(_pinch_midpoint)
	_zoom = new_zoom
	_offset = _pinch_midpoint - scene_mid * _zoom
	queue_redraw()

func _on_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
		_zoom_at(event.position, 1.15)
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
		_zoom_at(event.position, 1.0 / 1.15)
	elif event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_touches[-1] = event.position
			_drag_starts[-1] = event.position
		else:
			if -1 in _drag_starts and event.position.distance_to(_drag_starts[-1]) < TAP_THRESHOLD:
				_handle_tap(event.position)
			_touches.erase(-1)
			_drag_starts.erase(-1)

func _on_mouse_motion(event: InputEventMouseMotion) -> void:
	if -1 in _touches and (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
		_offset += event.relative
		_touches[-1] = event.position
		queue_redraw()

func _zoom_at(screen_pos: Vector2, factor: float) -> void:
	var sp := _to_scene(screen_pos)
	_zoom = clampf(_zoom * factor, 0.1, 10.0)
	_offset = screen_pos - sp * _zoom
	queue_redraw()

func _handle_tap(screen_pos: Vector2) -> void:
	if not _scene_data:
		return
	var scene_pos := _to_scene(screen_pos)
	
	if _mode == Mode.ITEMS:
		for i in _scene_data.items.size():
			var item: HideSeekItemData = _scene_data.items[i]
			if item.position.distance_to(scene_pos) <= item.radius:
				item_tapped.emit(i)
				return
	else:
		for i in _scene_data.anchors.size():
			var anchor: HideSeekAnchor = _scene_data.anchors[i]
			if anchor.position.distance_to(scene_pos) <= anchor.radius:
				item_tapped.emit(i)
				return
				
	empty_tapped.emit(scene_pos)
