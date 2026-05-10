extends Node

# Map logical names to filenames
var sound_files = {
	"splash": "res://assets/audio/splash.mp3",
	"catch": "res://assets/audio/catch.mp3",
	"pop": "res://assets/audio/pop.mp3",
	"bite": "res://assets/audio/bite.mp3"
}

var streams = {}
var sfx_pool = []
var pool_size = 6

@onready var music_player = AudioStreamPlayer.new()

var music_enabled: bool = true
var sfx_enabled: bool = true
var master_mute: bool = false

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
	
	# Start the music
	_start_music()

func _start_music() -> void:
	var path = "res://assets/audio/ocean_bgm.wav"
	if not FileAccess.file_exists(path):
		path = "res://assets/audio/ocean_bgm.mp3"
	
	if FileAccess.file_exists(path):
		var stream = load(path)
		if stream:
			music_player.stream = stream
			if music_enabled and not master_mute:
				music_player.play()

func _on_music_finished() -> void:
	if music_enabled and not master_mute:
		music_player.play()

func play_sfx(sound_name: String) -> void:
	if not sfx_enabled or master_mute: return
	
	var key = sound_name.to_lower()
	if key == "whoosh" or key == "woosh" or key == "snap": key = "bite"
	
	# Load on first use (standard Godot way)
	if not streams.has(key):
		var path = sound_files.get(key, "")
		if path != "" and FileAccess.file_exists(path):
			streams[key] = load(path)
		else:
			return

	# Find first available player
	for player in sfx_pool:
		if not player.playing:
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
	elif music_enabled:
		music_player.play()
		
	return master_mute
