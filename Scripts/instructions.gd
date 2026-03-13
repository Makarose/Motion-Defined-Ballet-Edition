# ----------------------------
# instructions.gd
# ----------------------------
extends Control
@onready var back_button: TextureButton = $MarginContainer2/HBoxContainer/BackButtonContainer/VBoxContainer/BackButton
@onready var dont_show_checkbox: CheckBox = $CheckBox

# ----------------------------
# Ready
# ----------------------------
func _ready() -> void:
	
	# Connect back button
	if back_button:
		back_button.pressed.connect(_on_back_button_pressed)
	
	# Set checkbox state and connect
	dont_show_checkbox.button_pressed = !GameManager.show_instructions_on_startup
	dont_show_checkbox.toggled.connect(func(checked):
		GameManager.show_instructions_on_startup = !checked
		GameManager.save_settings()
	)
		
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
	if GameManager.instructions_auto_opened:
		GameManager.instructions_auto_opened = false
		get_tree().change_scene_to_file("res://Scenes/main_scene.tscn")
	elif GameManager.previous_scene != "":
		get_tree().change_scene_to_file(GameManager.previous_scene)
	else:
		get_tree().change_scene_to_file("res://Scenes/title_page.tscn")
