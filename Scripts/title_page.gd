# ----------------------------
# title_page.gd
# ----------------------------
extends Control

@onready var music_button: TextureButton = $MarginContainer/HBoxContainer/MusicContainer/HBoxContainer/MusicButton
@onready var instructions_button: TextureButton = $MarginContainer/HBoxContainer/InstructionsContainer/HBoxContainer/InstructionsButton
@onready var exit_button: TextureButton = $MarginContainer/HBoxContainer/ExitContainer/HBoxContainer/ExitButton

# ----------------------------
# Ready
# ----------------------------
func _ready() -> void:
	print("[TitlePage] Ready")
	GameManager.clear_term_state()
	
	# Connect music button
	if music_button:
		print("[TitlePage] Music button found, connecting...")
		music_button.pressed.connect(func(): 
			print("[TitlePage] Music button CLICKED!")
			GameManager.toggle_music()
		)
		print("[TitlePage] Music button connected!")
	else:
		print("[TitlePage] ERROR: music_button is null!")
	
	# Connect instructions button
	if instructions_button:
		print("[TitlePage] Instructions button found, connecting...")
		instructions_button.pressed.connect(func():
			print("[TitlePage] Instructions button CLICKED!")
			_on_instructions_pressed()
		)
		print("[TitlePage] Instructions button connected!")
	else:
		print("[TitlePage] ERROR: instructions_button is null!")
		
	# Connect exit button
	if exit_button:
		print("[TitlePage] Exit button found, connecting...")
		exit_button.pressed.connect(func():
			print("[TitlePage] Exit button CLICKED!")
			_on_exit_pressed()
		)
		print("[TitlePage] Exit button connected!")
	else:
		print("[TitlePage] ERROR: exit_button is null!")


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
# Instructions Selected
# ----------------------------
func _on_instructions_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/instructions.tscn")
	
# ----------------------------
# Exit
# ----------------------------
func _on_exit_pressed() -> void:
	GameManager.quit_dialog.popup_centered()

# ----------------------------
# Keyboard shortcuts
# ----------------------------
func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	
	print("[TitlePage] Key pressed:", event.keycode)
	
	# Check for music toggle first
	if event.is_action_pressed("music_toggle"):
		print("[TitlePage] Music toggle detected!")
		get_viewport().set_input_as_handled()
		GameManager.toggle_music()
		return
		
	# Check for instructions
	if event.is_action_pressed("open_instructions"):
		print("[TitlePage] Instructions detected!")
		get_viewport().set_input_as_handled()
		_on_instructions_pressed()
		return
	
	match event.keycode:
		KEY_1, KEY_KP_1:
			_on_male_pressed()
		KEY_2, KEY_KP_2:
			_on_female_pressed()
