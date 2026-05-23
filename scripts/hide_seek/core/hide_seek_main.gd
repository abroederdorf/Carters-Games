extends Control

const CARDS_PER_PAGE := 8
const COLS := 4
const ROWS := 2

var _current_page: int = 0
var _total_pages: int = 0
var _page_width: float = 0.0

var _scroll: ScrollContainer
var _pages_container: HBoxContainer
var _btn_prev: Button
var _btn_next: Button
var _dots_container: HBoxContainer
var _page_vboxes: Array[VBoxContainer] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_update_pagination_ui()
	await get_tree().process_frame
	_fit_pages_to_scroll()
	_scroll.resized.connect(_fit_pages_to_scroll)


func _build_ui() -> void:
	# Background
	var bg := TextureRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.texture = preload("res://assets/icons/screen_settings.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 60)
	margin.add_theme_constant_override("margin_right", 60)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	margin.add_child(vbox)

	# ── Header ──────────────────────────────────────────────────────────────
	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 80
	vbox.add_child(header)

	var back_btn := Button.new()
	back_btn.flat = true
	back_btn.expand_icon = true
	back_btn.icon = preload("res://assets/sprites/ui/button_back.png")
	back_btn.custom_minimum_size = Vector2(100, 100)
	back_btn.focus_mode = Control.FOCUS_NONE
	back_btn.pressed.connect(_on_back_pressed)
	header.add_child(back_btn)

	var pad_l := Control.new()
	pad_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(pad_l)

	var title := Label.new()
	title.text = "Find It!"
	title.add_theme_font_size_override("font_size", 72)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.04, 0.12, 0.28, 1))
	header.add_child(title)

	var pad_r := Control.new()
	pad_r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(pad_r)

	var mute_btn := Button.new()
	mute_btn.flat = true
	mute_btn.expand_icon = true
	mute_btn.icon = load("res://assets/sprites/ui/button_mute.png") if AudioManager.master_mute else load("res://assets/sprites/ui/button_sound.png")
	mute_btn.custom_minimum_size = Vector2(80, 80)
	mute_btn.focus_mode = Control.FOCUS_NONE
	mute_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mute_btn.pressed.connect(func() -> void:
		AudioManager.toggle_mute()
		mute_btn.icon = load("res://assets/sprites/ui/button_mute.png") if AudioManager.master_mute else load("res://assets/sprites/ui/button_sound.png")
	)
	header.add_child(mute_btn)

	# ── Paginated Grid ──────────────────────────────────────────────────────
	var grid_area := HBoxContainer.new()
	grid_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(grid_area)

	# Floating Prev Button
	_btn_prev = Button.new()
	_btn_prev.flat = true
	_btn_prev.expand_icon = true
	_btn_prev.icon = preload("res://assets/sprites/ui/button_page_prev.png")
	_btn_prev.custom_minimum_size = Vector2(80, 400)
	_btn_prev.focus_mode = Control.FOCUS_NONE
	_btn_prev.pressed.connect(_on_prev_pressed)
	grid_area.add_child(_btn_prev)

	# Scroll Viewport
	_scroll = ScrollContainer.new()
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	grid_area.add_child(_scroll)

	_pages_container = HBoxContainer.new()
	_pages_container.add_theme_constant_override("separation", 0)
	_pages_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_pages_container)

	# Floating Next Button
	_btn_next = Button.new()
	_btn_next.flat = true
	_btn_next.expand_icon = true
	_btn_next.icon = preload("res://assets/sprites/ui/button_page_next.png")
	_btn_next.custom_minimum_size = Vector2(80, 400)
	_btn_next.focus_mode = Control.FOCUS_NONE
	_btn_next.pressed.connect(_on_next_pressed)
	grid_area.add_child(_btn_next)

	# ── Build Pages ─────────────────────────────────────────────────────────
	var scenes := HideSeekState.SCENE_ORDER
	_total_pages = ceil(scenes.size() / float(CARDS_PER_PAGE))
	
	# We need to calculate page width after the layout is established.
	# For now, we'll use a placeholder or wait for a frame.
	# But in _ready, the viewport size is usually known.
	# Each page will take 100% of the _scroll width.
	
	for p in _total_pages:
		var page_vbox := VBoxContainer.new()
		page_vbox.add_theme_constant_override("separation", 24)
		page_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		page_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_pages_container.add_child(page_vbox)
		_page_vboxes.append(page_vbox)
		
		var start_idx := p * CARDS_PER_PAGE
		for r in ROWS:
			var hbox := HBoxContainer.new()
			hbox.add_theme_constant_override("separation", 24)
			hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
			page_vbox.add_child(hbox)
			for c in COLS:
				var idx := start_idx + (r * COLS + c)
				if idx < scenes.size():
					var card := _make_card(scenes[idx])
					hbox.add_child(card)
				else:
					# Empty slot for layout consistency
					var empty := Control.new()
					empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					hbox.add_child(empty)

	# ── Dot Indicator ───────────────────────────────────────────────────────
	_dots_container = HBoxContainer.new()
	_dots_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_dots_container.add_theme_constant_override("separation", 20)
	vbox.add_child(_dots_container)
	
	for p in _total_pages:
		var dot := Panel.new()
		dot.custom_minimum_size = Vector2(20, 20)
		_dots_container.add_child(dot)

	# Initial UI state update
	_update_pagination_ui()


func _update_pagination_ui() -> void:
	if _btn_prev == null: return

	_btn_prev.modulate.a = 1.0 if _current_page > 0 else 0.0
	_btn_prev.mouse_filter = Control.MOUSE_FILTER_STOP if _current_page > 0 else Control.MOUSE_FILTER_IGNORE
	_btn_next.modulate.a = 1.0 if _current_page < _total_pages - 1 else 0.0
	_btn_next.mouse_filter = Control.MOUSE_FILTER_STOP if _current_page < _total_pages - 1 else Control.MOUSE_FILTER_IGNORE
	
	# Update dots
	var active_style := _dot_style(Color.WHITE)
	var inactive_style := _dot_style(Color(0, 0, 0, 0.4))
	
	for i in _dots_container.get_child_count():
		var dot: Panel = _dots_container.get_child(i)
		dot.add_theme_stylebox_override("panel", active_style if i == _current_page else inactive_style)


func _dot_style(color: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(10)
	return s


func _make_card(scene_name: String) -> Button:
	var unlocked := HideSeekState.is_unlocked(scene_name)
	var stars := HideSeekState.get_stars(scene_name)

	var style_normal := _card_stylebox(Color(0.08, 0.28, 0.12, 1), Color(0.14, 0.52, 0.22, 1))
	var style_pressed := _card_stylebox(Color(0.04, 0.16, 0.08, 1), Color(0.14, 0.52, 0.22, 1))

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(360, 300)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	btn.focus_mode = Control.FOCUS_NONE
	btn.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_normal)
	btn.add_theme_stylebox_override("pressed", style_pressed)

	# Background scene image
	var bg_candidates: Array[String] = [
		"res://assets/sprites/hide_seek/%s/bg_%s.png" % [scene_name, scene_name],
		"res://assets/sprites/hide_seek/%s/bg_%s.png" % [scene_name, scene_name.trim_suffix("s")],
		"res://assets/sprites/hide_seek/%s/bg_%s.png" % [scene_name, scene_name.split("_")[0]],
		"res://assets/sprites/hide_seek/%s/bg_%s.png" % [scene_name, scene_name.replace("_land", "")],
		"res://assets/sprites/hide_seek/%s/bg_%s.png" % [scene_name, scene_name.replace("_site", "")],
		"res://assets/sprites/hide_seek/%s/bg_%s.png" % [scene_name, scene_name.replace("monster_truck_jam", "monster_jam")],
		"res://assets/sprites/hide_seek/%s/bg.png" % scene_name,
		"res://assets/sprites/hide_seek/%s/bg_fast.png" % scene_name,
	]
	
	var bg_path := ""
	for path in bg_candidates:
		if ResourceLoader.exists(path):
			bg_path = path
			break
		
	if bg_path != "":
		var tex_rect := TextureRect.new()
		tex_rect.texture = load(bg_path)
		tex_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(tex_rect)

	# Bottom gradient for name legibility
	var gradient := ColorRect.new()
	gradient.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	gradient.offset_top = -110.0
	gradient.color = Color(0, 0, 0, 0.70)
	gradient.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(gradient)

	# Scene name
	var name_lbl := Label.new()
	name_lbl.text = HideSeekState.DISPLAY_NAMES.get(scene_name, scene_name)
	name_lbl.add_theme_font_size_override("font_size", 28)
	name_lbl.add_theme_color_override("font_color", Color.WHITE)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	name_lbl.offset_top = -100.0
	name_lbl.offset_bottom = -50.0
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(name_lbl)

	# Stars
	var star_hbox := HBoxContainer.new()
	star_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	star_hbox.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	star_hbox.offset_top = -50.0
	star_hbox.offset_bottom = -10.0
	star_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(star_hbox)

	var star_filled := preload("res://assets/sprites/ui/star_filled.png")
	var star_empty := preload("res://assets/sprites/ui/star_empty.png")
	for i in 3:
		var s := TextureRect.new()
		s.texture = star_filled if i < stars else star_empty
		s.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		s.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		s.custom_minimum_size = Vector2(32, 32)
		star_hbox.add_child(s)

	if not unlocked:
		var lock_overlay := ColorRect.new()
		lock_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		lock_overlay.color = Color(0, 0, 0, 0.65)
		lock_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(lock_overlay)

		var lock_icon := TextureRect.new()
		lock_icon.texture = preload("res://assets/sprites/ui/lock.png")
		lock_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		lock_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		lock_icon.custom_minimum_size = Vector2(80, 80)
		lock_icon.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		lock_icon.grow_horizontal = Control.GROW_DIRECTION_BOTH
		lock_icon.grow_vertical = Control.GROW_DIRECTION_BOTH
		lock_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(lock_icon)

		btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	else:
		btn.pressed.connect(_on_scene_pressed.bind(scene_name))

	return btn


func _card_stylebox(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.corner_radius_top_left = 20
	s.corner_radius_top_right = 20
	s.corner_radius_bottom_right = 20
	s.corner_radius_bottom_left = 20
	s.border_width_left = 4
	s.border_width_top = 4
	s.border_width_right = 4
	s.border_width_bottom = 4
	s.border_color = border
	return s


func _on_back_pressed() -> void:
	AudioManager.play_sfx("pop")
	get_tree().change_scene_to_file("res://scenes/GameSelect.tscn")


func _on_scene_pressed(scene_name: String) -> void:
	AudioManager.play_sfx("pop")
	HideSeekState.current_scene_name = scene_name
	if ResourceLoader.exists("res://scenes/hide_seek/HideSeekGame.tscn"):
		get_tree().change_scene_to_file("res://scenes/hide_seek/HideSeekGame.tscn")


func _on_prev_pressed() -> void:
	if _current_page > 0:
		_current_page -= 1
		_scroll_to_page()


func _on_next_pressed() -> void:
	if _current_page < _total_pages - 1:
		_current_page += 1
		_scroll_to_page()


func _fit_pages_to_scroll() -> void:
	var w := _scroll.size.x
	if w <= 0:
		return
	_page_width = w
	for page in _page_vboxes:
		page.custom_minimum_size.x = w
	_scroll.scroll_horizontal = int(_current_page * _page_width)


func _scroll_to_page() -> void:
	AudioManager.play_sfx("pop")
	var target_scroll := _current_page * _page_width
	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(_scroll, "scroll_horizontal", int(target_scroll), 0.4)
	_update_pagination_ui()
