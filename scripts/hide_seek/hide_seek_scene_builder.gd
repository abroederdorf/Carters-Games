extends Control

const PANEL_WIDTH := 300

var _scene_data: HideSeekSceneData = HideSeekSceneData.new()
var _selected_index: int = -1
var _updating_ui: bool = false

var _canvas: SceneBuilderCanvas
var _mode: int = 0 # SceneBuilderCanvas.Mode.ITEMS
var _scene_name_input: LineEdit
var _status_label: Label
var _item_list_container: VBoxContainer
var _selected_panel: Control
var _name_input: LineEdit
var _thumb_preview: TextureRect
var _radius_slider: HSlider
var _radius_label: Label
var _scale_slider: HSlider
var _scale_label: Label
var _tags_input: LineEdit
var _difficulty_option: OptionButton

var _bg_dialog: FileDialog
var _thumb_dialog: FileDialog
var _res_dialog: FileDialog

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

	# --- Mode Toggle ---
	var mode_hbox := HBoxContainer.new()
	vbox.add_child(mode_hbox)
	
	var btn_group := ButtonGroup.new()
	
	var items_mode_btn := Button.new()
	items_mode_btn.text = "Items"
	items_mode_btn.toggle_mode = true
	items_mode_btn.button_pressed = true
	items_mode_btn.button_group = btn_group
	items_mode_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	items_mode_btn.pressed.connect(_set_mode.bind(SceneBuilderCanvas.Mode.ITEMS))
	mode_hbox.add_child(items_mode_btn)
	
	var anchors_mode_btn := Button.new()
	anchors_mode_btn.text = "Anchors"
	anchors_mode_btn.toggle_mode = true
	anchors_mode_btn.button_group = btn_group
	anchors_mode_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	anchors_mode_btn.pressed.connect(_set_mode.bind(SceneBuilderCanvas.Mode.ANCHORS))
	mode_hbox.add_child(anchors_mode_btn)

	var load_bg_btn := Button.new()
	load_bg_btn.text = "Load Background Image..."
	load_bg_btn.pressed.connect(_on_load_bg_pressed)
	vbox.add_child(load_bg_btn)
	
	var load_res_btn := Button.new()
	load_res_btn.text = "Load .tres Theme..."
	load_res_btn.pressed.connect(_on_load_res_pressed)
	vbox.add_child(load_res_btn)

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

	var scale_hbox := HBoxContainer.new()
	_selected_panel.add_child(scale_hbox)
	var scale_lbl := Label.new()
	scale_lbl.text = "Scale:"
	scale_hbox.add_child(scale_lbl)
	_scale_slider = HSlider.new()
	_scale_slider.min_value = 0.2
	_scale_slider.max_value = 3.0
	_scale_slider.step = 0.05
	_scale_slider.value = 1.0
	_scale_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scale_slider.value_changed.connect(_on_scale_changed)
	scale_hbox.add_child(_scale_slider)
	_scale_label = Label.new()
	_scale_label.text = "1.0"
	_scale_label.custom_minimum_size.x = 28
	scale_hbox.add_child(_scale_label)

	# Tags row
	var tags_hbox := HBoxContainer.new()
	_selected_panel.add_child(tags_hbox)
	var tags_lbl := Label.new()
	tags_lbl.text = "Tags:"
	tags_hbox.add_child(tags_lbl)
	_tags_input = LineEdit.new()
	_tags_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tags_input.placeholder_text = "ground, sky..."
	_tags_input.text_changed.connect(_on_tags_changed)
	tags_hbox.add_child(_tags_input)

	# Difficulty row
	var diff_hbox := HBoxContainer.new()
	_selected_panel.add_child(diff_hbox)
	var diff_lbl := Label.new()
	diff_lbl.text = "Diff:"
	diff_hbox.add_child(diff_lbl)
	_difficulty_option = OptionButton.new()
	_difficulty_option.add_item("Easy", 0)
	_difficulty_option.add_item("Medium", 1)
	_difficulty_option.add_item("Hard", 2)
	_difficulty_option.item_selected.connect(_on_difficulty_selected)
	_difficulty_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	diff_hbox.add_child(_difficulty_option)

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
	
	_res_dialog = _make_dialog("Load Resource (.tres)")
	_res_dialog.filters = PackedStringArray(["*.tres ; Resources"])
	_res_dialog.file_selected.connect(_on_res_file_selected)
	add_child(_res_dialog)

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

func _set_mode(mode: int) -> void:
	_mode = mode
	_deselect()
	_canvas.set_mode(_mode)
	_set_status("Switched to %s mode." % ("Items" if _mode == 0 else "Anchors"))

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

func _on_load_res_pressed() -> void:
	_res_dialog.popup_centered()

func _on_res_file_selected(path: String) -> void:
	var res = load(path)
	if not res is HideSeekSceneData:
		_set_status("Invalid resource type. Expected HideSeekSceneData.")
		return
	_scene_data = res
	_scene_name_input.text = _scene_data.scene_name
	_deselect()
	_canvas.setup(_scene_data, _selected_index)
	_canvas.fit_background()
	_set_status("Resource loaded: " + path)

# --- Canvas interaction ---

func _on_canvas_empty_tapped(scene_pos: Vector2) -> void:
	if _mode == 0: # ITEMS
		var item := HideSeekItemData.new()
		item.item_name = "item_%d" % (_scene_data.items.size() + 1)
		item.position = scene_pos
		item.radius = 50.0
		_scene_data.items.append(item)
		_select_item(_scene_data.items.size() - 1)
	else: # ANCHORS
		var anchor := HideSeekAnchor.new()
		anchor.position = scene_pos
		anchor.radius = 60.0
		_scene_data.anchors.append(anchor)
		_select_item(_scene_data.anchors.size() - 1)

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
		
	var list: Array = _scene_data.items if _mode == 0 else _scene_data.anchors
	for i in list.size():
		var obj = list[i]
		var btn := Button.new()
		if _mode == 0:
			btn.text = "%d. %s" % [i + 1, obj.item_name if obj.item_name else "(unnamed)"]
		else:
			btn.text = "Anchor %d" % (i + 1)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.flat = (i != _selected_index)
		btn.pressed.connect(_select_item.bind(i))
		_item_list_container.add_child(btn)

func _refresh_selected_panel() -> void:
	var list: Array = _scene_data.items if _mode == 0 else _scene_data.anchors
	if _selected_index < 0 or _selected_index >= list.size():
		_selected_panel.visible = false
		return
		
	_selected_panel.visible = true
	var obj = list[_selected_index]
	_updating_ui = true
	
	if _mode == 0: # ITEMS
		_name_input.get_parent().visible = true
		_thumb_preview.get_parent().get_child(1).visible = true # Thumbnail button
		_thumb_preview.visible = true
		_scale_slider.get_parent().visible = true
		_tags_input.get_parent().visible = true
		_difficulty_option.get_parent().visible = false
		_name_input.text = obj.item_name
		_radius_slider.value = obj.radius
		_radius_label.text = str(int(obj.radius))
		_scale_slider.value = obj.scale_multiplier
		_scale_label.text = "%.2f" % obj.scale_multiplier
		_thumb_preview.texture = obj.thumbnail
		_tags_input.text = ", ".join(obj.tags)
	else: # ANCHORS
		_name_input.get_parent().visible = false
		_thumb_preview.get_parent().get_child(1).visible = false
		_thumb_preview.visible = false
		_scale_slider.get_parent().visible = false
		_tags_input.get_parent().visible = true
		_difficulty_option.get_parent().visible = true
		_radius_slider.value = obj.radius
		_radius_label.text = str(int(obj.radius))
		_tags_input.text = ", ".join(obj.tags)
		_difficulty_option.selected = obj.difficulty
		
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
	var list: Array = _scene_data.items if _mode == 0 else _scene_data.anchors
	list[_selected_index].radius = value
	_radius_label.text = str(int(value))
	_canvas.setup(_scene_data, _selected_index)

func _on_scale_changed(value: float) -> void:
	if _updating_ui or _selected_index < 0 or _mode != 0:
		return
	_scene_data.items[_selected_index].scale_multiplier = value
	_scale_label.text = "%.2f" % value
	_canvas.setup(_scene_data, _selected_index)

func _on_tags_changed(new_text: String) -> void:
	if _updating_ui or _selected_index < 0:
		return
	var list: Array = _scene_data.items if _mode == 0 else _scene_data.anchors
	var tags_list: Array[String] = []
	for t in new_text.split(","):
		var cleaned = t.strip_edges()
		if not cleaned.is_empty():
			tags_list.append(cleaned)
	list[_selected_index].tags = tags_list

func _on_difficulty_selected(index: int) -> void:
	if _updating_ui or _selected_index < 0 or _mode != 1:
		return
	_scene_data.anchors[_selected_index].difficulty = index
	_set_status("Anchor %d set to %s" % [_selected_index + 1, _difficulty_option.get_item_text(index)])

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
	var list: Array = _scene_data.items if _mode == 0 else _scene_data.anchors
	list.remove_at(_selected_index)
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
