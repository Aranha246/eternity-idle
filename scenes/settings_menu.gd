extends Control

@onready var sfx_slider: HSlider = %SFXSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var ui_scale_slider: HSlider = %UIScaleSlider
@onready var window_mode_option: OptionButton = %WindowModeOption
@onready var resolution_option: OptionButton = %ResolutionOption
@onready var close_button: Button = %CloseButton

signal closed

const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080)
]


func _ready() -> void:
	sfx_slider.value = GameManager.sfx_volume * 100
	music_slider.value = GameManager.music_volume * 100
	ui_scale_slider.value = GameManager.ui_scale * 100
	
	_setup_window_mode_option()
	_setup_resolution_option()
	
	sfx_slider.value_changed.connect(_on_sfx_changed)
	music_slider.value_changed.connect(_on_music_changed)
	ui_scale_slider.value_changed.connect(_on_ui_scale_changed)
	window_mode_option.item_selected.connect(_on_window_mode_selected)
	resolution_option.item_selected.connect(_on_resolution_selected)
	close_button.pressed.connect(_on_close_pressed)


func _setup_window_mode_option() -> void:
	window_mode_option.clear()
	window_mode_option.add_item("Windowed")
	window_mode_option.add_item("Fullscreen")
	window_mode_option.add_item("Borderless Maximize")
	
	var mode: DisplayServer.WindowMode = DisplayServer.window_get_mode()
	match mode:
		DisplayServer.WINDOW_MODE_FULLSCREEN:
			window_mode_option.selected = 1
		DisplayServer.WINDOW_MODE_MAXIMIZED:
			window_mode_option.selected = 2
		_:
			window_mode_option.selected = 0


func _setup_resolution_option() -> void:
	resolution_option.clear()
	var current_size: Vector2i = DisplayServer.window_get_size()
	var current_idx: int = 0
	
	for i in range(RESOLUTIONS.size()):
		var res: Vector2i = RESOLUTIONS[i]
		resolution_option.add_item("%dx%d" % [res.x, res.y])
		if res == current_size:
			current_idx = i
			
	resolution_option.selected = current_idx


func _on_sfx_changed(value: float) -> void:
	GameManager.sfx_volume = value / 100.0


func _on_music_changed(value: float) -> void:
	GameManager.music_volume = value / 100.0


func _on_ui_scale_changed(value: float) -> void:
	GameManager.ui_scale = value / 100.0


func _on_window_mode_selected(index: int) -> void:
	match index:
		0:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			resolution_option.disabled = false
		1:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			resolution_option.disabled = true
		2:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
			resolution_option.disabled = true


func _on_resolution_selected(index: int) -> void:
	if index >= 0 and index < RESOLUTIONS.size():
		var res: Vector2i = RESOLUTIONS[index]
		DisplayServer.window_set_size(res)
		var screen_center: Vector2i = DisplayServer.screen_get_position() + DisplayServer.screen_get_size() / 2
		DisplayServer.window_set_position(screen_center - res / 2)


func _on_close_pressed() -> void:
	closed.emit()
	hide()
