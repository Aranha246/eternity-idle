extends Node

const SAVE_PATH: String = "user://settings.cfg"

const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080)
]

var sfx_volume: float = 1.0
var music_volume: float = 1.0
var ui_scale: float = 1.0
var window_mode_index: int = 0
var resolution_index: int = 0


func _ready() -> void:
	load_settings()


func save_settings() -> void:
	var config := ConfigFile.new()
	
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("ui", "ui_scale", ui_scale)
	config.set_value("display", "window_mode", window_mode_index)
	config.set_value("display", "resolution_index", resolution_index)
	
	config.save(SAVE_PATH)


func load_settings() -> void:
	var config := ConfigFile.new()
	var err := config.load(SAVE_PATH)
	
	if err == OK:
		sfx_volume = float(config.get_value("audio", "sfx_volume", 1.0))
		music_volume = float(config.get_value("audio", "music_volume", 1.0))
		ui_scale = float(config.get_value("ui", "ui_scale", 1.0))
		window_mode_index = int(config.get_value("display", "window_mode", 0))
		resolution_index = int(config.get_value("display", "resolution_index", 0))
	
	GameManager.sfx_volume = sfx_volume
	GameManager.music_volume = music_volume
	GameManager.ui_scale = ui_scale
	
	# Apply initial display settings on the main window after scene tree is ready
	call_deferred("apply_display_settings")


func apply_display_settings() -> void:
	var window := get_window()
	if window == null:
		return

	match window_mode_index:
		0: # Windowed
			window.mode = Window.MODE_WINDOWED
			window.borderless = false
			apply_resolution()
		1: # Fullscreen
			window.borderless = false
			window.mode = Window.MODE_FULLSCREEN
		2: # Borderless Windowed
			window.mode = Window.MODE_WINDOWED
			window.borderless = true
			apply_resolution()


func apply_resolution() -> void:
	var window := get_window()
	if window == null:
		return
		
	if window_mode_index == 1:
		return # Resolution changes don't alter window size in true fullscreen
		
	if resolution_index >= 0 and resolution_index < RESOLUTIONS.size():
		var res: Vector2i = RESOLUTIONS[resolution_index]
		window.size = res
		
		# Center window on primary screen when in windowed or borderless mode
		var primary_screen: int = DisplayServer.get_primary_screen()
		var screen_pos: Vector2i = DisplayServer.screen_get_position(primary_screen)
		var screen_size: Vector2i = DisplayServer.screen_get_size(primary_screen)
		var target_pos: Vector2i = screen_pos + (screen_size - res) / 2
		window.position = target_pos
