class_name BubbleBlasterUI
extends CanvasLayer

const STAR_FILLED = preload("res://assets/sprites/ui/star_filled.png")
const STAR_EMPTY  = preload("res://assets/sprites/ui/star_empty.png")
const BTN_HOME    = preload("res://assets/sprites/ui/button_home.png")
const BTN_REPLAY  = preload("res://assets/sprites/ui/button_replay.png")
const BTN_NEXT    = preload("res://assets/sprites/ui/button_next.png")

signal retry_same
signal new_game
signal refill_requested
signal go_home

var _panel: PanelContainer
var _star_row: HBoxContainer
var _message_lbl: Label
var _sub_lbl: Label
var _btn_row: HBoxContainer
var _refill_btn: Button

func _ready() -> void:
	layer = 10
	visible = false
	_build()

# ─── Public API ───────────────────────────────────────────────────────────────

func show_win(stars: int, bank: int) -> void:
	_message_lbl.text = "Level Cleared!"
	_sub_lbl.text = "Stars earned: %d" % stars
	_set_stars(stars)
	_set_buttons_win()
	visible = true

func show_out_of_ammo(bank: int, refill_amt: int) -> void:
	_message_lbl.text = "Out of Bubbles!"
	if bank > 0:
		_sub_lbl.text = "Spend 1 star for %d more bubbles?" % refill_amt
	else:
		_sub_lbl.text = "No stars left.\nRetry or go home?"
	_set_stars(mini(bank, 3))  # show bank as filled stars (up to 3)
	_set_buttons_ammo(bank, refill_amt)
	visible = true

func show_game_over() -> void:
	_message_lbl.text = "Game Over!"
	_sub_lbl.text = "The bubbles reached the slingshot."
	_set_stars(0)
	_set_buttons_game_over()
	visible = true

func hide_overlay() -> void:
	visible = false

# ─── Build ────────────────────────────────────────────────────────────────────

func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(700, 400)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.08, 0.22, 0.97)
	style.corner_radius_top_left = 32
	style.corner_radius_top_right = 32
	style.corner_radius_bottom_left = 32
	style.corner_radius_bottom_right = 32
	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = 4
	style.border_color = Color(0.6, 0.4, 1.0)
	_panel.add_theme_stylebox_override("panel", style)
	center.add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 24)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_panel.add_child(vbox)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	vbox.add_child(margin)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 20)
	inner.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(inner)

	_message_lbl = Label.new()
	_message_lbl.add_theme_font_size_override("font_size", 64)
	_message_lbl.add_theme_color_override("font_color", Color.WHITE)
	_message_lbl.add_theme_constant_override("outline_size", 6)
	_message_lbl.add_theme_color_override("font_outline_color", Color(0.3, 0.1, 0.5))
	_message_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(_message_lbl)

	_star_row = HBoxContainer.new()
	_star_row.add_theme_constant_override("separation", 12)
	_star_row.alignment = BoxContainer.ALIGNMENT_CENTER
	for _i in 3:
		var img := TextureRect.new()
		img.custom_minimum_size = Vector2(72, 72)
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_star_row.add_child(img)
	inner.add_child(_star_row)

	_sub_lbl = Label.new()
	_sub_lbl.add_theme_font_size_override("font_size", 36)
	_sub_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 1.0))
	_sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inner.add_child(_sub_lbl)

	_btn_row = HBoxContainer.new()
	_btn_row.add_theme_constant_override("separation", 28)
	_btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	inner.add_child(_btn_row)

func _set_stars(count: int) -> void:
	for i in 3:
		var img: TextureRect = _star_row.get_child(i)
		if count < 0:
			img.visible = false
		else:
			img.visible = true
			img.texture = STAR_FILLED if i < count else STAR_EMPTY

func _clear_buttons() -> void:
	for child in _btn_row.get_children():
		child.queue_free()
	_refill_btn = null

func _make_icon_btn(tex: Texture2D, sz: float) -> Button:
	var btn := Button.new()
	btn.flat = true
	btn.expand_icon = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(sz, sz)
	btn.icon = tex
	return btn

func _set_buttons_win() -> void:
	_clear_buttons()
	var home := _make_icon_btn(BTN_HOME, 90)
	home.pressed.connect(func() -> void: hide_overlay(); go_home.emit())
	_btn_row.add_child(home)

	var retry := _make_icon_btn(BTN_REPLAY, 90)
	retry.pressed.connect(func() -> void: hide_overlay(); retry_same.emit())
	_btn_row.add_child(retry)

	var nxt := _make_icon_btn(BTN_NEXT, 90)
	nxt.pressed.connect(func() -> void: hide_overlay(); new_game.emit())
	_btn_row.add_child(nxt)

func _set_buttons_ammo(bank: int, _refill_amt: int) -> void:
	_clear_buttons()
	var home := _make_icon_btn(BTN_HOME, 90)
	home.pressed.connect(func() -> void: hide_overlay(); go_home.emit())
	_btn_row.add_child(home)

	var retry := _make_icon_btn(BTN_REPLAY, 90)
	retry.pressed.connect(func() -> void: hide_overlay(); retry_same.emit())
	_btn_row.add_child(retry)

	if bank > 0:
		# Amber button showing star icon + "−1" cost.
		var amber_n := StyleBoxFlat.new()
		amber_n.bg_color = Color(0.90, 0.65, 0.04)
		amber_n.corner_radius_top_left = 20
		amber_n.corner_radius_top_right = 20
		amber_n.corner_radius_bottom_left = 20
		amber_n.corner_radius_bottom_right = 20
		amber_n.border_width_left = 3
		amber_n.border_width_top = 3
		amber_n.border_width_right = 3
		amber_n.border_width_bottom = 3
		amber_n.border_color = Color(0.65, 0.44, 0.01)
		var amber_p := StyleBoxFlat.new()
		amber_p.bg_color = Color(0.65, 0.44, 0.01)
		amber_p.corner_radius_top_left = 20
		amber_p.corner_radius_top_right = 20
		amber_p.corner_radius_bottom_left = 20
		amber_p.corner_radius_bottom_right = 20

		_refill_btn = Button.new()
		_refill_btn.custom_minimum_size = Vector2(160, 90)
		_refill_btn.focus_mode = Control.FOCUS_NONE
		_refill_btn.add_theme_stylebox_override("normal", amber_n)
		_refill_btn.add_theme_stylebox_override("hover", amber_n)
		_refill_btn.add_theme_stylebox_override("pressed", amber_p)

		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 6)
		row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_refill_btn.add_child(row)

		var star_img := TextureRect.new()
		star_img.texture = STAR_FILLED
		star_img.custom_minimum_size = Vector2(46, 46)
		star_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		star_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		star_img.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		star_img.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(star_img)

		var cost_lbl := Label.new()
		cost_lbl.text = "−1"
		cost_lbl.add_theme_font_size_override("font_size", 44)
		cost_lbl.add_theme_color_override("font_color", Color(0.10, 0.05, 0.00))
		cost_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		cost_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(cost_lbl)

		_refill_btn.pressed.connect(func() -> void: hide_overlay(); refill_requested.emit())
		_btn_row.add_child(_refill_btn)

func _set_buttons_game_over() -> void:
	_clear_buttons()
	var home := _make_icon_btn(BTN_HOME, 90)
	home.pressed.connect(func() -> void: hide_overlay(); go_home.emit())
	_btn_row.add_child(home)

	var retry := _make_icon_btn(BTN_REPLAY, 90)
	retry.pressed.connect(func() -> void: hide_overlay(); retry_same.emit())
	_btn_row.add_child(retry)
