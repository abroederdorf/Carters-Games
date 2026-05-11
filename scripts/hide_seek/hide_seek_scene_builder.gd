extends Control

const PANEL_WIDTH := 300

var _scene_data: HideSeekSceneData = HideSeekSceneData.new()
var _selected_index: int = -1
var _updating_ui: bool = false

var _canvas: SceneBuilderCanvas
var _scene_name_input: LineEdit
var _status_label: Label
var _item_list_container: VBoxContainer
var _selected_panel: Control
var _name_input: LineEdit
var _thumb_preview: TextureRect
var _radius_slider: HSlider
var _radius_label: Label

var _bg_dialog: FileDialog
var _thumb_dialog: FileDialog

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var hbox := HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(hbox)

	# --- Side panel ---
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = PANEL_WIDTH
	hbox.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 8)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "Hide & Seek Builder"
	title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title)

	var load_bg_btn := Button.new()
	load_bg_btn.text = "Load Background Image..."
	load_bg_btn.pressed.connect(_on_load_bg_pressed)
	vbox.add_child(load_bg_btn)

	vbox.add_child(HSeparator.new())

	var items_lbl := Label.new()
	items_lbl.text = "Items  (tap canvas to place)"
	vbox.add_child(items_lbl)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size.y = 80
	vbox.add_child(scroll)

	_item_list_container = VBoxContainer.new()
	_item_list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_item_list_container)

	vbox.add_child(HSeparator.new())

	# Selected item panel
	_selected_panel = VBoxContainer.new()
	_selected_panel.visible = false
	_selected_panel.add_theme_constant_override("separation", 4)
	vbox.add_child(_selected_panel)

	var sel_title := Label.new()
	sel_title.text = "Selected Item"
	sel_title.add_theme_font_size_override("font_size", 13)
	_selected_panel.add_child(sel_title)

	var name_hbox := HBoxContainer.new()
	_selected_panel.add_child(name_hbox)
	var name_lbl := Label.new()
	name_lbl.text = "Name: "
	name_hbox.add_child(name_lbl)
	_name_input = LineEdit.new()
	_name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_input.placeholder_text = "item name..."
	_name_input.text_changed.connect(_on_item_name_changed)
	name_hbox.add_child(_name_input)

	var thumb_btn := Button.new()
	thumb_btn.text = "Pick Thumbnail..."
	thumb_btn.pressed.connect(_on_pick_thumb_pressed)
	_selected_panel.add_child(thumb_btn)

	_thumb_preview = TextureRect.new()
	_thumb_preview.custom_minimum_size = Vector2(60, 60)
	_thumb_preview.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_thumb_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_selected_panel.add_child(_thumb_preview)

	var rad_hbox := HBoxContainer.new()
	_selected_panel.add_child(rad_hbox)
	var rad_lbl := Label.new()
	rad_lbl.text = "Radius:"
	rad_hbox.add_child(rad_lbl)
	_radius_slider = HSlider.new()
	_radius_slider.min_value = 20
	_radius_slider.max_value = 300
	_radius_slider.value = 50
	_radius_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_radius_slider.value_changed.connect(_on_radius_changed)
	rad_hbox.add_child(_radius_slider)
	_radius_label = Label.new()
	_radius_label.text = "50"
	_radius_label.custom_minimum_size.x = 28
	rad_hbox.add_child(_radius_label)

	var del_btn := Button.new()
	del_btn.text = "Delete Item"
	del_btn.pressed.connect(_on_delete_pressed)
	_selected_panel.add_child(del_btn)

	vbox.add_child(HSeparator.new())

	# Export section
	var export_lbl := Label.new()
	export_lbl.text = "Export"
	vbox.add_child(export_lbl)

	var name_row := HBoxContainer.new()
	vbox.add_child(name_row)
	var snlbl := Label.new()
	snlbl.text = "ID:"
	name_row.add_child(snlbl)
	_scene_name_input = LineEdit.new()
	_scene_name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scene_name_input.placeholder_text = "e.g. mountains"
	name_row.add_child(_scene_name_input)

	var export_btn := Button.new()
	export_btn.text = "Save .tres"
	export_btn.pressed.connect(_on_export_pressed)
	vbox.add_child(export_btn)

	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_font_size_override("font_size", 11)
	_status_label.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7))
	vbox.add_child(_status_label)

	# --- Canvas ---
	_canvas = SceneBuilderCanvas.new()
	_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_canvas.item_tapped.connect(_on_canvas_item_tapped)
	_canvas.empty_tapped.connect(_on_canvas_empty_tapped)
	hbox.add_child(_canvas)

	# File dialogs
	_bg_dialog = _make_dialog("Load Background Image")
	_bg_dialog.file_selected.connect(_on_bg_file_selected)
	add_child(_bg_dialog)

	_thumb_dialog = _make_dialog("Load Thumbnail")
	_thumb_dialog.file_selected.connect(_on_thumb_file_selected)
	add_child(_thumb_dialog)

	_canvas.setup(_scene_data, _selected_index)

func _make_dialog(title: String) -> FileDialog:
	var dlg := FileDialog.new()
	dlg.title = title
	dlg.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dlg.filters = PackedStringArray(["*.png,*.jpg,*.jpeg,*.webp ; Images"])
	dlg.access = FileDialog.ACCESS_FILESYSTEM
	dlg.current_dir = ProjectSettings.globalize_path("res://assets")
	dlg.size = Vector2i(800, 500)
	return dlg

# --- Background loading ---

func _on_load_bg_pressed() -> void:
	_bg_dialog.popup_centered()

func _on_bg_file_selected(path: String) -> void:
	var img := Image.load_from_file(path)
	if img == null:
		_set_status("Failed to load image: " + path)
		return
	_scene_data.background_image = ImageTexture.create_from_image(img)
	_canvas.setup(_scene_data, _selected_index)
	_canvas.fit_background()
	_set_status("Background loaded.")

# --- Canvas interaction ---

func _on_canvas_empty_tapped(scene_pos: Vector2) -> void:
	var item := HideSeekItemData.new()
	item.item_name = "item_%d" % (_scene_data.items.size() + 1)
	item.position = scene_pos
	item.radius = 50.0
	_scene_data.items.append(item)
	_select_item(_scene_data.items.size() - 1)

func _on_canvas_item_tapped(index: int) -> void:
	_select_item(index)

# --- Selection ---

func _select_item(index: int) -> void:
	_selected_index = index
	_canvas.setup(_scene_data, _selected_index)
	_refresh_item_list()
	_refresh_selected_panel()

func _deselect() -> void:
	_selected_index = -1
	_canvas.setup(_scene_data, _selected_index)
	_refresh_item_list()
	_selected_panel.visible = false

func _refresh_item_list() -> void:
	for child in _item_list_container.get_children():
		child.queue_free()
	for i in _scene_data.items.size():
		var item: HideSeekItemData = _scene_data.items[i]
		var btn := Button.new()
		btn.text = "%d. %s" % [i + 1, item.item_name if item.item_name else "(unnamed)"]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.flat = (i != _selected_index)
		btn.pressed.connect(_select_item.bind(i))
		_item_list_container.add_child(btn)

func _refresh_selected_panel() -> void:
	if _selected_index < 0 or _selected_index >= _scene_data.items.size():
		_selected_panel.visible = false
		return
	_selected_panel.visible = true
	var item: HideSeekItemData = _scene_data.items[_selected_index]
	_updating_ui = true
	_name_input.text = item.item_name
	_radius_slider.value = item.radius
	_radius_label.text = str(int(item.radius))
	_thumb_preview.texture = item.thumbnail
	_updating_ui = false

# --- Selected item edits ---

func _on_item_name_changed(new_text: String) -> void:
	if _updating_ui or _selected_index < 0:
		return
	_scene_data.items[_selected_index].item_name = new_text
	_refresh_item_list()

func _on_radius_changed(value: float) -> void:
	if _updating_ui or _selected_index < 0:
		return
	_scene_data.items[_selected_index].radius = value
	_radius_label.text = str(int(value))
	_canvas.setup(_scene_data, _selected_index)

func _on_pick_thumb_pressed() -> void:
	_thumb_dialog.popup_centered()

func _on_thumb_file_selected(path: String) -> void:
	if _selected_index < 0:
		return
	var img := Image.load_from_file(path)
	if img == null:
		_set_status("Failed to load thumbnail: " + path)
		return
	var tex := ImageTexture.create_from_image(img)
	_scene_data.items[_selected_index].thumbnail = tex
	_thumb_preview.texture = tex
	_canvas.setup(_scene_data, _selected_index)

func _on_delete_pressed() -> void:
	if _selected_index < 0:
		return
	_scene_data.items.remove_at(_selected_index)
	_deselect()

# --- Export ---

func _on_export_pressed() -> void:
	var scene_id := _scene_name_input.text.strip_edges()
	if scene_id.is_empty():
		_set_status("Enter a scene ID before saving.")
		return
	if _scene_data.items.is_empty():
		_set_status("No items placed yet.")
		return

	_scene_data.scene_name = scene_id

	var save_path := "res://resources/hide_seek/%s.tres" % scene_id
	var err := ResourceSaver.save(_scene_data, save_path)
	if err == OK:
		_set_status("Saved: " + save_path)
	else:
		_set_status("Save failed (error %d). Check the resources/hide_seek/ folder exists." % err)

func _set_status(msg: String) -> void:
	_status_label.text = msg
