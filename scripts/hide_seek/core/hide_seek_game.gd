extends Control

const HideSeekCanvas = preload("res://scripts/hide_seek/core/hide_seek_canvas.gd")
const HideSeekUI = preload("res://scripts/hide_seek/core/hide_seek_ui.gd")

const TARGET_COUNT := 10
var _decoy_count: int

var _scene_name: String
var _scene_data: HideSeekSceneData
var _active_items: Array[HideSeekItemData] = []
var _active_item_data: Array[Dictionary] = []
var _found: Array[bool] = []
var _found_targets_count: int = 0
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

	_decoy_count = randi_range(5, 10)

	var all_items := _scene_data.items.duplicate()
	all_items.shuffle()

	var total_to_pick := TARGET_COUNT + _decoy_count
	_active_items = all_items.slice(0, min(total_to_pick, all_items.size()))
	
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
		var tex := _get_item_texture(item)
		var sprite_size := 750.0
		if tex:
			sprite_size = max(tex.get_width(), tex.get_height())
		var visual_scale := (229.0 * item.base_scale) / sprite_size
		_canvas.add_item_sprite(d["pos"], visual_scale, tex)

	_ui = HideSeekUI.new()
	add_child(_ui)
	
	# Only pass the TARGETS to the UI for the thumbnail strip
	var targets_only := _active_items.slice(0, min(TARGET_COUNT, _active_items.size()))
	_ui.build(self, targets_only, _get_item_texture)
	
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
	var available_anchors: Array[HideSeekAnchor] = []

	for a in _scene_data.anchors:
		# Filter out anchors too close to edges
		if a.position.x < margin_x or a.position.x > bg_size.x - margin_x \
				or a.position.y < margin_y or a.position.y > bg_size.y - margin_y:
			continue
		available_anchors.append(a)

	available_anchors.shuffle()

	var used_anchors: Array[HideSeekAnchor] = []

	for i in _active_items.size():
		var item := _active_items[i]
		var assigned_anchor: HideSeekAnchor = null

		# PASS 0: Preferred Anchors (Manual override)
		if not item.preferred_anchors.is_empty():
			for preferred_id in item.preferred_anchors:
				for a in available_anchors:
					if a.id == preferred_id and a not in used_anchors:
						assigned_anchor = a
						break
				if assigned_anchor: break

		# PASS 1: Strict Tag Matching
		if assigned_anchor == null and not item.tags.is_empty():
			for anchor in available_anchors:
				if anchor in used_anchors: continue

				var match_found := false
				for t in item.tags:
					if t in anchor.tags:
						match_found = true
						break

				if match_found:
					var is_sky := "sky" in anchor.tags
					var is_water := "water" in anchor.tags
					var item_likes_sky := "sky" in item.tags
					var item_likes_water := "water" in item.tags
					if is_sky and not item_likes_sky: continue
					if is_water and not item_likes_water: continue
					assigned_anchor = anchor
					break

		# PASS 2: Soft Matching (Generic ground items)
		if assigned_anchor == null:
			for anchor in available_anchors:
				if anchor in used_anchors: continue
				var is_special := "sky" in anchor.tags or "water" in anchor.tags
				if not is_special:
					assigned_anchor = anchor
					break

		# PASS 3: Environment-aware fallback (sky/water exclusion, ignores specific tags)
		if assigned_anchor == null:
			for anchor in available_anchors:
				if anchor in used_anchors: continue
				var is_sky := "sky" in anchor.tags
				var is_water := "water" in anchor.tags
				var item_likes_sky := "sky" in item.tags
				var item_likes_water := "water" in item.tags
				if is_sky and not item_likes_sky: continue
				if is_water and not item_likes_water: continue
				assigned_anchor = anchor
				break

		# PASS 4: Absolute last resort (no restrictions)
		if assigned_anchor == null:
			for anchor in available_anchors:
				if anchor not in used_anchors:
					assigned_anchor = anchor
					break

		var data := {"pos": Vector2.ZERO, "radius": 50.0, "anchor_radius": 50.0}
		if assigned_anchor != null:
			used_anchors.append(assigned_anchor)
			data["pos"] = assigned_anchor.position
			data["anchor_radius"] = assigned_anchor.radius
			data["radius"] = assigned_anchor.radius * item.base_scale * 1.5
		
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
	_canvas.fade_item(index)

	if index >= TARGET_COUNT:
		AudioManager.play_sfx("wrong")
		_elapsed += 5.0
		_canvas.show_wrong_at(_active_item_data[index]["pos"])
		return

	AudioManager.play_sfx("pop")
	_canvas.show_flash_at(_active_item_data[index]["pos"])
	_found_targets_count += 1
	_ui.mark_found(index)
	if _found_targets_count >= min(TARGET_COUNT, _active_items.size()):
		_on_win()


func _calculate_stars() -> int:
	var n: int = min(TARGET_COUNT, _active_items.size())
	if _elapsed < n * 5.0:
		return 3
	elif _elapsed < n * 15.0:
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
	var unfound_targets: Array[int] = []
	for i in min(TARGET_COUNT, _active_items.size()):
		if not _found[i]:
			unfound_targets.append(i)
	if unfound_targets.is_empty():
		return
	unfound_targets.shuffle()
	HideSeekState.hint_stars -= 1
	HideSeekState.save()
	_ui.update_hint_label(HideSeekState.hint_stars)
	var idx := unfound_targets[0]
	_canvas.show_hint_at(_active_item_data[idx]["pos"], _active_item_data[idx]["radius"])


# ── Navigation ─────────────────────────────────────────────────────────────────

func _on_back_pressed() -> void:
	AudioManager.play_sfx("pop")
	get_tree().change_scene_to_file("res://scenes/hide_seek/HideSeekMain.tscn")


func _on_home_pressed() -> void:
	AudioManager.play_sfx("pop")
	get_tree().change_scene_to_file("res://scenes/hide_seek/HideSeekMain.tscn")


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
