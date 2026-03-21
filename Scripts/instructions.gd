# ----------------------------
# instructions.gd
# ----------------------------
extends Control
@onready var back_button: TextureButton = $MarginContainer2/HBoxContainer/BackButtonContainer/VBoxContainer/BackButton
@onready var back_label: Label = $MarginContainer2/HBoxContainer/BackButtonContainer/VBoxContainer/BackLabel
@onready var show_button: Button = $HBoxContainer/ShowButton
@onready var dont_show_button: Button = $HBoxContainer/DontShowButton


# ----------------------------
# Ready
# ----------------------------
func _ready() -> void:
	
	# Connect back button
	if back_button:
		back_button.pressed.connect(_on_back_button_pressed)
	
	# Set shortcut label based on platform
	if back_label:
		back_label.text = "BACK\n[" + GameManager.get_shortcut_text("nav_left") + "]"
		back_label.add_theme_font_size_override("font_size", 18)
	
	# Button Text
	show_button.text = "Show on Startup"
	dont_show_button.text = "Don't Show on Startup"
	
	show_button.pressed.connect(_on_show_pressed)
	dont_show_button.pressed.connect(_on_dont_show_pressed)
	
	_update_buttons()

# ----------------------------
# Inputs
# ----------------------------
func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return

	var nav_left = event.is_action("nav_left") if not GameManager.is_macos() else (event.shift_pressed and event.physical_keycode == KEY_LEFT)

	if nav_left:
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

func _update_buttons() -> void:
	# Highlight the active setting by disabling it
	show_button.disabled = GameManager.show_instructions_on_startup
	dont_show_button.disabled = !GameManager.show_instructions_on_startup

func _on_show_pressed() -> void:
	GameManager.show_instructions_on_startup = true
	GameManager.save_settings()
	_update_buttons()

func _on_dont_show_pressed() -> void:
	GameManager.show_instructions_on_startup = false
	GameManager.save_settings()
	_update_buttons()
