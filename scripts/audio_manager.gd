extends Node

# Map logical names to filenames
var sound_files = {
	"splash": "res://assets/audio/splash.mp3",
	"catch": "res://assets/audio/catch.mp3",
	"pop": "res://assets/audio/pop.mp3",
	"bite": "res://assets/audio/bite.mp3",
	"wrong": "res://assets/audio/sound_buzzer.mp3"
}

var streams = {}
var sfx_pool = []
var pool_size = 6

@onready var music_player = AudioStreamPlayer.new()

var music_enabled: bool = true
var sfx_enabled: bool = true
var master_mute: bool = false
var spelling_quiet: bool = false
var _web_audio_unlocked: bool = false
var _music_requested: bool = false

func _ready() -> void:
	# Essential: Keep playing even when game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Setup Music Player
	add_child(music_player)
	music_player.bus = "Master"
	music_player.finished.connect(_on_music_finished)
	
	# Setup SFX Pool
	for i in pool_size:
		var p = AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		sfx_pool.append(p)
	
	# Load User Settings
	var settings = Leaderboard.load_settings()
	music_enabled = settings.get("music", true)
	sfx_enabled = settings.get("sfx", true)
	master_mute = settings.get("master_mute", false)
	
	_load_music_stream()

func _input(_event: InputEvent) -> void:
	if OS.has_feature("web") and not _web_audio_unlocked:
		_web_audio_unlocked = true
		if _music_requested and music_player.stream != null and music_enabled and not master_mute and not music_player.playing:
			music_player.play()

func _load_music_stream() -> void:
	var stream = load("res://assets/audio/ocean_bgm.wav") as AudioStream
	if not stream:
		stream = load("res://assets/audio/ocean_bgm.mp3") as AudioStream
	if stream:
		music_player.stream = stream

func start_music() -> void:
	_music_requested = true
	if music_player.stream == null:
		_load_music_stream()
	if music_enabled and not master_mute:
		if OS.has_feature("web"):
			if _web_audio_unlocked:
				music_player.play()
		else:
			music_player.play()

func stop_music() -> void:
	_music_requested = false
	music_player.stop()

func _on_music_finished() -> void:
	if music_enabled and not master_mute and not spelling_quiet:
		music_player.play()

func toggle_spelling_quiet() -> bool:
	spelling_quiet = !spelling_quiet
	if spelling_quiet:
		music_player.stop()
	elif music_enabled and not master_mute:
		music_player.play()
	return spelling_quiet

func play_sfx(sound_name: String) -> void:
	print("Audio: play_sfx=", sound_name, " sfx_enabled=", sfx_enabled, " mute=", master_mute)
	if not sfx_enabled or master_mute or spelling_quiet: return
	
	var key = sound_name.to_lower()
	if key == "whoosh" or key == "woosh" or key == "snap": key = "bite"
	
	# Load on first use (standard Godot way)
	if not streams.has(key):
		var path = sound_files.get(key, "")
		if path == "":
			return
		var s = load(path) as AudioStream
		if not s:
			return
		streams[key] = s

	# Find first available player
	for player in sfx_pool:
		if not player.playing:
			player.volume_db = 0.0
			player.stream = streams[key]
			player.play()
			return

func update_settings(music: bool, sfx: bool) -> void:
	music_enabled = music
	sfx_enabled = sfx
	
	if music_enabled and not master_mute:
		if not music_player.playing:
			music_player.play()
	else:
		music_player.stop()

func toggle_mute() -> bool:
	master_mute = !master_mute

	if master_mute:
		music_player.stop()
	elif music_enabled and _music_requested:
		music_player.play()

	return master_mute

func play_word(word: String) -> void:
	if master_mute: return
	var key := "word_" + word.to_lower()
	if not streams.has(key):
		var path := "res://assets/audio/spelling/%s.wav" % word.to_lower()
		var s = load(path) as AudioStream
		if not s:
			return
		streams[key] = s
	for player in sfx_pool:
		if not player.playing:
			player.volume_db = 10.0
			player.stream = streams[key]
			player.play()
			return
