# ----------------------------
# instructions.gd
# ----------------------------
extends Control

@onready var back_button: TextureButton = $MarginContainer2/HBoxContainer/BackButtonContainer/VBoxContainer/BackButton


# ----------------------------
# Ready
# ----------------------------
func _ready() -> void:
	
	# Connect instructions button
	if back_button:
		back_button.pressed.connect(_on_back_button_pressed)
		
		
# ----------------------------
# Inputs
# ----------------------------
func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	
	if event.is_action_pressed("nav_left"):
		get_viewport().set_input_as_handled()
		_on_back_button_pressed()	
		
		
# ----------------------------
# Navigation
# ----------------------------
func _on_back_button_pressed() -> void:
	if GameManager.previous_scene != "":
		get_tree().change_scene_to_file(GameManager.previous_scene)
	else:
		get_tree().change_scene_to_file("res://Scenes/title_page.tscn")  # Default fallback
