extends Control

@onready var sfx_slider: HSlider = %SFXSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var ui_scale_slider: HSlider = %UIScaleSlider
@onready var window_mode_option: OptionButton = %WindowModeOption
@onready var resolution_option: OptionButton = %ResolutionOption
@onready var close_button: Button = %CloseButton

signal closed


func _ready() -> void:
	sfx_slider.value = SettingsManager.sfx_volume * 100
	music_slider.value = SettingsManager.music_volume * 100
	ui_scale_slider.value = SettingsManager.ui_scale * 100
	
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
	window_mode_option.add_item("Borderless")
	
	window_mode_option.selected = SettingsManager.window_mode_index
	_update_resolution_option_state()


func _setup_resolution_option() -> void:
	resolution_option.clear()
	
	for res in SettingsManager.RESOLUTIONS:
		resolution_option.add_item("%dx%d" % [res.x, res.y])
		
	resolution_option.selected = SettingsManager.resolution_index


func _update_resolution_option_state() -> void:
	resolution_option.disabled = (SettingsManager.window_mode_index == 1) # Disabled in fullscreen


func _on_sfx_changed(value: float) -> void:
	SettingsManager.sfx_volume = value / 100.0
	GameManager.sfx_volume = SettingsManager.sfx_volume
	SettingsManager.save_settings()


func _on_music_changed(value: float) -> void:
	SettingsManager.music_volume = value / 100.0
	GameManager.music_volume = SettingsManager.music_volume
	SettingsManager.save_settings()


func _on_ui_scale_changed(value: float) -> void:
	SettingsManager.ui_scale = value / 100.0
	GameManager.ui_scale = SettingsManager.ui_scale
	SettingsManager.save_settings()


func _on_window_mode_selected(index: int) -> void:
	SettingsManager.window_mode_index = index
	SettingsManager.apply_display_settings()
	SettingsManager.save_settings()
	_update_resolution_option_state()


func _on_resolution_selected(index: int) -> void:
	SettingsManager.resolution_index = index
	SettingsManager.apply_resolution()
	SettingsManager.save_settings()


func _on_close_pressed() -> void:
	closed.emit()
	hide()
