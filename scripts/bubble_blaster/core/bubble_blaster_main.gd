extends Control

const BUBBLE_BLASTER_ICON = preload("res://assets/icons/Bubble-Blaster_Icon.png")
const BTN_HOME = preload("res://assets/sprites/ui/button_home.png")

const DIFFICULTIES: Array[String] = ["Easy", "Medium", "Hard"]
const DIFF_COLORS: Array[Color] = [
	Color(0.10, 0.55, 0.20, 1),  # Easy  — green
	Color(0.10, 0.38, 0.78, 1),  # Medium — blue
	Color(0.75, 0.12, 0.12, 1),  # Hard  — red
]
const DIFF_BORDERS: Array[Color] = [
	Color(0.04, 0.30, 0.10, 1),
	Color(0.02, 0.20, 0.50, 1),
	Color(0.45, 0.04, 0.04, 1),
]

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.04, 0.14)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Home button
	var home_btn := Button.new()
	home_btn.flat = true
	home_btn.expand_icon = true
	home_btn.focus_mode = Control.FOCUS_NONE
	home_btn.icon = BTN_HOME
	home_btn.anchors_preset = Control.PRESET_TOP_LEFT
	home_btn.custom_minimum_size = Vector2(80, 80)
	home_btn.offset_left = 12
	home_btn.offset_top = 12
	home_btn.offset_right = 92
	home_btn.offset_bottom = 92
	home_btn.pressed.connect(_on_home)
	add_child(home_btn)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 48)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(vbox)

	# Icon + title
	var icon := TextureRect.new()
	icon.texture = BUBBLE_BLASTER_ICON
	icon.custom_minimum_size = Vector2(140, 140)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(icon)

	var title := Label.new()
	title.text = "Bubble Blast"
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.add_theme_constant_override("outline_size", 7)
	title.add_theme_color_override("font_outline_color", Color(0.25, 0.08, 0.45))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var pick_lbl := Label.new()
	pick_lbl.text = "Choose difficulty"
	pick_lbl.add_theme_font_size_override("font_size", 44)
	pick_lbl.add_theme_color_override("font_color", Color(0.80, 0.80, 1.0))
	pick_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(pick_lbl)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 48)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(hbox)

	for i in 3:
		var btn := _make_diff_btn(i)
		hbox.add_child(btn)

	# Star bank display
	var bank_lbl := Label.new()
	bank_lbl.text = "Star bank: %d" % BubbleBlasterState.star_bank
	bank_lbl.add_theme_font_size_override("font_size", 38)
	bank_lbl.add_theme_color_override("font_color", Color(1.0, 0.90, 0.40))
	bank_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(bank_lbl)

func _make_diff_btn(diff_idx: int) -> Button:
	var style_n := StyleBoxFlat.new()
	style_n.bg_color = DIFF_COLORS[diff_idx]
	style_n.corner_radius_top_left = 24
	style_n.corner_radius_top_right = 24
	style_n.corner_radius_bottom_left = 24
	style_n.corner_radius_bottom_right = 24
	style_n.border_width_left = 4
	style_n.border_width_top = 4
	style_n.border_width_right = 4
	style_n.border_width_bottom = 4
	style_n.border_color = DIFF_BORDERS[diff_idx]

	var style_p := StyleBoxFlat.new()
	style_p.bg_color = DIFF_BORDERS[diff_idx]
	style_p.corner_radius_top_left = 24
	style_p.corner_radius_top_right = 24
	style_p.corner_radius_bottom_left = 24
	style_p.corner_radius_bottom_right = 24

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(220, 120)
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_stylebox_override("normal", style_n)
	btn.add_theme_stylebox_override("hover", style_n)
	btn.add_theme_stylebox_override("pressed", style_p)

	var lbl := Label.new()
	lbl.text = DIFFICULTIES[diff_idx]
	lbl.add_theme_font_size_override("font_size", 48)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(lbl)

	btn.pressed.connect(func() -> void: _on_difficulty(diff_idx))
	return btn

func _on_difficulty(diff: int) -> void:
	BubbleBlasterState.current_difficulty = diff
	get_tree().change_scene_to_file("res://scenes/bubble_blaster/BubbleBlasterGame.tscn")

func _on_home() -> void:
	get_tree().change_scene_to_file("res://scenes/GameSelect.tscn")
