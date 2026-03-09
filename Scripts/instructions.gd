# ----------------------------
# instructions.gd
# ----------------------------
extends Control

@onready var home_button: TextureButton = $Home/MarginContainer/HomeButton

# ----------------------------
# Ready
# ----------------------------
func _ready() -> void:
	
	# Connect instructions button
	if home_button:
		home_button.pressed.connect(_on_home_button_pressed)
		
		
# ----------------------------
# Inputs
# ----------------------------
func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	
	if event.is_action_pressed("nav_left"):
		get_viewport().set_input_as_handled()
		_on_home_button_pressed()	
		
		
# ----------------------------
# Navigation
# ----------------------------
func _on_home_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/title_page.tscn")
