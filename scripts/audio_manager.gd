extends Node

# Dictionary to store actual stream resources
var streams = {}

# Map logical names to filenames
var sound_files = {
	"splash": "res://assets/audio/splash.mp3",
	"catch": "res://assets/audio/catch.mp3",
	"pop": "res://assets/audio/pop.mp3",
	"bite": "res://assets/audio/bite.mp3"
}

@onready var music_player = AudioStreamPlayer.new()
var sfx_pool = []
var pool_size = 6

var music_enabled: bool = true
var sfx_enabled: bool = true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Setup Music
	if not music_player.get_parent():
		add_child(music_player)
	music_player.bus = &"Master"
	music_player.volume_db = -2.0
	music_player.finished.connect(_on_music_finished)
	
	# Setup SFX Pool
	for i in pool_size:
		var p = AudioStreamPlayer.new()
		p.bus = &"Master"
		add_child(p)
		sfx_pool.append(p)
	
	# Load settings
	var settings = Leaderboard.load_settings()
	music_enabled = settings.get("music", true)
	sfx_enabled = settings.get("sfx", true)
	
	# Pre-load SFX
	for key in sound_files:
		var path = sound_files[key]
		if FileAccess.file_exists(path):
			streams[key] = load(path)
	
	# Initial Music Start - wait a tiny bit
	get_tree().create_timer(0.2).timeout.connect(_start_music)

func _start_music() -> void:
	var paths = ["res://assets/audio/ocean_bgm.wav", "res://assets/audio/ocean_bgm.mp3"]
	var stream: AudioStream = null
	
	for path in paths:
		if ResourceLoader.exists(path):
			stream = load(path)
			if stream: break
			
	if stream:
		music_player.stream = stream
		if music_enabled:
			music_player.play()
			print("[Audio] Music started successfully")
	else:
		print("[Audio] ERROR: Music file not found or not imported. Try clicking it in the Godot Editor.")

func _on_music_finished() -> void:
	if music_enabled and music_player.stream:
		music_player.play()

func play_sfx(sound_name: String) -> void:
	if not sfx_enabled: return
	
	var key = sound_name.to_lower()
	# Aliases for predator sounds
	if key == "whoosh" or key == "woosh" or key == "snap": key = "bite"
	
	if not streams.has(key):
		if sound_files.has(key) and FileAccess.file_exists(sound_files[key]):
			streams[key] = load(sound_files[key])
		else:
			return

	for player in sfx_pool:
		if not player.playing:
			player.stream = streams[key]
			player.play()
			return

func update_settings(music: bool, sfx: bool) -> void:
	music_enabled = music
	sfx_enabled = sfx
	
	if music_enabled:
		if not music_player.playing:
			music_player.play()
	else:
		music_player.stop()
