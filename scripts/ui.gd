extends CanvasLayer

signal time_up
signal timer_selected(duration: float)
signal difficulty_selected(difficulty: int)
signal mode_selected(mode: int)

@onready var score_label: Label = find_child("ScoreLabel")
@onready var fish_label: Label = find_child("FishLabel")
@onready var timer_label: Label = find_child("TimerLabel")
@onready var end_screen: Control = find_child("EndScreen")
@onready var final_score_label: Label = find_child("FinalScoreLabel")
@onready var high_scores_label: Label = find_child("HighScoresLabel")
@onready var leaderboard_container: VBoxContainer = find_child("LeaderboardContainer")
@onready var menu_screen: Control = find_child("MenuScreen")
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
@onready var settings_back_button: Button = find_child("SettingsBackButton")
@onready var reset_lb_button: Button = find_child("ResetLBButton")
@onready var lb_back_button: Button = find_child("LBBackButton")
@onready var menu_play_button: Button = find_child("MenuPlayButton")
@onready var settings_button: Button = find_child("SettingsButton")
@onready var reset_no_button: Button = find_child("BtnNo")
@onready var reset_yes_button: Button = find_child("BtnYes")
@onready var pause_play_button: Button = find_child("PausePlayButton")
@onready var math_problem_label: Label = find_child("MathProblemLabel")

var SOUND_ON: Texture2D = load("res://assets/sprites/sound_on_icon.svg")
var SOUND_OFF: Texture2D = load("res://assets/sprites/sound_off_icon.svg")

var countdown: float = 0.0
var timer_running: bool = false
var _selected_mode: int = 0
var _selected_difficulty: int = 0
var _selected_timer: int = 60
var _lb_mode: int = 0
var _lb_difficulty: int = 0
var _lb_timer: int = 60

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

	play_again_button.pressed.connect(_on_play_again_pressed)

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

	menu_btn_spelling.visible = false

	_update_mute_icon()
	_update_menu_visuals()

func _update_mute_icon() -> void:
	mute_button.icon = SOUND_OFF if AudioManager.master_mute else SOUND_ON

func _on_mute_pressed() -> void:
	var is_muted = AudioManager.toggle_mute()
	_update_mute_icon()
	Leaderboard.save_settings(_selected_mode, _selected_difficulty, _selected_timer, music_toggle.button_pressed, sfx_toggle.button_pressed, is_muted)

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

func _update_menu_visuals() -> void:
	var mode_btns := [menu_btn_free_play, menu_btn_math, menu_btn_spelling]
	for i in mode_btns.size():
		mode_btns[i].modulate = Color(1, 1, 1, 1) if i == _selected_mode else Color(0.5, 0.5, 0.5, 0.8)

	var diff_btns := [menu_btn_easy, menu_btn_medium, menu_btn_hard]
	for i in diff_btns.size():
		diff_btns[i].modulate = Color(1, 1, 1, 1) if i == _selected_difficulty else Color(0.5, 0.5, 0.5, 0.8)

	var timer_btns := [menu_btn_1min, menu_btn_3min, menu_btn_5min]
	var timer_vals := [60, 180, 300]
	for i in timer_btns.size():
		timer_btns[i].modulate = Color(1, 1, 1, 1) if timer_vals[i] == _selected_timer else Color(0.5, 0.5, 0.5, 0.8)

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
	var mode_btns := [lb_btn_free_play, lb_btn_math, lb_btn_spelling]
	for i in mode_btns.size():
		mode_btns[i].modulate = Color(1, 1, 1, 1) if i == _lb_mode else Color(0.5, 0.5, 0.5, 0.8)

	var diff_btns := [lb_btn_easy, lb_btn_medium, lb_btn_hard]
	for i in diff_btns.size():
		diff_btns[i].modulate = Color(1, 1, 1, 1) if i == _lb_difficulty else Color(0.5, 0.5, 0.5, 0.8)

	var timer_btns := [lb_btn_1min, lb_btn_3min, lb_btn_5min]
	var timer_vals := [60, 180, 300]
	for i in timer_btns.size():
		timer_btns[i].modulate = Color(1, 1, 1, 1) if timer_vals[i] == _lb_timer else Color(0.5, 0.5, 0.5, 0.8)

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
			if _lb_mode == 1:
				lbl.text = "#%d  ·  %d solved" % [i + 1, e.score]
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
	if _selected_mode == 1:
		score_label.text = "Solved: %d" % score
		fish_label.visible = false
	else:
		score_label.text = "Score: %d" % score
		fish_label.visible = true
		fish_label.text = "Fish: %d" % fish

func show_math_problem(text: String) -> void:
	if math_problem_label:
		math_problem_label.text = text
		math_problem_label.visible = true

func hide_math_problem() -> void:
	if math_problem_label:
		math_problem_label.visible = false

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
			if _selected_mode == 1:
				lbl.text = "#%d  ·  %d solved" % [i + 1, e.score]
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
