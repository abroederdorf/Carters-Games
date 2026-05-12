extends Control

const SCENE_ORDER: Array[String] = [
	"mountains",
	"ocean",
	"jungle",
	"space",
	"dinosaur_land",
	"fire_station",
	"monster_truck_jam",
	"construction_site",
]

const DISPLAY_NAMES: Dictionary = {
	"mountains": "Mountains",
	"ocean": "Ocean",
	"jungle": "Jungle",
	"space": "Space",
	"dinosaur_land": "Dinosaur Land",
	"fire_station": "Fire Station",
	"monster_truck_jam": "Monster Truck Jam",
	"construction_site": "Construction Site",
}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.18, 0.08, 1)
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
	back_btn.text = "Back"
	back_btn.custom_minimum_size = Vector2(180, 70)
	back_btn.add_theme_font_size_override("font_size", 34)
	back_btn.focus_mode = Control.FOCUS_NONE
	back_btn.pressed.connect(_on_back_pressed)
	header.add_child(back_btn)

	var pad_l := Control.new()
	pad_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(pad_l)

	var title := Label.new()
	title.text = "Find It!"
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_child(title)

	var pad_r := Control.new()
	pad_r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(pad_r)

	# ── Scene grid: two rows of four ────────────────────────────────────────
	for row in 2:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 24)
		hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vbox.add_child(hbox)
		for col in 4:
			var idx := row * 4 + col
			var card := _make_card(SCENE_ORDER[idx])
			hbox.add_child(card)

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
	var bg_path := "res://assets/sprites/hide_seek/%s/bg.png" % scene_name
	if not ResourceLoader.exists(bg_path):
		bg_path = "res://assets/sprites/hide_seek/%s/bg_fast.png" % scene_name
		
	if ResourceLoader.exists(bg_path):
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
	gradient.offset_top = -90.0
	gradient.color = Color(0, 0, 0, 0.70)
	gradient.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(gradient)

	# Scene name
	var name_lbl := Label.new()
	name_lbl.text = DISPLAY_NAMES.get(scene_name, scene_name)
	name_lbl.add_theme_font_size_override("font_size", 30)
	name_lbl.add_theme_color_override("font_color", Color.WHITE)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	name_lbl.offset_top = -84.0
	name_lbl.offset_bottom = -46.0
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(name_lbl)

	# Stars
	var star_lbl := Label.new()
	var star_str := ""
	for i in 3:
		star_str += "*" if i < stars else "-"
	star_lbl.text = star_str
	star_lbl.add_theme_font_size_override("font_size", 30)
	star_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1, 1))
	star_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	star_lbl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	star_lbl.offset_top = -44.0
	star_lbl.offset_bottom = -6.0
	star_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(star_lbl)

	if not unlocked:
		var lock_overlay := ColorRect.new()
		lock_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		lock_overlay.color = Color(0, 0, 0, 0.65)
		lock_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(lock_overlay)

		var lock_icon := TextureRect.new()
		lock_icon.texture = preload("res://assets/sprites/words/lock.svg")
		lock_icon.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
		lock_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		lock_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
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
