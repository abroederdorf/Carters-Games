extends CanvasLayer

signal time_up
signal timer_selected(duration: float)
signal difficulty_selected(difficulty: int)
signal mode_selected(mode: int)
signal spelling_slot_tapped(index: int)
signal spelling_audio_requested
signal back_to_game_select

@onready var score_label: Label = find_child("ScoreLabel")
@onready var fish_label: Label = find_child("FishLabel")
@onready var timer_label: Label = find_child("TimerLabel")
@onready var end_screen: Control = find_child("EndScreen")
@onready var final_score_label: Label = find_child("FinalScoreLabel")
@onready var high_scores_label: Label = find_child("HighScoresLabel")
@onready var leaderboard_container: VBoxContainer = find_child("LeaderboardContainer")
@onready var menu_screen: Control = find_child("MenuScreen")
@onready var menu_back_button: Button = find_child("MenuBackButton")
@onready var menu_btn_free_play: Button = find_child("MenuBtnFreePlay")
@onready var menu_btn_math: Button = find_child("MenuBtnMath")
@onready var menu_btn_spelling: Button = find_child("MenuBtnSpelling")
@onready var menu_btn_easy: Button = find_child("MenuBtnEasy")
@onready var menu_btn_medium: Button = find_child("MenuBtnMedium")
@onready var menu_btn_hard: Button = find_child("MenuBtnHard")
@onready var menu_btn_1min: Button = find_child("MenuBtn1Min")
@onready var menu_btn_3min: Button = find_child("MenuBtn3Min")
@onready var menu_btn_5min: Button = find_child("MenuBtn5Min")
@onready var lb_screen: Control = find_child("LeaderboardScreen")
@onready var lb_btn_free_play: Button = find_child("LBBtnFreePlay")
@onready var lb_btn_math: Button = find_child("LBBtnMath")
@onready var lb_btn_spelling: Button = find_child("LBBtnSpelling")
@onready var lb_btn_easy: Button = find_child("LBBtnEasy")
@onready var lb_btn_medium: Button = find_child("LBBtnMedium")
@onready var lb_btn_hard: Button = find_child("LBBtnHard")
@onready var lb_btn_1min: Button = find_child("LBBtn1Min")
@onready var lb_btn_3min: Button = find_child("LBBtn3Min")
@onready var lb_btn_5min: Button = find_child("LBBtn5Min")
@onready var lb_entries: VBoxContainer = find_child("EntriesContainer")
@onready var lb_combo_label: Label = find_child("ComboLabel")
@onready var settings_screen: Control = find_child("SettingsScreen")
@onready var music_toggle: CheckButton = find_child("MusicToggle")
@onready var sfx_toggle: CheckButton = find_child("SFXToggle")
@onready var reset_confirm_overlay: Control = find_child("ResetConfirmOverlay")
@onready var exit_button: Button = find_child("ExitButton")
@onready var pause_button: Button = find_child("PauseButton")
@onready var pause_overlay: Control = find_child("PauseOverlay")
@onready var mute_button: Button = find_child("MuteButton")
@onready var play_again_button: Button = find_child("PlayAgainButton")
@onready var end_home_button: Button = find_child("EndHomeButton")
@onready var settings_back_button: Button = find_child("SettingsBackButton")
@onready var reset_lb_button: Button = find_child("ResetLBButton")
@onready var lb_back_button: Button = find_child("LBBackButton")
@onready var menu_play_button: Button = find_child("MenuPlayButton")
@onready var settings_button: Button = find_child("SettingsButton")
@onready var reset_no_button: Button = find_child("BtnNo")
@onready var reset_yes_button: Button = find_child("BtnYes")
@onready var pause_play_button: Button = find_child("PausePlayButton")
@onready var math_problem_label: Label = find_child("MathProblemLabel")
var _math_problem_panel: Panel = null

var countdown: float = 0.0
var timer_running: bool = false
var _selected_mode: int = 0
var _selected_difficulty: int = 0
var _selected_timer: int = 60
var _lb_mode: int = 0
var _lb_difficulty: int = 0
var _lb_timer: int = 60

var _spell_hud: Control = null
var _spell_image: TextureRect = null
var _spell_slots_container: HBoxContainer = null
var _spell_slots: Array = []
var _spell_held_display: Label = null
var _spell_audio_btn: Button = null
var _spell_quiet_btn: Button = null
var _spell_current_word: String = ""
var _spell_missing_indices: Array = []

const _MODE_NAMES := ["Fishing", "Math", "Spelling"]
const _DIFF_NAMES := ["Easy", "Medium", "Hard"]
const _TIMER_LABELS := {60: "1 min", 180: "3 min", 300: "5 min"}

func _ready() -> void:
	var settings := Leaderboard.load_settings()
	_selected_mode = settings.get("mode", 0)
	_selected_difficulty = settings.difficulty
	_selected_timer = settings.timer_secs
	_lb_mode = _selected_mode
	_lb_difficulty = _selected_difficulty
	_lb_timer = _selected_timer

	music_toggle.button_pressed = settings.get("music", true)
	sfx_toggle.button_pressed = settings.get("sfx", true)

	# Assign icons — flat + centered, no text
	for btn in [pause_button, pause_play_button, exit_button, play_again_button,
			end_home_button, settings_button, menu_back_button, settings_back_button,
			lb_back_button, menu_play_button]:
		btn.flat = true
		btn.expand_icon = true
		btn.text = ""
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Assign specialized icons for mode selection
	for btn in [menu_btn_free_play, menu_btn_math, menu_btn_spelling,
			menu_btn_easy, menu_btn_medium, menu_btn_hard,
			menu_btn_1min, menu_btn_3min, menu_btn_5min,
			lb_btn_free_play, lb_btn_math, lb_btn_spelling,
			lb_btn_easy, lb_btn_medium, lb_btn_hard,
			lb_btn_1min, lb_btn_3min, lb_btn_5min]:
		_apply_choice_style(btn)
		btn.text = ""

	menu_btn_free_play.icon = load("res://assets/sprites/fishing/mode_fish.png")
	lb_btn_free_play.icon = menu_btn_free_play.icon
	menu_btn_math.icon = load("res://assets/sprites/fishing/mode_math.png")
	lb_btn_math.icon = menu_btn_math.icon
	menu_btn_spelling.icon = load("res://assets/sprites/fishing/mode_spelling.png")
	lb_btn_spelling.icon = menu_btn_spelling.icon

	menu_btn_easy.icon = load("res://assets/sprites/fishing/difficulty_easy.png")
	lb_btn_easy.icon = menu_btn_easy.icon
	menu_btn_medium.icon = load("res://assets/sprites/fishing/difficulty_medium.png")
	lb_btn_medium.icon = menu_btn_medium.icon
	menu_btn_hard.icon = load("res://assets/sprites/fishing/difficulty_hard.png")
	lb_btn_hard.icon = menu_btn_hard.icon

	# Assign text AFTER the clearing loop
	for btn in [menu_btn_easy, lb_btn_easy]: btn.text = "Easy"
	for btn in [menu_btn_medium, lb_btn_medium]: btn.text = "Med"
	for btn in [menu_btn_hard, lb_btn_hard]: btn.text = "Hard"

	# Apply text styling to difficulty buttons
	for btn in [menu_btn_easy, menu_btn_medium, menu_btn_hard, lb_btn_easy, lb_btn_medium, lb_btn_hard]:
		btn.add_theme_font_size_override("font_size", 34)
		btn.add_theme_color_override("font_outline_color", Color.BLACK)
		btn.add_theme_constant_override("outline_size", 12)
		btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER

	var timer_icon = load("res://assets/sprites/fishing/timer.png")
	for btn in [menu_btn_1min, menu_btn_3min, menu_btn_5min, lb_btn_1min, lb_btn_3min, lb_btn_5min]:
		btn.icon = timer_icon
		btn.add_theme_font_size_override("font_size", 44)
		btn.add_theme_color_override("font_outline_color", Color.BLACK)
		btn.add_theme_constant_override("outline_size", 14)
		# Clear existing labels if we are just using the text property
		if btn.name.contains("1Min"): btn.text = "1"
		if btn.name.contains("3Min"): btn.text = "3"
		if btn.name.contains("5Min"): btn.text = "5"

	pause_button.icon = load("res://assets/sprites/ui/button_pause.png")
	pause_play_button.icon = load("res://assets/sprites/ui/button_play.png")
	exit_button.icon = load("res://assets/sprites/ui/button_home.png")
	play_again_button.icon = load("res://assets/sprites/ui/button_replay.png")
	end_home_button.icon = load("res://assets/sprites/ui/button_home.png")
	settings_button.icon = load("res://assets/sprites/ui/button_settings.png")
	menu_back_button.icon = load("res://assets/sprites/ui/button_back.png")
	settings_back_button.icon = load("res://assets/sprites/ui/button_back.png")
	lb_back_button.icon = load("res://assets/sprites/ui/button_back.png")
	menu_play_button.icon = load("res://assets/sprites/ui/button_play.png")

	var menu_bg_img := TextureRect.new()
	menu_bg_img.texture = preload("res://assets/icons/screen_settings.png")
	menu_bg_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	menu_bg_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	menu_bg_img.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_screen.add_child(menu_bg_img)
	menu_screen.move_child(menu_bg_img, 0)
	menu_screen.find_child("MenuBg").hide()

	play_again_button.pressed.connect(_on_play_again_pressed)
	end_home_button.pressed.connect(_on_end_home_pressed)

	menu_back_button.pressed.connect(_on_menu_back_pressed)
	menu_btn_free_play.pressed.connect(_set_menu_mode.bind(0))
	menu_btn_math.pressed.connect(_set_menu_mode.bind(1))
	menu_btn_spelling.pressed.connect(_set_menu_mode.bind(2))
	menu_btn_easy.pressed.connect(_set_menu_difficulty.bind(0))
	menu_btn_medium.pressed.connect(_set_menu_difficulty.bind(1))
	menu_btn_hard.pressed.connect(_set_menu_difficulty.bind(2))
	menu_btn_1min.pressed.connect(_set_menu_timer.bind(60))
	menu_btn_3min.pressed.connect(_set_menu_timer.bind(180))
	menu_btn_5min.pressed.connect(_set_menu_timer.bind(300))
	menu_play_button.pressed.connect(_on_menu_play_pressed)
	find_child("ScoresButton").pressed.connect(_on_scores_pressed)
	settings_button.pressed.connect(_on_settings_pressed)

	lb_btn_free_play.pressed.connect(_set_lb_mode.bind(0))
	lb_btn_math.pressed.connect(_set_lb_mode.bind(1))
	lb_btn_spelling.pressed.connect(_set_lb_mode.bind(2))
	lb_btn_easy.pressed.connect(_set_lb_difficulty.bind(0))
	lb_btn_medium.pressed.connect(_set_lb_difficulty.bind(1))
	lb_btn_hard.pressed.connect(_set_lb_difficulty.bind(2))
	lb_btn_1min.pressed.connect(_set_lb_timer.bind(60))
	lb_btn_3min.pressed.connect(_set_lb_timer.bind(180))
	lb_btn_5min.pressed.connect(_set_lb_timer.bind(300))
	lb_back_button.pressed.connect(_on_lb_back_pressed)

	settings_back_button.pressed.connect(_on_settings_back_pressed)
	reset_lb_button.pressed.connect(_on_reset_lb_pressed)
	reset_no_button.pressed.connect(_on_reset_cancel_pressed)
	reset_yes_button.pressed.connect(_on_reset_confirm_pressed)

	music_toggle.toggled.connect(_on_audio_toggled)
	sfx_toggle.toggled.connect(_on_audio_toggled)

	exit_button.pressed.connect(_on_exit_pressed)
	pause_button.pressed.connect(_on_pause_pressed)
	pause_play_button.pressed.connect(_on_play_pressed)
	mute_button.pressed.connect(_on_mute_pressed)

	_build_math_hud()
	_build_spelling_hud()
	_update_mute_icon()
	_update_menu_visuals()

func _build_math_hud() -> void:
	if _math_problem_panel: return
	
	_math_problem_panel = Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 1.0, 1.0, 0.9)
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_right = 20
	style.corner_radius_bottom_left = 20
	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = 4
	style.border_color = Color(0.2, 0.6, 1.0, 1.0) # Friendly blue border
	
	_math_problem_panel.add_theme_stylebox_override("panel", style)
	_math_problem_panel.custom_minimum_size = Vector2(400, 100)
	_math_problem_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_math_problem_panel.offset_top = 100
	_math_problem_panel.visible = false
	add_child(_math_problem_panel)
	
	# Move the existing label into the panel if it exists
	if math_problem_label:
		if math_problem_label.get_parent():
			math_problem_label.get_parent().remove_child(math_problem_label)
		_math_problem_panel.add_child(math_problem_label)
		
		# Reset internal label properties for the new container
		math_problem_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		math_problem_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		math_problem_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		math_problem_label.add_theme_color_override("font_color", Color.BLACK)
		math_problem_label.add_theme_font_size_override("font_size", 64)
		math_problem_label.text = "" # Start empty
		math_problem_label.show()

func _update_mute_icon() -> void:
	mute_button.icon = load("res://assets/sprites/ui/button_mute.png") if AudioManager.master_mute else load("res://assets/sprites/ui/button_sound.png")
	mute_button.expand_icon = true

func _on_mute_pressed() -> void:
	var is_muted = AudioManager.toggle_mute()
	_update_mute_icon()
	Leaderboard.save_settings(_selected_mode, _selected_difficulty, _selected_timer, music_toggle.button_pressed, sfx_toggle.button_pressed, is_muted)

func _on_menu_back_pressed() -> void:
	AudioManager.play_sfx("pop")
	back_to_game_select.emit()

func _on_settings_pressed() -> void:
	var settings := Leaderboard.load_settings()
	music_toggle.button_pressed = settings.get("music", true)
	sfx_toggle.button_pressed = settings.get("sfx", true)
	AudioManager.play_sfx("pop")
	settings_screen.visible = true

func _on_settings_back_pressed() -> void:
	AudioManager.play_sfx("pop")
	settings_screen.visible = false
	Leaderboard.save_settings(_selected_mode, _selected_difficulty, _selected_timer, music_toggle.button_pressed, sfx_toggle.button_pressed, AudioManager.master_mute)

func _on_audio_toggled(_toggled: bool) -> void:
	AudioManager.play_sfx("pop")
	AudioManager.update_settings(music_toggle.button_pressed, sfx_toggle.button_pressed)
	Leaderboard.save_settings(_selected_mode, _selected_difficulty, _selected_timer, music_toggle.button_pressed, sfx_toggle.button_pressed, AudioManager.master_mute)

func _on_reset_lb_pressed() -> void:
	AudioManager.play_sfx("pop")
	reset_confirm_overlay.visible = true

func _on_reset_cancel_pressed() -> void:
	AudioManager.play_sfx("pop")
	reset_confirm_overlay.visible = false

func _on_reset_confirm_pressed() -> void:
	AudioManager.play_sfx("pop")
	reset_confirm_overlay.visible = false
	Leaderboard.clear_scores()
	var btn = reset_lb_button
	var old_text = btn.text
	btn.text = "Scores Reset!"
	btn.disabled = true
	await get_tree().create_timer(1.5).timeout
	btn.text = old_text
	btn.disabled = false

func _set_menu_mode(m: int) -> void:
	AudioManager.play_sfx("pop")
	_selected_mode = m
	_update_menu_visuals()

func _set_menu_difficulty(d: int) -> void:
	AudioManager.play_sfx("pop")
	_selected_difficulty = d
	_update_menu_visuals()

func _set_menu_timer(t: int) -> void:
	AudioManager.play_sfx("pop")
	_selected_timer = t
	_update_menu_visuals()

func _apply_choice_style(btn: Button) -> void:
	var style_normal := _make_slot_style(Color(1, 1, 1, 0.15), Color(0.2, 0.6, 1.0, 0.6))
	var style_hover := _make_slot_style(Color(1, 1, 1, 0.25), Color(0.2, 0.7, 1.0, 0.8))
	var style_pressed := _make_slot_style(Color(0.2, 0.6, 1.0, 0.3), Color(1.0, 0.85, 0.0, 1.0))
	
	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_pressed)
	btn.add_theme_stylebox_override("focus", style_hover)
	
	btn.flat = false
	btn.expand_icon = true
	btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	# Force a reasonable icon size if the button doesn't have a fixed size
	# This helps normalize images with different internal aspect ratios
	btn.custom_minimum_size = Vector2(120, 120)

func _update_menu_visuals() -> void:
	var style_selected := _make_slot_style(Color(1, 1, 1, 0.4), Color(1.0, 0.85, 0.0, 1.0))
	style_selected.border_width_left = 6
	style_selected.border_width_top = 6
	style_selected.border_width_right = 6
	style_selected.border_width_bottom = 6

	var mode_btns := [menu_btn_free_play, menu_btn_math, menu_btn_spelling]
	for i in mode_btns.size():
		var btn = mode_btns[i]
		if i == _selected_mode:
			btn.add_theme_stylebox_override("normal", style_selected)
			btn.modulate = Color(1, 1, 1, 1)
		else:
			_apply_choice_style(btn)
			btn.modulate = Color(1, 1, 1, 0.8)

	var diff_btns := [menu_btn_easy, menu_btn_medium, menu_btn_hard]
	for i in diff_btns.size():
		var btn = diff_btns[i]
		if i == _selected_difficulty:
			btn.add_theme_stylebox_override("normal", style_selected)
			btn.modulate = Color(1, 1, 1, 1)
		else:
			_apply_choice_style(btn)
			btn.modulate = Color(1, 1, 1, 0.8)

	var timer_btns := [menu_btn_1min, menu_btn_3min, menu_btn_5min]
	var timer_vals := [60, 180, 300]
	for i in timer_btns.size():
		var btn = timer_btns[i]
		if timer_vals[i] == _selected_timer:
			btn.add_theme_stylebox_override("normal", style_selected)
			btn.modulate = Color(1, 1, 1, 1)
		else:
			_apply_choice_style(btn)
			btn.modulate = Color(1, 1, 1, 0.8)

func _on_menu_play_pressed() -> void:
	AudioManager.play_sfx("pop")
	menu_screen.visible = false
	exit_button.visible = true
	pause_button.visible = true
	Leaderboard.save_settings(_selected_mode, _selected_difficulty, _selected_timer, music_toggle.button_pressed, sfx_toggle.button_pressed, AudioManager.master_mute)
	mode_selected.emit(_selected_mode)
	difficulty_selected.emit(_selected_difficulty)
	timer_selected.emit(float(_selected_timer))

func _on_scores_pressed() -> void:
	AudioManager.play_sfx("pop")
	_lb_mode = _selected_mode
	_lb_difficulty = _selected_difficulty
	_lb_timer = _selected_timer
	_update_lb_visuals()
	_refresh_lb_entries()
	lb_screen.visible = true

func _set_lb_mode(m: int) -> void:
	_lb_mode = m
	_update_lb_visuals()
	_refresh_lb_entries()

func _set_lb_difficulty(d: int) -> void:
	_lb_difficulty = d
	_update_lb_visuals()
	_refresh_lb_entries()

func _set_lb_timer(t: int) -> void:
	_lb_timer = t
	_update_lb_visuals()
	_refresh_lb_entries()

func _update_lb_visuals() -> void:
	var style_selected := _make_slot_style(Color(1, 1, 1, 0.4), Color(1.0, 0.85, 0.0, 1.0))
	style_selected.border_width_left = 6
	style_selected.border_width_top = 6
	style_selected.border_width_right = 6
	style_selected.border_width_bottom = 6

	var mode_btns := [lb_btn_free_play, lb_btn_math, lb_btn_spelling]
	for i in mode_btns.size():
		var btn = mode_btns[i]
		if i == _lb_mode:
			btn.add_theme_stylebox_override("normal", style_selected)
			btn.modulate = Color(1, 1, 1, 1)
		else:
			_apply_choice_style(btn)
			btn.modulate = Color(1, 1, 1, 0.8)

	var diff_btns := [lb_btn_easy, lb_btn_medium, lb_btn_hard]
	for i in diff_btns.size():
		var btn = diff_btns[i]
		if i == _lb_difficulty:
			btn.add_theme_stylebox_override("normal", style_selected)
			btn.modulate = Color(1, 1, 1, 1)
		else:
			_apply_choice_style(btn)
			btn.modulate = Color(1, 1, 1, 0.8)

	var timer_btns := [lb_btn_1min, lb_btn_3min, lb_btn_5min]
	var timer_vals := [60, 180, 300]
	for i in timer_btns.size():
		var btn = timer_btns[i]
		if timer_vals[i] == _lb_timer:
			btn.add_theme_stylebox_override("normal", style_selected)
			btn.modulate = Color(1, 1, 1, 1)
		else:
			_apply_choice_style(btn)
			btn.modulate = Color(1, 1, 1, 0.8)

func _refresh_lb_entries() -> void:
	lb_combo_label.text = "%s · %s · %s" % [_MODE_NAMES[_lb_mode], _DIFF_NAMES[_lb_difficulty], _TIMER_LABELS[_lb_timer]]

	for child in lb_entries.get_children():
		child.queue_free()

	var entries := Leaderboard.get_scores(_lb_mode, _lb_difficulty, _lb_timer)
	if entries.is_empty():
		var lbl := Label.new()
		lbl.text = "No scores yet!"
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 30)
		lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
		lb_entries.add_child(lbl)
	else:
		for i in entries.size():
			var e: Dictionary = entries[i]
			var lbl := Label.new()
			if _lb_mode == 1 or _lb_mode == 2:
				lbl.text = "#%d  ·  %d %s" % [i + 1, e.score, "solved" if _lb_mode == 1 else "words"]
			else:
				lbl.text = "#%d  ·  %d pts  ·  %d fish" % [i + 1, e.score, e.fish]
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.add_theme_font_size_override("font_size", 32)
			lbl.add_theme_color_override("font_color", Color(1, 1, 1, 1))
			lb_entries.add_child(lbl)

func _on_lb_back_pressed() -> void:
	AudioManager.play_sfx("pop")
	lb_screen.visible = false

func _on_pause_pressed() -> void:
	AudioManager.play_sfx("pop")
	get_tree().paused = true
	pause_button.visible = false
	pause_overlay.visible = true

func _on_play_pressed() -> void:
	AudioManager.play_sfx("pop")
	get_tree().paused = false
	pause_overlay.visible = false
	pause_button.visible = true

func _on_exit_pressed() -> void:
	AudioManager.play_sfx("pop")
	get_tree().paused = false
	get_tree().reload_current_scene()

func update_score(score: int, fish: int) -> void:
	match _selected_mode:
		1:
			score_label.text = "Solved: %d" % score
			fish_label.visible = false
		2:
			score_label.text = "Words: %d" % score
			fish_label.visible = false
		_:
			score_label.text = "Score: %d" % score
			fish_label.visible = true
			fish_label.text = "Fish: %d" % fish

func show_math_problem(text: String) -> void:
	if _math_problem_panel:
		math_problem_label.text = text
		math_problem_label.show()
		_math_problem_panel.visible = true

func hide_math_problem() -> void:
	if _math_problem_panel:
		_math_problem_panel.visible = false

func start_timer(seconds: float) -> void:
	countdown = seconds
	timer_running = true
	_update_timer_label()

func _process(delta: float) -> void:
	if not timer_running or get_tree().paused:
		return
	countdown -= delta
	if countdown <= 0.0:
		countdown = 0.0
		timer_running = false
		_update_timer_label()
		time_up.emit()
	else:
		_update_timer_label()

func _update_timer_label() -> void:
	timer_label.text = "%d:%02d" % [floor(countdown / 60.0), int(countdown) % 60]

func show_end_screen(score: int, fish: int, difficulty: int, timer_secs: int, rank: int) -> void:
	exit_button.visible = false
	pause_button.visible = false
	pause_overlay.visible = false
	end_screen.visible = true

	if _selected_mode == 1:
		final_score_label.text = "%d problems solved!" % score
	elif _selected_mode == 2:
		final_score_label.text = "%d words spelled!" % score
	else:
		final_score_label.text = "%d fish caught!\nScore: %d pts" % [fish, score]

	high_scores_label.text = "%s · %s · %s · High Scores" % [
		_MODE_NAMES[_selected_mode],
		_DIFF_NAMES[difficulty],
		_TIMER_LABELS.get(timer_secs, "%d sec" % timer_secs)
	]

	for child in leaderboard_container.get_children():
		child.queue_free()

	var entries := Leaderboard.get_scores(_selected_mode, difficulty, timer_secs)
	if entries.is_empty():
		var lbl := Label.new()
		lbl.text = "No scores yet!"
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 26)
		lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
		leaderboard_container.add_child(lbl)
	else:
		for i in entries.size():
			var e: Dictionary = entries[i]
			var lbl := Label.new()
			if _selected_mode == 1 or _selected_mode == 2:
				lbl.text = "#%d  ·  %d %s" % [i + 1, e.score, "solved" if _lb_mode == 1 else "words"]
			else:
				lbl.text = "#%d  ·  %d pts  ·  %d fish" % [i + 1, e.score, e.fish]
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.add_theme_font_size_override("font_size", 28)
			lbl.add_theme_color_override("font_color", Color(1, 0.9, 0.1, 1) if rank == i + 1 \
				else Color(1, 1, 1, 1))
			leaderboard_container.add_child(lbl)

func _on_play_again_pressed() -> void:
	AudioManager.play_sfx("pop")
	get_tree().reload_current_scene()

func _on_end_home_pressed() -> void:
	AudioManager.play_sfx("pop")
	back_to_game_select.emit()

func _make_slot_style(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.corner_radius_top_left = 24
	s.corner_radius_top_right = 24
	s.corner_radius_bottom_right = 24
	s.corner_radius_bottom_left = 24
	s.border_width_left = 4
	s.border_width_top = 4
	s.border_width_right = 4
	s.border_width_bottom = 4
	s.border_color = border
	return s

func _build_spelling_hud() -> void:
	_spell_hud = Control.new()
	_spell_hud.name = "SpellingHUD"
	_spell_hud.visible = false
	_spell_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_spell_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_spell_hud)

	# White panel anchored to right edge so it never overlaps center buttons
	var img_panel := Panel.new()
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(1.0, 1.0, 1.0, 0.93)
	panel_style.corner_radius_top_left = 16
	panel_style.corner_radius_top_right = 16
	panel_style.corner_radius_bottom_right = 16
	panel_style.corner_radius_bottom_left = 16
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.75, 0.75, 0.75, 1.0)
	img_panel.add_theme_stylebox_override("panel", panel_style)
	img_panel.anchor_left = 1.0
	img_panel.anchor_right = 1.0
	img_panel.anchor_top = 0.0
	img_panel.anchor_bottom = 0.0
	img_panel.offset_left = -370.0
	img_panel.offset_right = -5.0
	img_panel.offset_top = 65.0
	img_panel.offset_bottom = 248.0
	_spell_hud.add_child(img_panel)

	# Image and buttons are children of the panel using local coordinates
	_spell_image = TextureRect.new()
	_spell_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_spell_image.position = Vector2(10, 10)
	_spell_image.size = Vector2(155, 165)
	img_panel.add_child(_spell_image)

	_spell_slots_container = HBoxContainer.new()
	_spell_slots_container.add_theme_constant_override("separation", 10)
	_spell_slots_container.layout_mode = 0
	_spell_hud.add_child(_spell_slots_container)

	_spell_audio_btn = Button.new()
	_spell_audio_btn.icon = load("res://assets/sprites/ui/button_sound.png")
	_spell_audio_btn.expand_icon = true
	_spell_audio_btn.flat = true
	_spell_audio_btn.focus_mode = Control.FOCUS_NONE
	_spell_audio_btn.position = Vector2(173, 15)
	_spell_audio_btn.size = Vector2(182, 80)
	img_panel.add_child(_spell_audio_btn)
	_spell_audio_btn.pressed.connect(func() -> void: spelling_audio_requested.emit())

	_spell_quiet_btn = Button.new()
	_spell_quiet_btn.icon = load("res://assets/sprites/ui/button_voice_only.png")
	_spell_quiet_btn.expand_icon = true
	_spell_quiet_btn.flat = true
	_spell_quiet_btn.focus_mode = Control.FOCUS_NONE
	_spell_quiet_btn.position = Vector2(173, 103)
	_spell_quiet_btn.size = Vector2(182, 65)
	img_panel.add_child(_spell_quiet_btn)
	_update_quiet_btn_style(false)
	_spell_quiet_btn.pressed.connect(func() -> void:
		var is_quiet := AudioManager.toggle_spelling_quiet()
		_update_quiet_btn_style(is_quiet)
	)

	_spell_held_display = Label.new()
	_spell_held_display.add_theme_font_size_override("font_size", 56)
	_spell_held_display.add_theme_color_override("font_color", Color.YELLOW)
	_spell_held_display.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_spell_held_display.add_theme_constant_override("shadow_offset_x", 3)
	_spell_held_display.add_theme_constant_override("shadow_offset_y", 3)
	_spell_held_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_spell_held_display.layout_mode = 0
	_spell_held_display.position = Vector2(340, 118)
	_spell_held_display.size = Vector2(115, 72)
	_spell_held_display.visible = false
	_spell_hud.add_child(_spell_held_display)

func show_spelling_hud(word: String, missing_indices: Array, filled: Dictionary, is_hard: bool) -> void:
	_spell_current_word = word
	_spell_missing_indices = missing_indices
	_spell_hud.visible = true

	var img_path := "res://assets/sprites/words/%s.png" % word.to_lower()
	if not ResourceLoader.exists(img_path):
		img_path = "res://assets/sprites/words/%s.svg" % word.to_lower()
	if ResourceLoader.exists(img_path):
		_spell_image.texture = load(img_path)
		_spell_image.visible = true
	else:
		_spell_image.visible = false

	for child in _spell_slots_container.get_children():
		child.queue_free()
	_spell_slots.clear()

	var style_known := _make_slot_style(Color(0.15, 0.20, 0.40, 0.9), Color(0.35, 0.40, 0.65, 1))
	var style_empty := _make_slot_style(Color(0.08, 0.18, 0.45, 0.9), Color(1.0, 0.85, 0.0, 1))
	var style_filled := _make_slot_style(Color(0.10, 0.55, 0.18, 0.9), Color(0.05, 0.35, 0.10, 1))

	for i in word.length():
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(78, 78)
		btn.add_theme_font_size_override("font_size", 42)
		btn.focus_mode = Control.FOCUS_NONE

		if i in missing_indices and not filled.has(i):
			btn.text = "_"
			btn.add_theme_color_override("font_color", Color.YELLOW)
			btn.add_theme_stylebox_override("normal", style_empty)
			btn.add_theme_stylebox_override("hover", style_empty)
			btn.add_theme_stylebox_override("pressed", style_empty)
			if is_hard:
				btn.pressed.connect(_on_spell_slot_pressed.bind(i))
			else:
				btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		else:
			var letter: String = filled.get(i, word[i].to_upper() if not filled.has(i) else "")
			if filled.has(i):
				btn.text = (filled[i] as String).to_upper()
				btn.add_theme_color_override("font_color", Color.WHITE)
				btn.add_theme_stylebox_override("normal", style_filled)
				btn.add_theme_stylebox_override("hover", style_filled)
				btn.add_theme_stylebox_override("pressed", style_filled)
			else:
				btn.text = word[i].to_upper()
				btn.add_theme_color_override("font_color", Color.WHITE)
				btn.add_theme_stylebox_override("normal", style_known)
				btn.add_theme_stylebox_override("hover", style_known)
				btn.add_theme_stylebox_override("pressed", style_known)
			btn.mouse_filter = Control.MOUSE_FILTER_IGNORE

		_spell_slots_container.add_child(btn)
		_spell_slots.append(btn)

	var slot_w := 78
	var gap := 10
	var total_w: int = word.length() * slot_w + max(0, word.length() - 1) * gap
	var center_x := 940.0 # Shifted further right from 740.0
	_spell_slots_container.position = Vector2(center_x - total_w / 2.0, 106.0)

func hide_spelling_hud() -> void:
	if _spell_hud:
		_spell_hud.visible = false
	if AudioManager.spelling_quiet:
		AudioManager.toggle_spelling_quiet()
		_update_quiet_btn_style(false)

func _update_quiet_btn_style(is_quiet: bool) -> void:
	if not _spell_quiet_btn:
		return
	var style := _make_slot_style(
		Color(0.10, 0.55, 0.18, 1.0) if is_quiet else Color(0.20, 0.20, 0.38, 0.9),
		Color(0.05, 0.35, 0.10, 1.0) if is_quiet else Color(0.38, 0.38, 0.60, 1.0)
	)
	_spell_quiet_btn.add_theme_stylebox_override("normal", style)
	_spell_quiet_btn.add_theme_stylebox_override("hover", style)
	_spell_quiet_btn.add_theme_stylebox_override("pressed", style)
	_spell_quiet_btn.add_theme_color_override("font_color", Color.WHITE)

func update_spelling_slots(word: String, missing_indices: Array, filled: Dictionary) -> void:
	var style_empty := _make_slot_style(Color(0.08, 0.18, 0.45, 0.9), Color(1.0, 0.85, 0.0, 1))
	var style_filled := _make_slot_style(Color(0.10, 0.55, 0.18, 0.9), Color(0.05, 0.35, 0.10, 1))

	for i in _spell_slots.size():
		var btn = _spell_slots[i]
		if i in missing_indices:
			if filled.has(i):
				btn.text = (filled[i] as String).to_upper()
				btn.add_theme_color_override("font_color", Color.WHITE)
				btn.add_theme_stylebox_override("normal", style_filled)
				btn.add_theme_stylebox_override("hover", style_filled)
				btn.add_theme_stylebox_override("pressed", style_filled)
				btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
			else:
				btn.text = "_"
				btn.add_theme_color_override("font_color", Color.YELLOW)
				btn.add_theme_stylebox_override("normal", style_empty)

func show_held_letter(letter: String) -> void:
	if not _spell_held_display:
		return
	if letter == "":
		_spell_held_display.visible = false
	else:
		_spell_held_display.text = letter.to_upper()
		_spell_held_display.visible = true

func flash_slot_wrong(index: int) -> void:
	if index >= _spell_slots.size():
		return
	var btn: Button = _spell_slots[index]
	var style_wrong := _make_slot_style(Color(0.6, 0.05, 0.05, 0.9), Color(1.0, 0.1, 0.1, 1.0))
	btn.text = "X"
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_stylebox_override("normal", style_wrong)
	btn.add_theme_stylebox_override("hover", style_wrong)
	btn.add_theme_stylebox_override("pressed", style_wrong)
	await get_tree().create_timer(0.5).timeout
	if not is_instance_valid(btn):
		return
	var style_empty := _make_slot_style(Color(0.08, 0.18, 0.45, 0.9), Color(1.0, 0.85, 0.0, 1))
	btn.text = "_"
	btn.add_theme_color_override("font_color", Color.YELLOW)
	btn.add_theme_stylebox_override("normal", style_empty)
	btn.add_theme_stylebox_override("hover", style_empty)
	btn.add_theme_stylebox_override("pressed", style_empty)

func _on_spell_slot_pressed(index: int) -> void:
	spelling_slot_tapped.emit(index)
