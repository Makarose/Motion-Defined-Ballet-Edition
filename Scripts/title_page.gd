extends Control

func _on_male_pressed() -> void:
	GameManager.chosen_character = "res://Scenes/male.tscn"
	get_tree().change_scene_to_file("res://Scenes/main_scene.tscn")

func _on_female_pressed() -> void:
	GameManager.chosen_character = "res://Scenes/female.tscn"
	get_tree().change_scene_to_file("res://Scenes/main_scene.tscn")
