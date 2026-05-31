extends CanvasLayer

var _overlay: Control
var _visible_portrait: bool = false


func _ready() -> void:
	layer = 128
	_build_overlay()
	get_tree().root.size_changed.connect(_on_size_changed)
	_on_size_changed()


func _build_overlay() -> void:
	_overlay = Control.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.visible = false
	add_child(_overlay)

	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.05, 0.1, 0.95)
	_overlay.add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	vbox.grow_vertical = Control.GROW_DIRECTION_BOTH
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 24)
	_overlay.add_child(vbox)

	var icon_lbl := Label.new()
	icon_lbl.text = "🔄"
	icon_lbl.add_theme_font_size_override("font_size", 96)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(icon_lbl)

	var msg := Label.new()
	msg.text = "Rotate your device"
	msg.add_theme_font_size_override("font_size", 40)
	msg.add_theme_color_override("font_color", Color.WHITE)
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(msg)


func _on_size_changed() -> void:
	var vp := get_tree().root.size
	var is_portrait := vp.y > vp.x
	if is_portrait != _visible_portrait:
		_visible_portrait = is_portrait
		_overlay.visible = is_portrait
