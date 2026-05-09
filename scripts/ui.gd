extends CanvasLayer

signal time_up

@onready var score_label: Label = $ScoreLabel
@onready var fish_label: Label = $FishLabel
@onready var timer_label: Label = $TimerLabel
@onready var end_screen: Control = $EndScreen
@onready var final_score_label: Label = $EndScreen/FinalScoreLabel

var countdown: float = 0.0
var timer_running: bool = false

func _ready() -> void:
	$EndScreen/PlayAgainButton.pressed.connect(_on_play_again_pressed)

func update_score(score: int, fish: int) -> void:
	score_label.text = "Score: %d" % score
	fish_label.text = "Fish: %d" % fish

func start_timer(seconds: float) -> void:
	countdown = seconds
	timer_running = true
	_update_timer_label()

func _process(delta: float) -> void:
	if not timer_running:
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
	timer_label.text = "%d:%02d" % [int(countdown) / 60, int(countdown) % 60]

func show_end_screen(score: int, fish: int) -> void:
	end_screen.visible = true
	final_score_label.text = "%d fish caught!\nScore: %d pts" % [fish, score]

func _on_play_again_pressed() -> void:
	get_tree().reload_current_scene()
