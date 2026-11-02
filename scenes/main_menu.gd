extends Control

const GAME_SCENE := "res://scenes/main_idle.tscn"


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_quit_pressed() -> void:
	get_tree().quit()
