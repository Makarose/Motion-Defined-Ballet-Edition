# ----------------------------
# index.gd
# ----------------------------
extends Control

# ----------------------------
# Nodes
# ----------------------------
@onready var search_bar: LineEdit = $VBoxContainer/LineEdit
@onready var term_list: ItemList = $VBoxContainer/ItemList

@onready var back_button: TextureButton = $BottomButtons/HBoxContainer/BackContainer/VBoxContaine/BackButton
@onready var music_button: TextureButton = $BottomButtons/HBoxContainer/MusicContainer/VBoxContaine/MusicButton
@onready var instructions_button: TextureButton = $BottomButtons/HBoxContainer/InstructionsContainer/VBoxContainer/InstructionsButton
@onready var exit_button: TextureButton = $BottomButtons/HBoxContainer/ExitContainer/VBoxContainer/ExitButton
@onready var home_button: TextureButton = $BottomButtons/HBoxContainer/HomeContainer/VBoxContainer/HomeButton

@onready var back_label: Label = $BottomButtons/HBoxContainer/BackContainer/VBoxContaine/BackLabel
@onready var music_label: Label = $BottomButtons/HBoxContainer/MusicContainer/VBoxContaine/MusicLabel
@onready var instructions_label: Label = $BottomButtons/HBoxContainer/InstructionsContainer/VBoxContainer/InstructionsLabel
@onready var exit_label: Label = $BottomButtons/HBoxContainer/ExitContainer/VBoxContainer/ExitLabel
@onready var home_label: Label = $BottomButtons/HBoxContainer/HomeContainer/VBoxContainer/HomeLabel

# ----------------------------
# Runtime state
# ----------------------------
var terms: Array = []
var current_index: int = -1

# ----------------------------
# Ready
# ----------------------------
func _ready() -> void:
	print("[Index] Ready")
	# Load and sort all terms from database
	terms = GameManager.get_terms()
	terms.sort_custom(func(a, b): return GameManager.normalize(a) < GameManager.normalize(b))
	_populate_list(terms)
	
	# Search bar signals
	search_bar.text_changed.connect(_on_search_changed)
	search_bar.gui_input.connect(_on_search_bar_gui_input)
	search_bar.grab_focus()
	
	# Item list signal
	term_list.item_activated.connect(_on_term_activated)
	
	# Connect navigation buttons
	if back_button:
		back_button.pressed.connect(_on_back_button_pressed)
	if home_button:
		home_button.pressed.connect(_on_home_button_pressed)
	
	# Music button
	if music_button:
		music_button.pressed.connect(GameManager.toggle_music)
	
	# Instructions button
	if instructions_button:
		instructions_button.pressed.connect(_on_instructions_pressed)
	
	# Exit button
	if exit_button:
		exit_button.pressed.connect(_on_exit_pressed)
	
	# GameManager nav signals
	GameManager.nav_left.connect(_on_nav_left)
	GameManager.nav_right.connect(_on_nav_right)
	
	# Set button spacing and center layout
	var hbox = %HBoxContainer
	
	if hbox:
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		
		if GameManager.is_macos():
			hbox.add_theme_constant_override("separation", 350)  # MacOS
		else:
			hbox.add_theme_constant_override("separation", 400)  # Windows

# Shortcut labels
	back_label.text = "BACK\n[" + GameManager.get_shortcut_text("nav_left") + "]"
	home_label.text = "HOME\n[" + GameManager.get_shortcut_text("nav_right") + "]"
	music_label.text = "MUSIC ON/OFF\n[" + GameManager.get_shortcut_text("music_toggle") + "]"
	instructions_label.text = "INSTRUCTIONS\n[" + GameManager.get_shortcut_text("open_instructions") + "]"
	exit_label.text = "EXIT\n[" + GameManager.get_shortcut_text("quit_app") + "]"

	# Font sizes
	back_label.add_theme_font_size_override("font_size", 18)
	home_label.add_theme_font_size_override("font_size", 18)
	music_label.add_theme_font_size_override("font_size", 18)
	instructions_label.add_theme_font_size_override("font_size", 18)
	exit_label.add_theme_font_size_override("font_size", 18)

# ----------------------------
# Populate list
# ----------------------------
func _populate_list(term_array: Array) -> void:
	term_list.clear()
	current_index = -1
	for t in term_array:
		term_list.add_item(t)


# ----------------------------
# Filter list as user types
# ----------------------------
func _on_search_changed(new_text: String) -> void:
	var filtered: Array = []
	var normalized = GameManager.normalize(new_text)
	for t in terms:
		if normalized == "" or GameManager.normalize(t).begins_with(normalized):
			filtered.append(t)
	_populate_list(filtered)
	
	# Auto-select exact match
	if term_list.get_item_count() > 0:
		for i in range(term_list.get_item_count()):
			if GameManager.normalize(term_list.get_item_text(i)) == normalized:
				current_index = i
				term_list.select(i)
				term_list.ensure_current_is_visible()
				break


# ----------------------------
# Term activated (double click or enter)
# ----------------------------
func _on_term_activated(index: int) -> void:
	var selected: String = term_list.get_item_text(index)
	print("[Index] Term activated:", selected)

	# Look up full move data
	var move: BalletMove = GameManager.ballet_move_database.get_move_by_name(selected)
	if not move:
		push_warning("[Index] Move not found in database: " + selected)
		return

	# Save to GameManager so MainScene can restore on arrival
	GameManager.selected_term = move.name
	GameManager.selected_animation = move.animation_name
	GameManager.selected_definition = move.definition

	get_tree().change_scene_to_file("res://Scenes/main_scene.tscn")


# ----------------------------
# Keyboard navigation
# ----------------------------
func _on_search_bar_gui_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return

	print("[Index SearchBar] keycode:", event.keycode, " ctrl:", event.ctrl_pressed, " shift:", event.shift_pressed)

	var nav_left = event.is_action("nav_left") if not GameManager.is_macos() else (event.shift_pressed and event.physical_keycode == KEY_LEFT)
	var nav_right = event.is_action("nav_right") if not GameManager.is_macos() else (event.shift_pressed and event.physical_keycode == KEY_RIGHT)

	if nav_left:
		accept_event()
		_on_nav_left()
		return
	elif nav_right:
		accept_event()
		_on_nav_right()
		return

	match event.keycode:
		KEY_DOWN:
			if current_index < term_list.get_item_count() - 1:
				current_index += 1
				term_list.select(current_index)
				term_list.ensure_current_is_visible()
		KEY_UP:
			if current_index > 0:
				current_index -= 1
				term_list.select(current_index)
				term_list.ensure_current_is_visible()
		KEY_ENTER, KEY_KP_ENTER:
			if current_index >= 0:
				_on_term_activated(current_index)
			else:
				var normalized = GameManager.normalize(search_bar.text)
				for i in range(term_list.get_item_count()):
					if GameManager.normalize(term_list.get_item_text(i)) == normalized:
						_on_term_activated(i)
						return

# ----------------------------
# Keyboard shortcuts
# ----------------------------
func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	
	if event.is_action_pressed("music_toggle", false):
		get_viewport().set_input_as_handled()
		GameManager.toggle_music()
	
	if event.is_action_pressed("open_instructions", false):
		get_viewport().set_input_as_handled()
		_on_instructions_pressed()
	
	if event.is_action_pressed("quit_app", false):
		get_viewport().set_input_as_handled()
		_on_exit_pressed()

# ----------------------------
# Navigation
# ----------------------------
func _on_nav_left() -> void:
	GameManager.clear_term_state()  # Clear since we're not selecting anything
	get_tree().change_scene_to_file("res://Scenes/main_scene.tscn")

func _on_nav_right() -> void:
	get_tree().change_scene_to_file("res://Scenes/title_page.tscn")

func _on_back_button_pressed() -> void:
	_on_nav_left()

func _on_home_button_pressed() -> void:
	_on_nav_right()

func _on_instructions_pressed() -> void:
	GameManager.previous_scene = "res://Scenes/index.tscn"
	get_tree().change_scene_to_file("res://Scenes/instructions.tscn")

func _on_exit_pressed() -> void:
	GameManager.quit_dialog.popup_centered()
