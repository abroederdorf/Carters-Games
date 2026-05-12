extends Control

const HideSeekCanvas = preload("res://scripts/hide_seek/core/hide_seek_canvas.gd")
const HideSeekUI = preload("res://scripts/hide_seek/core/hide_seek_ui.gd")

const MAX_ITEMS := 10

var _scene_name: String
var _scene_data: HideSeekSceneData
var _active_items: Array[HideSeekItemData] = []
var _active_item_data: Array[Dictionary] = []
var _found: Array[bool] = []
var _found_count: int = 0
var _elapsed: float = 0.0
var _running: bool = false
var _won: bool = false

var _canvas: HideSeekCanvas
var _ui: HideSeekUI


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_scene_name = HideSeekState.current_scene_name
	if _scene_name.is_empty():
		get_tree().change_scene_to_file("res://scenes/hide_seek/HideSeekMain.tscn")
		return
	_scene_data = load("res://resources/hide_seek/%s.tres" % _scene_name) as HideSeekSceneData
	if _scene_data == null:
		get_tree().change_scene_to_file("res://scenes/hide_seek/HideSeekMain.tscn")
		return

	var bg_tex := _scene_data.background_image
	var bg_size := Vector2(bg_tex.get_width(), bg_tex.get_height())

	var all_items := _scene_data.items.duplicate()
	all_items.shuffle()
	_active_items = all_items.slice(0, min(MAX_ITEMS, all_items.size()))
	_assign_items_to_anchors(bg_size)
	_found.resize(_active_items.size())
	_found.fill(false)

	var scene_bg := ColorRect.new()
	scene_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scene_bg.color = Color(0.05, 0.05, 0.05)
	add_child(scene_bg)

	_canvas = HideSeekCanvas.new()
	add_child(_canvas)
	_canvas.setup(self, bg_size, HideSeekUI.TOP_BAR_H, HideSeekUI.THUMB_STRIP_H)
	_canvas.tapped.connect(_on_canvas_tapped)
	_canvas.setup_done.connect(_on_canvas_ready)

	var bg_sprite := Sprite2D.new()
	bg_sprite.texture = bg_tex
	bg_sprite.centered = false
	_canvas.get_canvas_root().add_child(bg_sprite)
	for i in _active_items.size():
		var item: HideSeekItemData = _active_items[i]
		var d: Dictionary = _active_item_data[i]
		_canvas.add_item_sprite(d["pos"], d["radius"], _get_item_texture(item))

	_ui = HideSeekUI.new()
	add_child(_ui)
	_ui.build(self, _active_items, _get_item_texture)
	_ui.update_hint_label(HideSeekState.hint_stars)
	_ui.back_pressed.connect(_on_back_pressed)
	_ui.home_pressed.connect(_on_home_pressed)
	_ui.replay_pressed.connect(_on_replay_pressed)
	_ui.next_pressed.connect(_on_next_pressed)
	_ui.hint_pressed.connect(_on_hint_pressed)


func _on_canvas_ready() -> void:
	_canvas.set_running(true)
	_running = true


func _process(delta: float) -> void:
	if _running and not _won:
		_elapsed += delta
		_ui.update_timer(_elapsed)


# ── Item Assignment ────────────────────────────────────────────────────────────

func _assign_items_to_anchors(bg_size: Vector2) -> void:
	_active_item_data.clear()

	var margin_x := bg_size.x * 0.05
	var margin_y := bg_size.y * 0.05
	var standard_anchors: Array[HideSeekAnchor] = []
	var hard_anchors: Array[HideSeekAnchor] = []

	for a in _scene_data.anchors:
		if a.position.x < margin_x or a.position.x > bg_size.x - margin_x \
				or a.position.y < margin_y or a.position.y > bg_size.y - margin_y:
			continue
		if a.difficulty >= 2:
			hard_anchors.append(a)
		else:
			standard_anchors.append(a)

	standard_anchors.shuffle()
	hard_anchors.shuffle()

	var session_anchors: Array[HideSeekAnchor] = []
	var hard_count := min(2, hard_anchors.size())
	for i in hard_count:
		session_anchors.append(hard_anchors.pop_back())
	var needed: int = min(20, standard_anchors.size() + session_anchors.size()) - session_anchors.size()
	for i in needed:
		if not standard_anchors.is_empty():
			session_anchors.append(standard_anchors.pop_back())
	session_anchors.shuffle()

	var used_anchors: Array[bool] = []
	used_anchors.resize(session_anchors.size())
	used_anchors.fill(false)

	for i in _active_items.size():
		var item := _active_items[i]
		var assigned_anchor: HideSeekAnchor = null

		# PASS 1: Strict Tag Matching
		if not item.tags.is_empty():
			for j in session_anchors.size():
				if used_anchors[j]: continue
				var anchor: HideSeekAnchor = session_anchors[j]
				for t in item.tags:
					if t in anchor.tags:
						assigned_anchor = anchor
						used_anchors[j] = true
						break
				if assigned_anchor: break

		# PASS 2: Bidirectional soft matching
		if assigned_anchor == null:
			for j in session_anchors.size():
				if used_anchors[j]: continue
				var anchor: HideSeekAnchor = session_anchors[j]
				var anchor_has_water := "water" in anchor.tags
				var anchor_has_sky := "sky" in anchor.tags
				var item_needs_water := "water" in item.tags
				var item_needs_sky := "sky" in item.tags
				var item_is_ground := "ground" in item.tags and not item_needs_sky and not item_needs_water

				if item_is_ground and (anchor_has_sky or anchor_has_water): continue
				if item_needs_water and not anchor_has_water: continue
				if item_needs_sky and not anchor_has_sky: continue

				assigned_anchor = anchor
				used_anchors[j] = true
				break

		# PASS 3: Absolute fallback
		if assigned_anchor == null:
			for j in session_anchors.size():
				if not used_anchors[j]:
					assigned_anchor = session_anchors[j]
					used_anchors[j] = true
					break

		var data := {"pos": item.position, "radius": item.radius}
		if assigned_anchor != null:
			data["pos"] = assigned_anchor.position
			data["radius"] = assigned_anchor.radius * item.scale_multiplier
		_active_item_data.append(data)


# ── Game Logic ─────────────────────────────────────────────────────────────────

func _on_canvas_tapped(canvas_pos: Vector2) -> void:
	if not _running or _won:
		return
	for i in _active_items.size():
		if _found[i]:
			continue
		var d: Dictionary = _active_item_data[i]
		if canvas_pos.distance_to(d["pos"]) <= d["radius"]:
			_on_item_found(i)
			return


func _on_item_found(index: int) -> void:
	_found[index] = true
	_found_count += 1
	AudioManager.play_sfx("pop")
	_ui.mark_found(index)
	_canvas.fade_item(index)
	_canvas.show_flash_at(_active_item_data[index]["pos"])
	if _found_count >= _active_items.size():
		_on_win()


func _calculate_stars() -> int:
	var n := _active_items.size()
	if _elapsed < n * 10.0:
		return 3
	elif _elapsed < n * 20.0:
		return 2
	return 1


func _on_win() -> void:
	_running = false
	_won = true
	var stars := _calculate_stars()
	HideSeekState.complete_scene(_scene_name, stars)
	var idx := HideSeekState.SCENE_ORDER.find(_scene_name)
	var has_next := idx >= 0 and idx + 1 < HideSeekState.SCENE_ORDER.size()
	_ui.show_win(stars, _elapsed, has_next)


# ── Hint System ────────────────────────────────────────────────────────────────

func _on_hint_pressed() -> void:
	if HideSeekState.hint_stars <= 0 or _won:
		return
	var unfound: Array[int] = []
	for i in _active_items.size():
		if not _found[i]:
			unfound.append(i)
	if unfound.is_empty():
		return
	unfound.shuffle()
	HideSeekState.hint_stars -= 1
	HideSeekState.save()
	_ui.update_hint_label(HideSeekState.hint_stars)
	var idx := unfound[0]
	_canvas.show_hint_at(_active_item_data[idx]["pos"], _active_item_data[idx]["radius"])


# ── Navigation ─────────────────────────────────────────────────────────────────

func _on_back_pressed() -> void:
	AudioManager.play_sfx("pop")
	get_tree().change_scene_to_file("res://scenes/hide_seek/HideSeekMain.tscn")


func _on_home_pressed() -> void:
	AudioManager.play_sfx("pop")
	get_tree().change_scene_to_file("res://scenes/GameSelect.tscn")


func _on_replay_pressed() -> void:
	AudioManager.play_sfx("pop")
	get_tree().change_scene_to_file("res://scenes/hide_seek/HideSeekGame.tscn")


func _on_next_pressed() -> void:
	AudioManager.play_sfx("pop")
	var idx := HideSeekState.SCENE_ORDER.find(_scene_name)
	if idx >= 0 and idx + 1 < HideSeekState.SCENE_ORDER.size():
		HideSeekState.current_scene_name = HideSeekState.SCENE_ORDER[idx + 1]
		get_tree().change_scene_to_file("res://scenes/hide_seek/HideSeekGame.tscn")


# ── Helpers ────────────────────────────────────────────────────────────────────

func _get_item_texture(item: HideSeekItemData) -> Texture2D:
	if item.thumbnail != null:
		return item.thumbnail
	var path := "res://assets/sprites/hide_seek/%s/%s.png" % [_scene_name, item.item_name]
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	var shared := "res://assets/sprites/hide_seek/shared/%s.png" % item.item_name
	if ResourceLoader.exists(shared):
		return load(shared) as Texture2D
	return null
