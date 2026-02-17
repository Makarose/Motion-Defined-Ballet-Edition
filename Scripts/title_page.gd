# ----------------------------
# title_page.gd
# ----------------------------
extends Control

# ----------------------------
# Ready
# ----------------------------
func _ready() -> void:
	print("[TitlePage] Ready")
	# Clear any leftover term state from a previous session
	GameManager.clear_term_state()


# ----------------------------
# Character selection
# ----------------------------
func _on_male_pressed() -> void:
	print("[TitlePage] Male selected")
	GameManager.chosen_character = "res://Scenes/male.tscn"
	get_tree().change_scene_to_file("res://Scenes/main_scene.tscn")

func _on_female_pressed() -> void:
	print("[TitlePage] Female selected")
	GameManager.chosen_character = "res://Scenes/female.tscn"
	get_tree().change_scene_to_file("res://Scenes/main_scene.tscn")


# ----------------------------
# Keyboard shortcuts
# ----------------------------
func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_1, KEY_KP_1:
			_on_male_pressed()
		KEY_2, KEY_KP_2:
			_on_female_pressed()
