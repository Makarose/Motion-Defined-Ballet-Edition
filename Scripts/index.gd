extends Control



func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/main_scene.tscn")


func _on_home_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/title_page.tscn")
