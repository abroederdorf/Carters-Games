extends Control

const TOP_BAR_H := 80.0
const THUMB_STRIP_H := 150.0
const THUMB_SIZE := 110.0
const MAX_SCALE := 3.5
const TAP_MAX_MOVE := 20.0

const MAX_ITEMS := 10

var _scene_name: String
var _scene_data: HideSeekSceneData
var _active_items: Array[HideSeekItemData] = []
var _found: Array[bool] = []
var _found_count: int = 0
var _elapsed: float = 0.0
var _running: bool = false
var _won: bool = false

# Runtime item assignment (anchor info for each item index)
var _active_item_data: Array[Dictionary] = []

# Canvas transform
var _canvas_scale: float = 1.0
var _min_scale: float = 0.5
var _canvas_offset: Vector2 = Vector2.ZERO
var _bg_size: Vector2 = Vector2.ZERO
var _canvas_area_size: Vector2 = Vector2.ZERO

# Touch tracking (int id → Dictionary{pos, start})
var _touches: Dictionary = {}
var _pinch_start_dist: float = 0.0
var _pinch_start_scale: float = 0.0
var _pinch_start_offset: Vector2 = Vector2.ZERO
var _pinch_area_mid: Vector2 = Vector2.ZERO
var _pan_start_offset: Vector2 = Vector2.ZERO
var _pan_start_pos: Vector2 = Vector2.ZERO
var _is_pinching: bool = false

# Mouse tracking (desktop testing)
var _mouse_panning: bool = false
var _mouse_press_start: Vector2 = Vector2.ZERO

# Node refs
var _canvas_area: Control
var _canvas_root: Node2D
var _timer_label: Label
var _hint_stars_label: Label
var _thumb_nodes: Array[Control] = []
var _item_sprites: Array[Sprite2D] = []
var _win_overlay: Control
var _win_stars_label: Label
var _win_time_label: Label
var _win_next_btn: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scene_name = HideSeekState.current_scene_name
	if _scene_name.is_empty():
		get_tree().change_scene_to_file("res://scenes/hide_seek/HideSeekMain.tscn")
		return
	_scene_data = load("res://resources/hide_seek/%s.tres" % _scene_name) as HideSeekSceneData
	if _scene_data == null:
		get_tree().change_scene_to_file("res://scenes/hide_seek/HideSeekMain.tscn")
		return

	var bg_tex_early := _scene_data.background_image
	_bg_size = Vector2(bg_tex_early.get_width(), bg_tex_early.get_height())

	var all_items := _scene_data.items.duplicate()
	all_items.shuffle()
	_active_items = all_items.slice(0, min(MAX_ITEMS, all_items.size()))

	_assign_items_to_anchors()

	_found.resize(_active_items.size())
	_found.fill(false)
	_build_ui()
	_setup_canvas()


func _assign_items_to_anchors() -> void:
	_active_item_data.clear()
	
	# 1. Filter and separate anchors by difficulty
	var standard_anchors: Array[HideSeekAnchor] = []
	var hard_anchors: Array[HideSeekAnchor] = []
	
	# Margin to prevent items from being cut off at edges
	var margin_x := _bg_size.x * 0.05
	var margin_y := _bg_size.y * 0.05
	
	for a in _scene_data.anchors:
		if a.position.x < margin_x or a.position.x > _bg_size.x - margin_x \
			or a.position.y < margin_y or a.position.y > _bg_size.y - margin_y:
			continue
			
		if a.difficulty >= 2:
			hard_anchors.append(a)
		else:
			standard_anchors.append(a)
	
	standard_anchors.shuffle()
	hard_anchors.shuffle()
	
	# 2. Select the pool for this session (Target: more than items.size to allow matching)
	var session_anchors: Array[HideSeekAnchor] = []
	
	# Aim for 2 hard anchors if available
	var hard_count = min(2, hard_anchors.size())
	for i in hard_count:
		session_anchors.append(hard_anchors.pop_back())
		
	# Fill with standard anchors to give the matcher breathing room
	# (We pick 20 anchors for 10 items to ensure tag matching works)
	var needed = min(20, standard_anchors.size() + session_anchors.size()) - session_anchors.size()
	for i in needed:
		if not standard_anchors.is_empty():
			session_anchors.append(standard_anchors.pop_back())
	
	session_anchors.shuffle()
	
	# 3. Match items to anchors via tags
	var used_anchors: Array[bool] = []
	used_anchors.resize(session_anchors.size())
	used_anchors.fill(false)
	
	for i in _active_items.size():
		var item := _active_items[i]
		var assigned_anchor: HideSeekAnchor = null
		
		# PASS 1: Strict Tag Matching
		if not item.tags.is_empty():
			for j in session_anchors.size():
				if used_anchors[j]: continue
				var anchor = session_anchors[j]
				
				for t in item.tags:
					if t in anchor.tags:
						assigned_anchor = anchor
						used_anchors[j] = true
						break
				if assigned_anchor: break
		
		# PASS 2: Fallback for generic items or no tag match
		if assigned_anchor == null:
			for j in session_anchors.size():
				if used_anchors[j]: continue
				var anchor: HideSeekAnchor = session_anchors[j]

				var anchor_has_water := "water" in anchor.tags
				var anchor_has_sky := "sky" in anchor.tags
				var item_needs_water := "water" in item.tags
				var item_needs_sky := "sky" in item.tags
				var item_is_ground := "ground" in item.tags and not item_needs_sky and not item_needs_water

				if item_is_ground and (anchor_has_sky or anchor_has_water): continue
				if item_needs_water and not anchor_has_water: continue
				if item_needs_sky and not anchor_has_sky: continue
					
				assigned_anchor = anchor
				used_anchors[j] = true
				break
				
		# PASS 3: Absolute fallback (ran out of good spots)
		if assigned_anchor == null:
			for j in session_anchors.size():
				if not used_anchors[j]:
					assigned_anchor = session_anchors[j]
					used_anchors[j] = true
					break
		
		# Final result
		var data := {"pos": item.position, "radius": item.radius}
		if assigned_anchor != null:
			data["pos"] = assigned_anchor.position
			data["radius"] = assigned_anchor.radius * item.scale_multiplier
			
		_active_item_data.append(data)


func _process(delta: float) -> void:
	if _running and not _won:
		_elapsed += delta
		_update_timer()


func _input(event: InputEvent) -> void:
	if _won:
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


# ── UI Construction ────────────────────────────────────────────────────────────

func _build_ui() -> void:
	var scene_bg := ColorRect.new()
	scene_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scene_bg.color = Color(0.05, 0.05, 0.05)
	add_child(scene_bg)

	_canvas_area = Control.new()
	_canvas_area.anchor_left = 0.0
	_canvas_area.anchor_top = 0.0
	_canvas_area.anchor_right = 1.0
	_canvas_area.anchor_bottom = 1.0
	_canvas_area.offset_top = TOP_BAR_H
	_canvas_area.offset_bottom = -THUMB_STRIP_H
	_canvas_area.clip_contents = true
	add_child(_canvas_area)

	_canvas_root = Node2D.new()
	_canvas_area.add_child(_canvas_root)

	var bg_tex := _scene_data.background_image
	_bg_size = Vector2(bg_tex.get_width(), bg_tex.get_height())
	var bg_sprite := Sprite2D.new()
	bg_sprite.texture = bg_tex
	bg_sprite.centered = false
	_canvas_root.add_child(bg_sprite)
	_build_item_sprites()

	_build_top_bar()
	_build_thumb_strip()
	_build_win_overlay()


func _build_item_sprites() -> void:
	for i in _active_items.size():
		var item: HideSeekItemData = _active_items[i]
		var runtime_data: Dictionary = _active_item_data[i]
		var tex := _get_item_texture(item)
		var sprite := Sprite2D.new()
		sprite.centered = true
		sprite.position = runtime_data["pos"]
		if tex != null:
			sprite.texture = tex
			var max_dim := float(max(tex.get_width(), tex.get_height()))
			if max_dim > 0.0:
				# Scale based on the assigned anchor's radius
				sprite.scale = Vector2.ONE * ((runtime_data["radius"] * 2.0) / max_dim)
		_canvas_root.add_child(sprite)
		_item_sprites.append(sprite)


func _build_top_bar() -> void:
	var bar := ColorRect.new()
	bar.anchor_left = 0.0
	bar.anchor_top = 0.0
	bar.anchor_right = 1.0
	bar.anchor_bottom = 0.0
	bar.offset_bottom = TOP_BAR_H
	bar.color = Color(0, 0, 0, 0.8)
	bar.z_index = 10
	add_child(bar)

	var hbox := HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 16)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_child(hbox)

	var pad_l := Control.new()
	pad_l.custom_minimum_size.x = 20
	hbox.add_child(pad_l)

	var back_btn := Button.new()
	back_btn.text = "← Back"
	back_btn.custom_minimum_size = Vector2(160, 58)
	back_btn.add_theme_font_size_override("font_size", 28)
	back_btn.focus_mode = Control.FOCUS_NONE
	back_btn.pressed.connect(_on_back_pressed)
	hbox.add_child(back_btn)

	var spacer_l := Control.new()
	spacer_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer_l)

	_timer_label = Label.new()
	_timer_label.text = "0:00"
	_timer_label.add_theme_font_size_override("font_size", 46)
	_timer_label.add_theme_color_override("font_color", Color.WHITE)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_label.custom_minimum_size.x = 140
	hbox.add_child(_timer_label)

	var spacer_r := Control.new()
	spacer_r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer_r)

	var hint_vbox := VBoxContainer.new()
	hint_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hint_vbox.custom_minimum_size = Vector2(170, 0)
	hbox.add_child(hint_vbox)

	var hint_btn := Button.new()
	hint_btn.text = "💡 Hint"
	hint_btn.custom_minimum_size = Vector2(150, 44)
	hint_btn.add_theme_font_size_override("font_size", 26)
	hint_btn.focus_mode = Control.FOCUS_NONE
	hint_btn.pressed.connect(_on_hint_pressed)
	hint_vbox.add_child(hint_btn)

	_hint_stars_label = Label.new()
	_hint_stars_label.add_theme_font_size_override("font_size", 20)
	_hint_stars_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1, 1))
	_hint_stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_vbox.add_child(_hint_stars_label)

	var pad_r := Control.new()
	pad_r.custom_minimum_size.x = 20
	hbox.add_child(pad_r)

	_update_hint_label()


func _build_thumb_strip() -> void:
	var strip := ColorRect.new()
	strip.anchor_left = 0.0
	strip.anchor_top = 1.0
	strip.anchor_right = 1.0
	strip.anchor_bottom = 1.0
	strip.offset_top = -THUMB_STRIP_H
	strip.color = Color(0, 0, 0, 0.8)
	strip.z_index = 10
	add_child(strip)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	strip.add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	hbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	scroll.add_child(hbox)

	for i in _active_items.size():
		var item: HideSeekItemData = _active_items[i]
		var card := _make_thumb_card(item)
		_thumb_nodes.append(card)
		hbox.add_child(card)


func _make_thumb_card(item: HideSeekItemData) -> Control:
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(THUMB_SIZE, THUMB_SIZE)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.18, 0.18)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.35, 0.35, 0.35)
	panel.add_theme_stylebox_override("panel", style)

	# Index 0: item image
	var tex_rect := TextureRect.new()
	tex_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.texture = _get_item_texture(item)
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(tex_rect)

	# Index 1: green found overlay (hidden until found)
	var check_bg := ColorRect.new()
	check_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	check_bg.color = Color(0.1, 0.65, 0.1, 0.65)
	check_bg.visible = false
	check_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(check_bg)

	# Index 2: check label (hidden until found)
	var check_lbl := Label.new()
	check_lbl.text = "✓"
	check_lbl.add_theme_font_size_override("font_size", 52)
	check_lbl.add_theme_color_override("font_color", Color.WHITE)
	check_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	check_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	check_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	check_lbl.visible = false
	check_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(check_lbl)

	return panel


func _build_win_overlay() -> void:
	_win_overlay = ColorRect.new()
	_win_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	(_win_overlay as ColorRect).color = Color(0, 0, 0, 0.78)
	_win_overlay.z_index = 20
	_win_overlay.visible = false
	add_child(_win_overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_win_overlay.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 28)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(vbox)

	var title := Label.new()
	title.text = "You Found Them All!"
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	_win_stars_label = Label.new()
	_win_stars_label.add_theme_font_size_override("font_size", 90)
	_win_stars_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1, 1))
	_win_stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_win_stars_label)

	_win_time_label = Label.new()
	_win_time_label.add_theme_font_size_override("font_size", 36)
	_win_time_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	_win_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_win_time_label)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 32)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_row)

	var home_btn := Button.new()
	home_btn.text = "🏠 Home"
	home_btn.custom_minimum_size = Vector2(210, 74)
	home_btn.add_theme_font_size_override("font_size", 34)
	home_btn.focus_mode = Control.FOCUS_NONE
	home_btn.pressed.connect(_on_home_pressed)
	btn_row.add_child(home_btn)

	var replay_btn := Button.new()
	replay_btn.text = "↺ Replay"
	replay_btn.custom_minimum_size = Vector2(210, 74)
	replay_btn.add_theme_font_size_override("font_size", 34)
	replay_btn.focus_mode = Control.FOCUS_NONE
	replay_btn.pressed.connect(_on_replay_pressed)
	btn_row.add_child(replay_btn)

	_win_next_btn = Button.new()
	_win_next_btn.text = "Next →"
	_win_next_btn.custom_minimum_size = Vector2(210, 74)
	_win_next_btn.add_theme_font_size_override("font_size", 34)
	_win_next_btn.focus_mode = Control.FOCUS_NONE
	_win_next_btn.pressed.connect(_on_next_pressed)
	btn_row.add_child(_win_next_btn)


# ── Canvas Setup ───────────────────────────────────────────────────────────────

func _setup_canvas() -> void:
	await get_tree().process_frame
	_canvas_area_size = _canvas_area.size
	var scale_x := _canvas_area_size.x / _bg_size.x
	var scale_y := _canvas_area_size.y / _bg_size.y
	_min_scale = min(scale_x, scale_y)
	_canvas_scale = _min_scale
	_canvas_offset = (_canvas_area_size - _bg_size * _canvas_scale) / 2.0
	_update_canvas_transform()
	_running = true


func _update_canvas_transform() -> void:
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


# ── Input Handling ─────────────────────────────────────────────────────────────

func _handle_touch(event: InputEventScreenTouch) -> void:
	var vp_h := get_viewport_rect().size.y
	if event.position.y < TOP_BAR_H or event.position.y > vp_h - THUMB_STRIP_H:
		return
	if event.pressed:
		_touches[event.index] = {"pos": event.position, "start": event.position}
		if _touches.size() == 2:
			_is_pinching = true
			var ids := _touches.keys()
			var e0: Dictionary = _touches[ids[0]]
			var e1: Dictionary = _touches[ids[1]]
			var p0: Vector2 = e0["pos"]
			var p1: Vector2 = e1["pos"]
			_pinch_start_dist = p0.distance_to(p1)
			_pinch_start_scale = _canvas_scale
			_pinch_start_offset = _canvas_offset
			_pinch_area_mid = (p0 + p1) / 2.0 - Vector2(0, TOP_BAR_H)
		else:
			_is_pinching = false
			_pan_start_offset = _canvas_offset
			_pan_start_pos = event.position
	else:
		if _touches.has(event.index):
			var entry: Dictionary = _touches[event.index]
			var start: Vector2 = entry["start"]
			_touches.erase(event.index)
			if not _is_pinching and event.position.distance_to(start) < TAP_MAX_MOVE:
				_handle_tap(event.position)
		if _touches.size() < 2:
			_is_pinching = false
		if _touches.size() == 1:
			var ids := _touches.keys()
			var e: Dictionary = _touches[ids[0]]
			_pan_start_offset = _canvas_offset
			_pan_start_pos = e["pos"]


func _handle_drag(event: InputEventScreenDrag) -> void:
	if not _touches.has(event.index):
		return
	var entry: Dictionary = _touches[event.index]
	entry["pos"] = event.position
	_touches[event.index] = entry

	if _is_pinching and _touches.size() == 2:
		var ids := _touches.keys()
		var e0: Dictionary = _touches[ids[0]]
		var e1: Dictionary = _touches[ids[1]]
		var p0: Vector2 = e0["pos"]
		var p1: Vector2 = e1["pos"]
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
			_update_canvas_transform()
	elif not _is_pinching and _touches.size() == 1:
		_canvas_offset = _pan_start_offset + (event.position - _pan_start_pos)
		_clamp_offset()
		_update_canvas_transform()


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	var vp_h := get_viewport_rect().size.y
	if event.position.y < TOP_BAR_H or event.position.y > vp_h - THUMB_STRIP_H:
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
			_apply_zoom(_canvas_scale * 1.12, event.position - Vector2(0, TOP_BAR_H))
		MOUSE_BUTTON_WHEEL_DOWN:
			_apply_zoom(_canvas_scale / 1.12, event.position - Vector2(0, TOP_BAR_H))


func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if not _mouse_panning:
		return
	_canvas_offset = _pan_start_offset + (event.position - _pan_start_pos)
	_clamp_offset()
	_update_canvas_transform()


func _handle_pan_gesture(event: InputEventPanGesture) -> void:
	var vp_h := get_viewport_rect().size.y
	if event.position.y < TOP_BAR_H or event.position.y > vp_h - THUMB_STRIP_H:
		return
	_canvas_offset -= event.delta * 4.0
	_clamp_offset()
	_update_canvas_transform()


func _handle_magnify_gesture(event: InputEventMagnifyGesture) -> void:
	var vp_h := get_viewport_rect().size.y
	if event.position.y < TOP_BAR_H or event.position.y > vp_h - THUMB_STRIP_H:
		return
	_apply_zoom(_canvas_scale * event.factor, event.position - Vector2(0, TOP_BAR_H))


func _apply_zoom(new_scale: float, area_center: Vector2) -> void:
	new_scale = clamp(new_scale, _min_scale, MAX_SCALE)
	var canvas_pt := (area_center - _canvas_offset) / _canvas_scale
	_canvas_scale = new_scale
	_canvas_offset = area_center - canvas_pt * _canvas_scale
	_clamp_offset()
	_update_canvas_transform()


func _handle_tap(screen_pos: Vector2) -> void:
	if not _running or _canvas_area_size == Vector2.ZERO:
		return
	var area_pos := screen_pos - Vector2(0, TOP_BAR_H)
	if area_pos.y < 0 or area_pos.y > _canvas_area_size.y:
		return
	var canvas_pos := (area_pos - _canvas_offset) / _canvas_scale
	for i in _active_items.size():
		if _found[i]:
			continue
		var runtime_data: Dictionary = _active_item_data[i]
		if canvas_pos.distance_to(runtime_data["pos"]) <= runtime_data["radius"]:
			_on_item_found(i)
			return


# ── Game Logic ─────────────────────────────────────────────────────────────────

func _on_item_found(index: int) -> void:
	_found[index] = true
	_found_count += 1
	AudioManager.play_sfx("pop")

	var card := _thumb_nodes[index]
	(card.get_child(1) as CanvasItem).visible = true  # green overlay
	(card.get_child(2) as CanvasItem).visible = true  # check label

	# Fade the canvas sprite out
	var sprite := _item_sprites[index]
	var fade := create_tween()
	fade.tween_property(sprite, "modulate:a", 0.0, 0.4)

	_show_found_flash(index)

	if _found_count >= _active_items.size():
		_on_win()


func _show_found_flash(index: int) -> void:
	var runtime_data: Dictionary = _active_item_data[index]
	var lbl := Label.new()
	lbl.text = "✓"
	lbl.add_theme_font_size_override("font_size", 80)
	lbl.add_theme_color_override("font_color", Color(0.2, 1.0, 0.2, 1))
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	lbl.add_theme_constant_override("shadow_offset_x", 2)
	lbl.add_theme_constant_override("shadow_offset_y", 2)
	lbl.position = runtime_data["pos"] - Vector2(30, 30)
	_canvas_root.add_child(lbl)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(lbl, "position", runtime_data["pos"] - Vector2(30, 90), 0.7)
	tween.tween_property(lbl, "modulate:a", 0.0, 0.7).set_delay(0.2)
	tween.chain().tween_callback(lbl.queue_free)


func _calculate_stars() -> int:
	var n := _active_items.size()
	if _elapsed < n * 10.0:
		return 3
	elif _elapsed < n * 20.0:
		return 2
	return 1


func _on_win() -> void:
	_running = false
	_won = true
	var stars := _calculate_stars()
	HideSeekState.complete_scene(_scene_name, stars)

	var star_str := ""
	for i in 3:
		star_str += "★" if i < stars else "☆"
	_win_stars_label.text = star_str

	var mins := int(_elapsed) / 60
	var secs := int(_elapsed) % 60
	_win_time_label.text = "Time: %d:%02d" % [mins, secs]

	var idx := HideSeekState.SCENE_ORDER.find(_scene_name)
	_win_next_btn.visible = idx >= 0 and idx + 1 < HideSeekState.SCENE_ORDER.size()

	_win_overlay.visible = true
	_win_overlay.modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.tween_property(_win_overlay, "modulate", Color.WHITE, 0.4)


func _update_timer() -> void:
	var mins := int(_elapsed) / 60
	var secs := int(_elapsed) % 60
	_timer_label.text = "%d:%02d" % [mins, secs]


func _update_hint_label() -> void:
	_hint_stars_label.text = "%d ★ avail." % HideSeekState.hint_stars


# ── Hint System ────────────────────────────────────────────────────────────────

func _on_hint_pressed() -> void:
	if HideSeekState.hint_stars <= 0 or _won:
		return
	var unfound: Array[int] = []
	for i in _active_items.size():
		if not _found[i]:
			unfound.append(i)
	if unfound.is_empty():
		return
	unfound.shuffle()
	HideSeekState.hint_stars -= 1
	HideSeekState.save()
	_update_hint_label()
	_show_hint(unfound[0])


func _show_hint(index: int) -> void:
	var runtime_data: Dictionary = _active_item_data[index]
	var lbl := Label.new()
	lbl.text = "⭐"
	var font_sz := int(runtime_data["radius"] * 1.5)
	lbl.add_theme_font_size_override("font_size", font_sz)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var sz: float = runtime_data["radius"] * 2.0
	lbl.custom_minimum_size = Vector2(sz, sz)
	lbl.position = runtime_data["pos"] - Vector2(runtime_data["radius"], runtime_data["radius"])
	_canvas_root.add_child(lbl)

	var pulse := create_tween()
	pulse.set_loops(3)
	pulse.tween_property(lbl, "scale", Vector2(1.4, 1.4), 0.3).set_ease(Tween.EASE_OUT)
	pulse.tween_property(lbl, "scale", Vector2(1.0, 1.0), 0.3).set_ease(Tween.EASE_IN)
	pulse.tween_callback(_fade_hint.bind(lbl))


func _fade_hint(lbl: Label) -> void:
	if not is_instance_valid(lbl):
		return
	var fade := create_tween()
	fade.tween_property(lbl, "modulate:a", 0.0, 0.5)
	fade.tween_callback(lbl.queue_free)


# ── Navigation ─────────────────────────────────────────────────────────────────

func _on_back_pressed() -> void:
	AudioManager.play_sfx("pop")
	get_tree().change_scene_to_file("res://scenes/hide_seek/HideSeekMain.tscn")


func _on_home_pressed() -> void:
	AudioManager.play_sfx("pop")
	get_tree().change_scene_to_file("res://scenes/GameSelect.tscn")


func _on_replay_pressed() -> void:
	AudioManager.play_sfx("pop")
	get_tree().change_scene_to_file("res://scenes/hide_seek/HideSeekGame.tscn")


func _on_next_pressed() -> void:
	AudioManager.play_sfx("pop")
	var idx := HideSeekState.SCENE_ORDER.find(_scene_name)
	if idx >= 0 and idx + 1 < HideSeekState.SCENE_ORDER.size():
		HideSeekState.current_scene_name = HideSeekState.SCENE_ORDER[idx + 1]
		get_tree().change_scene_to_file("res://scenes/hide_seek/HideSeekGame.tscn")


# ── Helpers ────────────────────────────────────────────────────────────────────

func _get_item_texture(item: HideSeekItemData) -> Texture2D:
	if item.thumbnail != null:
		return item.thumbnail
	var path := "res://assets/sprites/hide_seek/%s/%s.png" % [_scene_name, item.item_name]
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	var shared := "res://assets/sprites/hide_seek/shared/%s.png" % item.item_name
	if ResourceLoader.exists(shared):
		return load(shared) as Texture2D
	return null
