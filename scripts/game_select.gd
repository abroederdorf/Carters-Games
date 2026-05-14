extends Control

const SPLASH_BG = preload("res://assets/icons/splash_screen.png")
const GONE_FISHIN_ICON = preload("res://assets/icons/Gone-Fishin_Icon.png")
const FIND_IT_ICON = preload("res://assets/icons/Find-It_Icon.png")
const SOUND_ON = preload("res://assets/sprites/ui/button_sound.png")
const SOUND_OFF = preload("res://assets/sprites/ui/button_mute.png")

var _mute_btn: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()

func _build_ui() -> void:
	var bg := TextureRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.texture = SPLASH_BG
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 50)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(vbox)

	var title := Label.new()
	title.text = "Carter's Games"
	title.add_theme_font_size_override("font_size", 80)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.04, 0.12, 0.28, 1))
	title.add_theme_color_override("font_shadow_color", Color.WHITE)
	title.add_theme_constant_override("shadow_offset_x", 0)
	title.add_theme_constant_override("shadow_offset_y", 0)
	title.add_theme_constant_override("shadow_outline_size", 6)
	title.add_theme_color_override("font_outline_color", Color.WHITE)
	title.add_theme_constant_override("outline_size", 8)
	vbox.add_child(title)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 60)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(hbox)

	var fish_card := _make_game_card(
		"Gone Fishin'",
		GONE_FISHIN_ICON,
		Color(0.06, 0.38, 0.72, 1),
		Color(0.02, 0.20, 0.48, 1)
	)
	fish_card.pressed.connect(_on_fishing_pressed)
	hbox.add_child(fish_card)

	var find_card := _make_game_card(
		"Find It!",
		FIND_IT_ICON,
		Color(0.10, 0.54, 0.22, 1),
		Color(0.04, 0.30, 0.10, 1)
	)
	if ResourceLoader.exists("res://scenes/hide_seek/HideSeekMain.tscn"):
		find_card.pressed.connect(_on_find_it_pressed)
	else:
		find_card.modulate = Color(1, 1, 1, 0.45)
		find_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(find_card)

	_mute_btn = Button.new()
	_mute_btn.flat = true
	_mute_btn.expand_icon = true
	_mute_btn.focus_mode = Control.FOCUS_NONE
	_mute_btn.anchors_preset = Control.PRESET_TOP_RIGHT
	_mute_btn.anchor_left = 1.0
	_mute_btn.anchor_right = 1.0
	_mute_btn.offset_left = -90.0
	_mute_btn.offset_top = 8.0
	_mute_btn.offset_right = -10.0
	_mute_btn.offset_bottom = 88.0
	_mute_btn.pressed.connect(_on_mute_pressed)
	add_child(_mute_btn)
	_update_mute_icon()

func _make_game_card(title: String, icon: Texture2D, color: Color, border: Color) -> Button:
	var style_n := StyleBoxFlat.new()
	style_n.bg_color = color
	style_n.corner_radius_top_left = 28
	style_n.corner_radius_top_right = 28
	style_n.corner_radius_bottom_right = 28
	style_n.corner_radius_bottom_left = 28
	style_n.border_width_left = 5
	style_n.border_width_top = 5
	style_n.border_width_right = 5
	style_n.border_width_bottom = 5
	style_n.border_color = border

	var style_p := StyleBoxFlat.new()
	style_p.bg_color = border
	style_p.corner_radius_top_left = 28
	style_p.corner_radius_top_right = 28
	style_p.corner_radius_bottom_right = 28
	style_p.corner_radius_bottom_left = 28
	style_p.border_width_left = 5
	style_p.border_width_top = 5
	style_p.border_width_right = 5
	style_p.border_width_bottom = 5
	style_p.border_color = border

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(280, 320)
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_stylebox_override("normal", style_n)
	btn.add_theme_stylebox_override("hover", style_n)
	btn.add_theme_stylebox_override("pressed", style_p)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 16)
	inner.alignment = BoxContainer.ALIGNMENT_CENTER
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(inner)

	var img := TextureRect.new()
	img.texture = icon
	img.custom_minimum_size = Vector2(160, 160)
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(img)

	var lbl := Label.new()
	lbl.text = title
	lbl.add_theme_font_size_override("font_size", 40)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(lbl)

	return btn

func _on_fishing_pressed() -> void:
	AudioManager.play_sfx("pop")
	get_tree().change_scene_to_file("res://scenes/fishing/game.tscn")

func _on_find_it_pressed() -> void:
	AudioManager.play_sfx("pop")
	get_tree().change_scene_to_file("res://scenes/hide_seek/HideSeekMain.tscn")

func _on_mute_pressed() -> void:
	AudioManager.toggle_mute()
	_update_mute_icon()

func _update_mute_icon() -> void:
	_mute_btn.icon = SOUND_OFF if AudioManager.master_mute else SOUND_ON
