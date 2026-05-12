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
var _win_next_btn: Button

var _texture_fn: Callable


func build(parent: Control, items: Array[HideSeekItemData], texture_fn: Callable) -> void:
	_texture_fn = texture_fn
	_build_top_bar(parent)
	_build_thumb_strip(parent, items)
	_build_win_overlay(parent)


func mark_found(index: int) -> void:
	var card := _thumb_nodes[index]
	card.get_child(1).visible = true  # green overlay
	card.get_child(2).visible = true  # check label


func update_timer(elapsed: float) -> void:
	var mins := int(elapsed) / 60
	var secs := int(elapsed) % 60
	_timer_label.text = "%d:%02d" % [mins, secs]


func update_hint_label(hint_stars: int) -> void:
	_hint_stars_label.text = "%d avail." % hint_stars


func show_win(stars: int, elapsed: float, has_next: bool) -> void:
	var star_str := ""
	for i in 3:
		star_str += "*" if i < stars else "-"
	_win_stars_label.text = star_str

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
	bar.color = Color(0, 0, 0, 0.8)
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

	var back_btn := Button.new()
	back_btn.text = "Back"
	back_btn.custom_minimum_size = Vector2(160, 58)
	back_btn.add_theme_font_size_override("font_size", 28)
	back_btn.focus_mode = Control.FOCUS_NONE
	back_btn.pressed.connect(func(): back_pressed.emit())
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
	hint_btn.text = "Hint"
	hint_btn.custom_minimum_size = Vector2(150, 44)
	hint_btn.add_theme_font_size_override("font_size", 26)
	hint_btn.focus_mode = Control.FOCUS_NONE
	hint_btn.pressed.connect(func(): hint_pressed.emit())
	hint_vbox.add_child(hint_btn)

	_hint_stars_label = Label.new()
	_hint_stars_label.add_theme_font_size_override("font_size", 20)
	_hint_stars_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1, 1))
	_hint_stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_vbox.add_child(_hint_stars_label)

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
	strip.color = Color(0, 0, 0, 0.8)
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
	hbox.add_theme_constant_override("separation", 10)
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

	var tex_rect := TextureRect.new()
	tex_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.texture = _texture_fn.call(item)
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(tex_rect)

	var check_bg := ColorRect.new()
	check_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	check_bg.color = Color(0.1, 0.65, 0.1, 0.65)
	check_bg.visible = false
	check_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(check_bg)

	var check_lbl := Label.new()
	check_lbl.text = "+"
	check_lbl.add_theme_font_size_override("font_size", 52)
	check_lbl.add_theme_color_override("font_color", Color.WHITE)
	check_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	check_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	check_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	check_lbl.visible = false
	check_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(check_lbl)

	return panel


func _build_win_overlay(parent: Control) -> void:
	_win_overlay = ColorRect.new()
	_win_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	(_win_overlay as ColorRect).color = Color(0, 0, 0, 0.78)
	_win_overlay.z_index = 20
	_win_overlay.visible = false
	parent.add_child(_win_overlay)

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
	home_btn.text = "Home"
	home_btn.custom_minimum_size = Vector2(210, 74)
	home_btn.add_theme_font_size_override("font_size", 34)
	home_btn.focus_mode = Control.FOCUS_NONE
	home_btn.pressed.connect(func(): home_pressed.emit())
	btn_row.add_child(home_btn)

	var replay_btn := Button.new()
	replay_btn.text = "Replay"
	replay_btn.custom_minimum_size = Vector2(210, 74)
	replay_btn.add_theme_font_size_override("font_size", 34)
	replay_btn.focus_mode = Control.FOCUS_NONE
	replay_btn.pressed.connect(func(): replay_pressed.emit())
	btn_row.add_child(replay_btn)

	_win_next_btn = Button.new()
	_win_next_btn.text = "Next"
	_win_next_btn.custom_minimum_size = Vector2(210, 74)
	_win_next_btn.add_theme_font_size_override("font_size", 34)
	_win_next_btn.focus_mode = Control.FOCUS_NONE
	_win_next_btn.pressed.connect(func(): next_pressed.emit())
	btn_row.add_child(_win_next_btn)
