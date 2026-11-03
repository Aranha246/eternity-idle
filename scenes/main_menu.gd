extends Control

const GAME_SCENE := "res://scenes/main_idle.tscn"
const SETTINGS_SCENE := preload("res://scenes/settings_menu.tscn")

var _settings_instance: Control


func _ready() -> void:
	if has_node("%SettingsButton"):
		%SettingsButton.pressed.connect(_on_settings_pressed)


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_settings_pressed() -> void:
	if _settings_instance == null:
		_settings_instance = SETTINGS_SCENE.instantiate()
		add_child(_settings_instance)
	_settings_instance.show()


func _on_quit_pressed() -> void:
	get_tree().quit()
