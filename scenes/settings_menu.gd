extends Control

@onready var sfx_slider: HSlider = %SFXSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var ui_scale_slider: HSlider = %UIScaleSlider
@onready var close_button: Button = %CloseButton

signal closed


func _ready() -> void:
	sfx_slider.value = GameManager.sfx_volume * 100
	music_slider.value = GameManager.music_volume * 100
	ui_scale_slider.value = GameManager.ui_scale * 100
	
	sfx_slider.value_changed.connect(_on_sfx_changed)
	music_slider.value_changed.connect(_on_music_changed)
	ui_scale_slider.value_changed.connect(_on_ui_scale_changed)
	close_button.pressed.connect(_on_close_pressed)


func _on_sfx_changed(value: float) -> void:
	GameManager.sfx_volume = value / 100.0


func _on_music_changed(value: float) -> void:
	GameManager.music_volume = value / 100.0


func _on_ui_scale_changed(value: float) -> void:
	GameManager.ui_scale = value / 100.0


func _on_close_pressed() -> void:
	closed.emit()
	hide()
