extends Control

func _on_male_pressed() -> void:
	GameManager.chosen_character = "res://Scenes/male.tscn"
	get_tree().change_scene_to_file("res://Scenes/main_scene.tscn")

func _on_female_pressed() -> void:
	GameManager.chosen_character = "res://Scenes/female.tscn"
	get_tree().change_scene_to_file("res://Scenes/main_scene.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1, KEY_KP_1:
				_on_male_pressed()
			KEY_2, KEY_KP_2:
				_on_female_pressed()
