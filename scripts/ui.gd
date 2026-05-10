extends CanvasLayer

signal time_up
signal timer_selected(duration: float)
signal difficulty_selected(difficulty: int)

@onready var score_label: Label = $ScoreLabel
@onready var fish_label: Label = $FishLabel
@onready var timer_label: Label = $TimerLabel
@onready var end_screen: Control = $EndScreen
@onready var final_score_label: Label = $EndScreen/ScrollContainer/CenterContainer/VBoxContainer/FinalScoreLabel
@onready var high_scores_label: Label = $EndScreen/ScrollContainer/CenterContainer/VBoxContainer/HighScoresLabel
@onready var leaderboard_container: VBoxContainer = $EndScreen/ScrollContainer/CenterContainer/VBoxContainer/LeaderboardContainer
@onready var menu_screen: Control = $MenuScreen
@onready var menu_btn_easy: Button = $MenuScreen/ScrollContainer/CenterContainer/VBoxContainer/DifficultySection/DifficultyButtons/BtnEasy
@onready var menu_btn_medium: Button = $MenuScreen/ScrollContainer/CenterContainer/VBoxContainer/DifficultySection/DifficultyButtons/BtnMedium
@onready var menu_btn_hard: Button = $MenuScreen/ScrollContainer/CenterContainer/VBoxContainer/DifficultySection/DifficultyButtons/BtnHard
@onready var menu_btn_1min: Button = $MenuScreen/ScrollContainer/CenterContainer/VBoxContainer/TimerSection/TimerButtons/Btn1Min
@onready var menu_btn_3min: Button = $MenuScreen/ScrollContainer/CenterContainer/VBoxContainer/TimerSection/TimerButtons/Btn3Min
@onready var menu_btn_5min: Button = $MenuScreen/ScrollContainer/CenterContainer/VBoxContainer/TimerSection/TimerButtons/Btn5Min
@onready var lb_screen: Control = $LeaderboardScreen
@onready var lb_btn_easy: Button = $LeaderboardScreen/ScrollContainer/CenterContainer/VBoxContainer/DifficultySection/DifficultyButtons/BtnEasy
@onready var lb_btn_medium: Button = $LeaderboardScreen/ScrollContainer/CenterContainer/VBoxContainer/DifficultySection/DifficultyButtons/BtnMedium
@onready var lb_btn_hard: Button = $LeaderboardScreen/ScrollContainer/CenterContainer/VBoxContainer/DifficultySection/DifficultyButtons/BtnHard
@onready var lb_btn_1min: Button = $LeaderboardScreen/ScrollContainer/CenterContainer/VBoxContainer/TimerSection/TimerButtons/Btn1Min
@onready var lb_btn_3min: Button = $LeaderboardScreen/ScrollContainer/CenterContainer/VBoxContainer/TimerSection/TimerButtons/Btn3Min
@onready var lb_btn_5min: Button = $LeaderboardScreen/ScrollContainer/CenterContainer/VBoxContainer/TimerSection/TimerButtons/Btn5Min
@onready var lb_entries: VBoxContainer = $LeaderboardScreen/ScrollContainer/CenterContainer/VBoxContainer/EntriesContainer
@onready var lb_combo_label: Label = $LeaderboardScreen/ScrollContainer/CenterContainer/VBoxContainer/ComboLabel
@onready var settings_screen: Control = $SettingsScreen
@onready var music_toggle: CheckButton = $SettingsScreen/VBoxContainer/AudioSection/MusicToggle
@onready var sfx_toggle: CheckButton = $SettingsScreen/VBoxContainer/AudioSection/SFXToggle
@onready var reset_confirm_overlay: Control = $SettingsScreen/ResetConfirmOverlay
@onready var exit_button: Button = $ExitButton
@onready var pause_button: Button = $PauseButton
@onready var pause_overlay: Control = $PauseOverlay

var countdown: float = 0.0
var timer_running: bool = false
var _selected_difficulty: int = 0
var _selected_timer: int = 60
var _lb_difficulty: int = 0
var _lb_timer: int = 60

const _DIFF_NAMES := ["Easy", "Medium", "Hard"]
const _TIMER_LABELS := {60: "1 min", 180: "3 min", 300: "5 min"}

func _ready() -> void:
	var settings := Leaderboard.load_settings()
	_selected_difficulty = settings.difficulty
	_selected_timer = settings.timer_secs
	_lb_difficulty = _selected_difficulty
	_lb_timer = _selected_timer
	
	music_toggle.button_pressed = settings.get("music", true)
	sfx_toggle.button_pressed = settings.get("sfx", true)

	$EndScreen/ScrollContainer/CenterContainer/VBoxContainer/PlayAgainButton.pressed.connect(_on_play_again_pressed)

	menu_btn_easy.pressed.connect(_set_menu_difficulty.bind(0))
	menu_btn_medium.pressed.connect(_set_menu_difficulty.bind(1))
	menu_btn_hard.pressed.connect(_set_menu_difficulty.bind(2))
	menu_btn_1min.pressed.connect(_set_menu_timer.bind(60))
	menu_btn_3min.pressed.connect(_set_menu_timer.bind(180))
	menu_btn_5min.pressed.connect(_set_menu_timer.bind(300))
	$MenuScreen/ScrollContainer/CenterContainer/VBoxContainer/ActionsSection/PlayButton.pressed.connect(_on_menu_play_pressed)
	$MenuScreen/ScrollContainer/CenterContainer/VBoxContainer/ActionsSection/ScoresButton.pressed.connect(_on_scores_pressed)
	$MenuScreen/ScrollContainer/CenterContainer/VBoxContainer/ActionsSection/SettingsButton.pressed.connect(_on_settings_pressed)

	lb_btn_easy.pressed.connect(_set_lb_difficulty.bind(0))
	lb_btn_medium.pressed.connect(_set_lb_difficulty.bind(1))
	lb_btn_hard.pressed.connect(_set_lb_difficulty.bind(2))
	lb_btn_1min.pressed.connect(_set_lb_timer.bind(60))
	lb_btn_3min.pressed.connect(_set_lb_timer.bind(180))
	lb_btn_5min.pressed.connect(_set_lb_timer.bind(300))
	$LeaderboardScreen/ScrollContainer/CenterContainer/VBoxContainer/Header/BackButton.pressed.connect(_on_lb_back_pressed)
	
	$SettingsScreen/VBoxContainer/BackButton.pressed.connect(_on_settings_back_pressed)
	$SettingsScreen/VBoxContainer/ResetSection/ResetLBButton.pressed.connect(_on_reset_lb_pressed)
	$SettingsScreen/ResetConfirmOverlay/Panel/HBox/BtnNo.pressed.connect(_on_reset_cancel_pressed)
	$SettingsScreen/ResetConfirmOverlay/Panel/HBox/BtnYes.pressed.connect(_on_reset_confirm_pressed)
	
	music_toggle.toggled.connect(_on_audio_toggled)
	sfx_toggle.toggled.connect(_on_audio_toggled)

	exit_button.pressed.connect(_on_exit_pressed)
	pause_button.pressed.connect(_on_pause_pressed)
	$PauseOverlay/PlayButton.pressed.connect(_on_play_pressed)

	_update_menu_visuals()

func _on_settings_pressed() -> void:
	var settings := Leaderboard.load_settings()
	music_toggle.button_pressed = settings.get("music", true)
	sfx_toggle.button_pressed = settings.get("sfx", true)
	
	AudioManager.play_sfx("pop")
	settings_screen.visible = true

func _on_settings_back_pressed() -> void:
	AudioManager.play_sfx("pop")
	settings_screen.visible = false
	Leaderboard.save_settings(_selected_difficulty, _selected_timer, music_toggle.button_pressed, sfx_toggle.button_pressed)

func _on_audio_toggled(_toggled: bool) -> void:
	AudioManager.play_sfx("pop")
	AudioManager.update_settings(music_toggle.button_pressed, sfx_toggle.button_pressed)
	Leaderboard.save_settings(_selected_difficulty, _selected_timer, music_toggle.button_pressed, sfx_toggle.button_pressed)

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
	# Optional: show a quick "Cleared!" message or change button text
	var btn = $SettingsScreen/VBoxContainer/ResetSection/ResetLBButton
	var old_text = btn.text
	btn.text = "Scores Reset!"
	btn.disabled = true
	await get_tree().create_timer(1.5).timeout
	btn.text = old_text
	btn.disabled = false

func _set_menu_difficulty(d: int) -> void:
	AudioManager.play_sfx("pop")
	_selected_difficulty = d
	_update_menu_visuals()

func _set_menu_timer(t: int) -> void:
	AudioManager.play_sfx("pop")
	_selected_timer = t
	_update_menu_visuals()

func _update_menu_visuals() -> void:
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
	Leaderboard.save_settings(_selected_difficulty, _selected_timer, music_toggle.button_pressed, sfx_toggle.button_pressed)
	difficulty_selected.emit(_selected_difficulty)
	timer_selected.emit(float(_selected_timer))

func _on_scores_pressed() -> void:
	AudioManager.play_sfx("pop")
	_lb_difficulty = _selected_difficulty
	_lb_timer = _selected_timer
	_update_lb_visuals()
	_refresh_lb_entries()
	lb_screen.visible = true

func _set_lb_difficulty(d: int) -> void:
	_lb_difficulty = d
	_update_lb_visuals()
	_refresh_lb_entries()

func _set_lb_timer(t: int) -> void:
	_lb_timer = t
	_update_lb_visuals()
	_refresh_lb_entries()

func _update_lb_visuals() -> void:
	var diff_btns := [lb_btn_easy, lb_btn_medium, lb_btn_hard]
	for i in diff_btns.size():
		diff_btns[i].modulate = Color(1, 1, 1, 1) if i == _lb_difficulty else Color(0.5, 0.5, 0.5, 0.8)
	var timer_btns := [lb_btn_1min, lb_btn_3min, lb_btn_5min]
	var timer_vals := [60, 180, 300]
	for i in timer_btns.size():
		timer_btns[i].modulate = Color(1, 1, 1, 1) if timer_vals[i] == _lb_timer else Color(0.5, 0.5, 0.5, 0.8)

func _refresh_lb_entries() -> void:
	lb_combo_label.text = "%s · %s" % [_DIFF_NAMES[_lb_difficulty], _TIMER_LABELS[_lb_timer]]

	for child in lb_entries.get_children():
		child.queue_free()

	var entries := Leaderboard.get_scores(_lb_difficulty, _lb_timer)
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
	score_label.text = "Score: %d" % score
	fish_label.text = "Fish: %d" % fish

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
	final_score_label.text = "%d fish caught!\nScore: %d pts" % [fish, score]

	high_scores_label.text = "%s · %s · High Scores" % [
		_DIFF_NAMES[difficulty],
		_TIMER_LABELS.get(timer_secs, "%d sec" % timer_secs)
	]

	for child in leaderboard_container.get_children():
		child.queue_free()

	var entries := Leaderboard.get_scores(difficulty, timer_secs)
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
			lbl.text = "#%d  ·  %d pts  ·  %d fish" % [i + 1, e.score, e.fish]
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.add_theme_font_size_override("font_size", 28)
			lbl.add_theme_color_override("font_color", Color(1, 0.9, 0.1, 1) if rank == i + 1 \
				else Color(1, 1, 1, 1))
			leaderboard_container.add_child(lbl)

func _on_play_again_pressed() -> void:
	AudioManager.play_sfx("pop")
	get_tree().reload_current_scene()
