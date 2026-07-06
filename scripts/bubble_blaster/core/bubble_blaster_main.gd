extends Control

@onready var _bbs := get_node("/root/BubbleBlasterState")

const BUBBLE_BLASTER_ICON = preload("res://assets/icons/Bubble-Blaster_Icon.png")
const BTN_BACK = preload("res://assets/sprites/ui/button_back.png")
const SCREEN_BG = preload("res://assets/icons/screen_settings.png")
const STAR_FILLED = preload("res://assets/sprites/ui/star_filled.png")

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
	var bg := TextureRect.new()
	bg.texture = SCREEN_BG
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Back button (top-left, matching fishing and hide-and-seek screens).
	var home_btn := Button.new()
	home_btn.flat = true
	home_btn.expand_icon = true
	home_btn.focus_mode = Control.FOCUS_NONE
	home_btn.icon = BTN_BACK
	home_btn.anchors_preset = Control.PRESET_TOP_LEFT
	home_btn.custom_minimum_size = Vector2(100, 100)
	home_btn.offset_left = 12
	home_btn.offset_top = 12
	home_btn.offset_right = 112
	home_btn.offset_bottom = 112
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
	title.add_theme_color_override("font_color", Color(0.04, 0.12, 0.28, 1))
	title.add_theme_constant_override("outline_size", 8)
	title.add_theme_color_override("font_outline_color", Color.WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var pick_lbl := Label.new()
	pick_lbl.text = "Choose difficulty"
	pick_lbl.add_theme_font_size_override("font_size", 44)
	pick_lbl.add_theme_color_override("font_color", Color(0.10, 0.06, 0.22))
	pick_lbl.add_theme_color_override("font_outline_color", Color.WHITE)
	pick_lbl.add_theme_constant_override("outline_size", 5)
	pick_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(pick_lbl)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 48)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(hbox)

	for i in 3:
		var btn := _make_diff_btn(i)
		hbox.add_child(btn)

	# Star bank display — star icon + count
	var bank_row := HBoxContainer.new()
	bank_row.alignment = BoxContainer.ALIGNMENT_CENTER
	bank_row.add_theme_constant_override("separation", 10)
	vbox.add_child(bank_row)

	var star_img := TextureRect.new()
	star_img.texture = STAR_FILLED
	star_img.custom_minimum_size = Vector2(48, 48)
	star_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	star_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	star_img.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bank_row.add_child(star_img)

	var bank_lbl := Label.new()
	bank_lbl.text = str(_bbs.star_bank)
	bank_lbl.add_theme_font_size_override("font_size", 44)
	bank_lbl.add_theme_color_override("font_color", Color(0.12, 0.08, 0.05))
	bank_lbl.add_theme_color_override("font_outline_color", Color.WHITE)
	bank_lbl.add_theme_constant_override("outline_size", 5)
	bank_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bank_row.add_child(bank_lbl)

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
	_bbs.current_difficulty = diff
	get_tree().change_scene_to_file("res://scenes/bubble_blaster/BubbleBlasterGame.tscn")

func _on_home() -> void:
	get_tree().change_scene_to_file("res://scenes/GameSelect.tscn")
