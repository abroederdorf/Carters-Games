class_name HideSeekUI
extends Node

signal hint_pressed
signal back_pressed
signal home_pressed
signal replay_pressed
signal next_pressed

const TOP_BAR_H := 80.0
const THUMB_STRIP_H := 150.0
const THUMB_SIZE := 110.0

var _timer_label: Label
var _hint_stars_label: Label
var _thumb_nodes: Array[Control] = []
var _win_overlay: Control
var _win_stars_label: Label
var _win_time_label: Label
var _win_next_btn: TextureButton
var _mute_btn: TextureButton

var _texture_fn: Callable


func build(parent: Control, items: Array[HideSeekItemData], texture_fn: Callable) -> void:
	_texture_fn = texture_fn
	_build_top_bar(parent)
	_build_thumb_strip(parent, items)
	_build_win_overlay(parent)


func mark_found(index: int) -> void:
	var card := _thumb_nodes[index]
	card.get_child(1).visible = true  # green overlay
	card.get_child(2).visible = true  # checkmark


func update_timer(elapsed: float) -> void:
	var mins := int(elapsed) / 60
	var secs := int(elapsed) % 60
	_timer_label.text = "%d:%02d" % [mins, secs]


func update_hint_label(hint_stars: int) -> void:
	_hint_stars_label.text = "%d" % hint_stars

func _on_mute_pressed() -> void:
	AudioManager.toggle_mute()
	_update_mute_icon()

func _update_mute_icon() -> void:
	if _mute_btn == null:
		return
	_mute_btn.texture_normal = load("res://assets/sprites/ui/button_mute.png") if AudioManager.master_mute else load("res://assets/sprites/ui/button_sound.png")


func show_win(stars: int, elapsed: float, has_next: bool) -> void:
	var star_hbox: HBoxContainer = _win_overlay.find_child("StarHBox", true, false)
	for child in star_hbox.get_children():
		child.queue_free()
		
	for i in 3:
		var stex := TextureRect.new()
		stex.texture = load("res://assets/sprites/ui/star_filled.png") if i < stars else load("res://assets/sprites/ui/star_empty.png")
		stex.custom_minimum_size = Vector2(120, 120)
		stex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		stex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		star_hbox.add_child(stex)

	var mins := int(elapsed) / 60
	var secs := int(elapsed) % 60
	_win_time_label.text = "Time: %d:%02d" % [mins, secs]

	_win_next_btn.visible = has_next
	_win_overlay.visible = true
	_win_overlay.modulate = Color(1, 1, 1, 0)
	var tween := get_tree().create_tween()
	tween.tween_property(_win_overlay, "modulate", Color.WHITE, 0.4)


# ── UI Construction ────────────────────────────────────────────────────────────

func _build_top_bar(parent: Control) -> void:
	var bar := ColorRect.new()
	bar.anchor_left = 0.0
	bar.anchor_top = 0.0
	bar.anchor_right = 1.0
	bar.anchor_bottom = 0.0
	bar.offset_bottom = TOP_BAR_H
	bar.color = Color(0, 0, 0, 0.6)
	bar.z_index = 10
	parent.add_child(bar)

	var hbox := HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 16)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_child(hbox)

	var pad_l := Control.new()
	pad_l.custom_minimum_size.x = 20
	hbox.add_child(pad_l)

	var back_btn := TextureButton.new()
	back_btn.texture_normal = load("res://assets/sprites/ui/button_back.png")
	back_btn.ignore_texture_size = true
	back_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	back_btn.custom_minimum_size = Vector2(140, 60)
	back_btn.focus_mode = Control.FOCUS_NONE
	back_btn.pressed.connect(func(): back_pressed.emit())
	hbox.add_child(back_btn)

	var spacer_l := Control.new()
	spacer_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer_l)

	_timer_label = Label.new()
	_timer_label.text = "0:00"
	_timer_label.add_theme_font_size_override("font_size", 42)
	_timer_label.add_theme_color_override("font_color", Color.WHITE)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_label.custom_minimum_size.x = 120
	hbox.add_child(_timer_label)

	var spacer_r := Control.new()
	spacer_r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer_r)

	_hint_stars_label = Label.new()
	_hint_stars_label.add_theme_font_size_override("font_size", 32)
	_hint_stars_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2, 1))
	_hint_stars_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	_hint_stars_label.add_theme_constant_override("shadow_offset_x", 2)
	_hint_stars_label.add_theme_constant_override("shadow_offset_y", 2)
	_hint_stars_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(_hint_stars_label)

	var hint_btn := TextureButton.new()
	hint_btn.texture_normal = load("res://assets/sprites/ui/button_hint.png")
	hint_btn.ignore_texture_size = true
	hint_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	hint_btn.custom_minimum_size = Vector2(70, 70)
	hint_btn.focus_mode = Control.FOCUS_NONE
	hint_btn.pressed.connect(func(): hint_pressed.emit())
	hbox.add_child(hint_btn)

	_mute_btn = TextureButton.new()
	_mute_btn.ignore_texture_size = true
	_mute_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	_mute_btn.custom_minimum_size = Vector2(70, 70)
	_mute_btn.focus_mode = Control.FOCUS_NONE
	_mute_btn.pressed.connect(_on_mute_pressed)
	hbox.add_child(_mute_btn)
	_update_mute_icon()

	var pad_r := Control.new()
	pad_r.custom_minimum_size.x = 20
	hbox.add_child(pad_r)


func _build_thumb_strip(parent: Control, items: Array[HideSeekItemData]) -> void:
	var strip := ColorRect.new()
	strip.anchor_left = 0.0
	strip.anchor_top = 1.0
	strip.anchor_right = 1.0
	strip.anchor_bottom = 1.0
	strip.offset_top = -THUMB_STRIP_H
	strip.color = Color(0, 0, 0, 0.6)
	strip.z_index = 10
	parent.add_child(strip)

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
	hbox.add_theme_constant_override("separation", 12)
	hbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	scroll.add_child(hbox)

	for item: HideSeekItemData in items:
		var card := _make_thumb_card(item)
		_thumb_nodes.append(card)
		hbox.add_child(card)


func _make_thumb_card(item: HideSeekItemData) -> Control:
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(THUMB_SIZE, THUMB_SIZE)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.9, 0.9, 0.9, 1.0) # Light off-white for high contrast
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color(1, 1, 1, 0.4)
	panel.add_theme_stylebox_override("panel", style)

	var tex_rect := TextureRect.new()
	tex_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.texture = _texture_fn.call(item)
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(tex_rect)

	var check_bg := ColorRect.new()
	check_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	check_bg.color = Color(0.1, 0.8, 0.2, 0.5)
	check_bg.visible = false
	check_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(check_bg)

	var check_tex := TextureRect.new()
	check_tex.texture = load("res://assets/sprites/ui/checkmark.png")
	check_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	check_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	check_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	check_tex.offset_left = 10
	check_tex.offset_top = 10
	check_tex.offset_right = -10
	check_tex.offset_bottom = -10
	check_tex.visible = false
	check_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(check_tex)

	return panel


func _build_win_overlay(parent: Control) -> void:
	_win_overlay = ColorRect.new()
	_win_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	(_win_overlay as ColorRect).color = Color(0, 0, 0, 0.85)
	_win_overlay.z_index = 20
	_win_overlay.visible = false
	parent.add_child(_win_overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_win_overlay.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 32)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(vbox)

	var title := Label.new()
	title.text = "Success!"
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var star_hbox := HBoxContainer.new()
	star_hbox.name = "StarHBox"
	star_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	star_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(star_hbox)
	
	_win_stars_label = Label.new()
	_win_stars_label.visible = false
	vbox.add_child(_win_stars_label)

	_win_time_label = Label.new()
	_win_time_label.add_theme_font_size_override("font_size", 32)
	_win_time_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	_win_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_win_time_label)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 40)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_row)

	var home_btn := TextureButton.new()
	home_btn.texture_normal = load("res://assets/sprites/ui/button_home.png")
	home_btn.custom_minimum_size = Vector2(100, 100)
	home_btn.ignore_texture_size = true
	home_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	home_btn.focus_mode = Control.FOCUS_NONE
	home_btn.pressed.connect(func(): home_pressed.emit())
	btn_row.add_child(home_btn)

	var replay_btn := TextureButton.new()
	replay_btn.texture_normal = load("res://assets/sprites/ui/button_replay.png")
	replay_btn.custom_minimum_size = Vector2(100, 100)
	replay_btn.ignore_texture_size = true
	replay_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	replay_btn.focus_mode = Control.FOCUS_NONE
	replay_btn.pressed.connect(func(): replay_pressed.emit())
	btn_row.add_child(replay_btn)

	_win_next_btn = TextureButton.new()
	_win_next_btn.texture_normal = load("res://assets/sprites/ui/button_next.png")
	_win_next_btn.custom_minimum_size = Vector2(140, 80)
	_win_next_btn.ignore_texture_size = true
	_win_next_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	_win_next_btn.focus_mode = Control.FOCUS_NONE
	_win_next_btn.pressed.connect(func(): next_pressed.emit())
	btn_row.add_child(_win_next_btn)
