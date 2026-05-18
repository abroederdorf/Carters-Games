class_name HideSeekCanvas
extends Node

signal tapped(canvas_pos: Vector2)
signal setup_done

const MAX_SCALE := 3.5
const TAP_MAX_MOVE := 20.0

var _bg_size: Vector2
var _top_bar_h: float
var _thumb_strip_h: float
var _is_running: bool = false

var _canvas_scale: float = 1.0
var _min_scale: float = 0.5
var _canvas_offset: Vector2 = Vector2.ZERO
var _canvas_area_size: Vector2 = Vector2.ZERO

var _touches: Dictionary = {}
var _pinch_start_dist: float = 0.0
var _pinch_start_scale: float = 0.0
var _pinch_start_offset: Vector2 = Vector2.ZERO
var _pinch_area_mid: Vector2 = Vector2.ZERO
var _pan_start_offset: Vector2 = Vector2.ZERO
var _pan_start_pos: Vector2 = Vector2.ZERO
var _is_pinching: bool = false

var _mouse_panning: bool = false
var _mouse_press_start: Vector2 = Vector2.ZERO

var _canvas_area: Control
var _canvas_root: Node2D
var _item_sprites: Array[Sprite2D] = []


func setup(parent: Control, bg_size: Vector2, top_bar_h: float, thumb_strip_h: float) -> void:
	_bg_size = bg_size
	_top_bar_h = top_bar_h
	_thumb_strip_h = thumb_strip_h

	_canvas_area = Control.new()
	_canvas_area.anchor_left = 0.0
	_canvas_area.anchor_top = 0.0
	_canvas_area.anchor_right = 1.0
	_canvas_area.anchor_bottom = 1.0
	_canvas_area.offset_top = top_bar_h
	_canvas_area.offset_bottom = -thumb_strip_h
	_canvas_area.clip_contents = true
	parent.add_child(_canvas_area)

	_canvas_root = Node2D.new()
	_canvas_area.add_child(_canvas_root)

	_init_transform()


func _init_transform() -> void:
	await get_tree().process_frame
	_canvas_area_size = _canvas_area.size
	var scale_x := _canvas_area_size.x / _bg_size.x
	var scale_y := _canvas_area_size.y / _bg_size.y
	_min_scale = min(scale_x, scale_y)
	_canvas_scale = _min_scale
	_canvas_offset = (_canvas_area_size - _bg_size * _canvas_scale) / 2.0
	_update_transform()
	setup_done.emit()


func set_running(value: bool) -> void:
	_is_running = value


func get_canvas_root() -> Node2D:
	return _canvas_root


func add_item_sprite(pos: Vector2, visual_scale: float, texture: Texture2D) -> void:
	var sprite := Sprite2D.new()
	sprite.centered = true
	sprite.position = pos
	if texture != null:
		sprite.texture = texture
		# 60.0 is our baseline sprite radius (120px diameter)
		# We scale based on the requested visual_scale
		sprite.scale = Vector2.ONE * visual_scale
	_canvas_root.add_child(sprite)
	_item_sprites.append(sprite)


func fade_item(index: int) -> void:
	if index >= _item_sprites.size():
		return
	var tween := get_tree().create_tween()
	tween.tween_property(_item_sprites[index], "modulate:a", 0.0, 0.4)


func show_flash_at(pos: Vector2) -> void:
	var img := TextureRect.new()
	img.texture = preload("res://assets/sprites/ui/checkmark.png")
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img.custom_minimum_size = Vector2(80, 80)
	img.size = Vector2(80, 80)
	img.position = pos - Vector2(40, 40)
	_canvas_root.add_child(img)

	var tween := get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(img, "position", pos - Vector2(40, 100), 0.7)
	tween.tween_property(img, "modulate:a", 0.0, 0.7).set_delay(0.2)
	tween.chain().tween_callback(img.queue_free)


func show_wrong_at(pos: Vector2) -> void:
	var img := TextureRect.new()
	img.texture = preload("res://assets/sprites/ui/xmark.png")
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img.custom_minimum_size = Vector2(80, 80)
	img.size = Vector2(80, 80)
	img.position = pos - Vector2(40, 40)
	img.modulate = Color(1, 0.2, 0.2, 1)
	_canvas_root.add_child(img)

	var penalty := Label.new()
	penalty.text = "+5s"
	penalty.add_theme_font_size_override("font_size", 36)
	penalty.add_theme_color_override("font_color", Color(1, 0.2, 0.2, 1))
	penalty.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	penalty.add_theme_constant_override("shadow_offset_x", 2)
	penalty.add_theme_constant_override("shadow_offset_y", 2)
	penalty.position = pos + Vector2(10, -60)
	_canvas_root.add_child(penalty)

	var tween := get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(img, "position", pos - Vector2(40, 100), 0.7)
	tween.tween_property(img, "modulate:a", 0.0, 0.7).set_delay(0.2)
	tween.tween_property(penalty, "position", pos + Vector2(10, -120), 0.7)
	tween.tween_property(penalty, "modulate:a", 0.0, 0.7).set_delay(0.2)
	tween.chain().tween_callback(img.queue_free)
	tween.chain().tween_callback(penalty.queue_free)


func show_hint_at(pos: Vector2, radius: float) -> void:
	var hint := Node2D.new()
	hint.position = pos
	_canvas_root.add_child(hint)

	var font_size := int(radius * 3.5)

	# Outer ripple ring — expands and fades repeatedly
	var ring := Label.new()
	ring.text = "●"
	ring.add_theme_font_size_override("font_size", font_size)
	ring.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0, 0.5))
	ring.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ring.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ring.custom_minimum_size = Vector2(font_size * 1.5, font_size * 1.5)
	ring.position = Vector2(-font_size * 0.75, -font_size * 0.75)
	hint.add_child(ring)

	# Inner star — pulses and flashes color
	var star := Label.new()
	star.text = "★"
	star.add_theme_font_size_override("font_size", font_size)
	star.add_theme_color_override("font_color", Color(1.0, 0.9, 0.0))
	star.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 1.0))
	star.add_theme_constant_override("shadow_offset_x", 4)
	star.add_theme_constant_override("shadow_offset_y", 4)
	star.add_theme_constant_override("shadow_size", 6)
	star.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	star.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	star.custom_minimum_size = Vector2(font_size * 1.5, font_size * 1.5)
	star.position = Vector2(-font_size * 0.75, -font_size * 0.75)
	hint.add_child(star)

	# Ripple: ring expands outward and fades, loops 5 times
	var ripple := get_tree().create_tween()
	ripple.set_loops(5)
	ripple.tween_property(ring, "scale", Vector2(2.5, 2.5), 0.6).set_ease(Tween.EASE_OUT)
	ripple.tween_property(ring, "modulate:a", 0.0, 0.0)
	ripple.tween_property(ring, "scale", Vector2(1.0, 1.0), 0.0)
	ripple.tween_property(ring, "modulate:a", 1.0, 0.0)

	# Star: pulses scale and flashes between gold and white, 10 times
	var flash := get_tree().create_tween()
	flash.set_loops(10)
	flash.tween_property(star, "scale", Vector2(1.35, 1.35), 0.15).set_ease(Tween.EASE_OUT)
	flash.tween_property(star, "modulate", Color(1.0, 1.0, 1.0), 0.15)
	flash.tween_property(star, "scale", Vector2(0.9, 0.9), 0.15).set_ease(Tween.EASE_IN)
	flash.tween_property(star, "modulate", Color(1.0, 0.9, 0.0), 0.15)

	# Fade everything out after 3.5 seconds
	var fade := get_tree().create_tween()
	fade.tween_interval(3.2)
	fade.tween_property(hint, "modulate:a", 0.0, 0.6)
	fade.tween_callback(hint.queue_free)


# ── Input ──────────────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if not _is_running:
		return
	if event is InputEventScreenTouch:
		_handle_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_handle_drag(event as InputEventScreenDrag)
	elif event is InputEventMouseButton:
		_handle_mouse_button(event as InputEventMouseButton)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event as InputEventMouseMotion)
	elif event is InputEventPanGesture:
		_handle_pan_gesture(event as InputEventPanGesture)
	elif event is InputEventMagnifyGesture:
		_handle_magnify_gesture(event as InputEventMagnifyGesture)


func _handle_touch(event: InputEventScreenTouch) -> void:
	var vp_h := get_viewport().get_visible_rect().size.y
	if event.position.y < _top_bar_h or event.position.y > vp_h - _thumb_strip_h:
		return
	if event.pressed:
		_touches[event.index] = {"pos": event.position, "start": event.position}
		if _touches.size() == 2:
			_is_pinching = true
			var ids := _touches.keys()
			var p0: Vector2 = _touches[ids[0]]["pos"]
			var p1: Vector2 = _touches[ids[1]]["pos"]
			_pinch_start_dist = p0.distance_to(p1)
			_pinch_start_scale = _canvas_scale
			_pinch_start_offset = _canvas_offset
			_pinch_area_mid = (p0 + p1) / 2.0 - Vector2(0, _top_bar_h)
		else:
			_is_pinching = false
			_pan_start_offset = _canvas_offset
			_pan_start_pos = event.position
	else:
		if _touches.has(event.index):
			var start: Vector2 = _touches[event.index]["start"]
			_touches.erase(event.index)
			if not _is_pinching and event.position.distance_to(start) < TAP_MAX_MOVE:
				_handle_tap(event.position)
		if _touches.size() < 2:
			_is_pinching = false
		if _touches.size() == 1:
			var ids := _touches.keys()
			_pan_start_offset = _canvas_offset
			_pan_start_pos = _touches[ids[0]]["pos"]


func _handle_drag(event: InputEventScreenDrag) -> void:
	if not _touches.has(event.index):
		return
	_touches[event.index]["pos"] = event.position

	if _is_pinching and _touches.size() == 2:
		var ids := _touches.keys()
		var p0: Vector2 = _touches[ids[0]]["pos"]
		var p1: Vector2 = _touches[ids[1]]["pos"]
		var new_dist := p0.distance_to(p1)
		if _pinch_start_dist > 0.0:
			var new_scale: float = clamp(
				_pinch_start_scale * (new_dist / _pinch_start_dist),
				_min_scale, MAX_SCALE
			)
			var canvas_pt := (_pinch_area_mid - _pinch_start_offset) / _pinch_start_scale
			_canvas_scale = new_scale
			_canvas_offset = _pinch_area_mid - canvas_pt * _canvas_scale
			_clamp_offset()
			_update_transform()
	elif not _is_pinching and _touches.size() == 1:
		_canvas_offset = _pan_start_offset + (event.position - _pan_start_pos)
		_clamp_offset()
		_update_transform()


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	var vp_h := get_viewport().get_visible_rect().size.y
	if event.position.y < _top_bar_h or event.position.y > vp_h - _thumb_strip_h:
		return
	match event.button_index:
		MOUSE_BUTTON_LEFT:
			if event.pressed:
				_mouse_panning = true
				_mouse_press_start = event.position
				_pan_start_offset = _canvas_offset
				_pan_start_pos = event.position
			else:
				_mouse_panning = false
				if event.position.distance_to(_mouse_press_start) < TAP_MAX_MOVE:
					_handle_tap(event.position)
		MOUSE_BUTTON_WHEEL_UP:
			_apply_zoom(_canvas_scale * 1.12, event.position - Vector2(0, _top_bar_h))
		MOUSE_BUTTON_WHEEL_DOWN:
			_apply_zoom(_canvas_scale / 1.12, event.position - Vector2(0, _top_bar_h))


func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if not _mouse_panning:
		return
	_canvas_offset = _pan_start_offset + (event.position - _pan_start_pos)
	_clamp_offset()
	_update_transform()


func _handle_pan_gesture(event: InputEventPanGesture) -> void:
	var vp_h := get_viewport().get_visible_rect().size.y
	if event.position.y < _top_bar_h or event.position.y > vp_h - _thumb_strip_h:
		return
	_canvas_offset -= event.delta * 4.0
	_clamp_offset()
	_update_transform()


func _handle_magnify_gesture(event: InputEventMagnifyGesture) -> void:
	var vp_h := get_viewport().get_visible_rect().size.y
	if event.position.y < _top_bar_h or event.position.y > vp_h - _thumb_strip_h:
		return
	_apply_zoom(_canvas_scale * event.factor, event.position - Vector2(0, _top_bar_h))


func _apply_zoom(new_scale: float, area_center: Vector2) -> void:
	new_scale = clamp(new_scale, _min_scale, MAX_SCALE)
	var canvas_pt := (area_center - _canvas_offset) / _canvas_scale
	_canvas_scale = new_scale
	_canvas_offset = area_center - canvas_pt * _canvas_scale
	_clamp_offset()
	_update_transform()


func _handle_tap(screen_pos: Vector2) -> void:
	if _canvas_area_size == Vector2.ZERO:
		return
	var area_pos := screen_pos - Vector2(0, _top_bar_h)
	if area_pos.y < 0 or area_pos.y > _canvas_area_size.y:
		return
	tapped.emit((area_pos - _canvas_offset) / _canvas_scale)


func _update_transform() -> void:
	_canvas_root.position = _canvas_offset
	_canvas_root.scale = Vector2(_canvas_scale, _canvas_scale)


func _clamp_offset() -> void:
	var w := _bg_size.x * _canvas_scale
	var h := _bg_size.y * _canvas_scale
	var area := _canvas_area_size
	if w <= area.x:
		_canvas_offset.x = (area.x - w) / 2.0
	else:
		_canvas_offset.x = clamp(_canvas_offset.x, area.x - w, 0.0)
	if h <= area.y:
		_canvas_offset.y = (area.y - h) / 2.0
	else:
		_canvas_offset.y = clamp(_canvas_offset.y, area.y - h, 0.0)
