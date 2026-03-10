# ----------------------------
# main_scene_ui.gd
# ----------------------------
extends Control

# ----------------------------
# Signals
# ----------------------------
signal term_selected(term: String, anim_name: String, definition: String)
signal fullscreen_requested
signal back_pressed
signal index_pressed
signal replay_requested

@export var replay_timeout_seconds: float = 10.0

# ----------------------------
# Nodes
# ----------------------------
@onready var search_bar: LineEdit = $CanvasLayer/Search/MarginContainerText/VBoxContainer/LineEdit
@onready var item_list: ItemList = $CanvasLayer/Search/MarginContainerText/VBoxContainer/ItemList
@onready var definition_label: RichTextLabel = $CanvasLayer/Definitions/MarginContainerTextMain/VBoxContainer/MarginContainerText/DefinitionLabel
@onready var title_label: RichTextLabel = $CanvasLayer/Definitions/MarginContainerTextMain/VBoxContainer/MarginContainerTitle/TitleLabel
@onready var back_button: TextureButton = $MarginContainer/HBoxContainer/BackButtonContainer/VBoxContainer/BackButton
@onready var index_button: TextureButton = $MarginContainer/HBoxContainer/IndexButtonContainer/VBoxContainer/IndexButton
@onready var replay_container: MarginContainer = $CanvasLayer/ReplayContainer
@onready var replay_button: TextureButton = $CanvasLayer/ReplayContainer/HBoxContainer/ReplayButton
@onready var fullscreen_container: MarginContainer = $CanvasLayer/FullscreenContainer
@onready var fullscreen_button: TextureButton = $CanvasLayer/FullscreenContainer/HBoxContainer/FullscreenButton
@onready var music_button: TextureButton = $MarginContainer/HBoxContainer/MusicContainer/VBoxContaine/MusicButton
@onready var instructions_button: TextureButton = $MarginContainer/HBoxContainer/InstructionsContainer/VBoxContainer/InstructionsButton
@onready var exit_button: TextureButton = $MarginContainer/HBoxContainer/ExitContainer/VBoxContainer/ExitButton
@onready var random_button: TextureButton = $CanvasLayer/RandomContainer/HBoxContainer/RandomButton
@onready var random_container: MarginContainer = $CanvasLayer/RandomContainer


# ----------------------------
# Resources
# ----------------------------
@export var database: BalletMoveDatabase

# ----------------------------
# Runtime state
# ----------------------------
var current_index: int = -1
var clear_timer: Timer
var replay_timer: Timer

# ----------------------------
# Ready
# ----------------------------
func _ready() -> void:
	print("[MainSceneUI] Ready")
	await get_tree().process_frame
	search_bar.grab_focus()
	print("[MainSceneUI] Focus owner after ready:", get_viewport().gui_get_focus_owner())
	
	# Only hide fullscreen button if no term is selected
	if GameManager.selected_term == "":
		fullscreen_container.visible = false
	else:
		fullscreen_container.visible = true
	
	# Hide replay button initially
	if replay_container:
		replay_container.visible = false
	
	# Show random button initially
	if random_container:
		random_container.visible = true
	
	# Load database if not set in inspector
	if not database:
		database = load("res://Definition Resources/ballet_moves_database.tres")
	
	# Search bar signals
	search_bar.text_changed.connect(_on_search_changed)
	search_bar.text_submitted.connect(_on_text_submitted)
	search_bar.gui_input.connect(_on_search_bar_gui_input)
	
	# Item list signals
	item_list.item_selected.connect(_on_item_selected)
	item_list.visible = false
	
	# Button connections
	fullscreen_button.pressed.connect(_on_fullscreen_key_pressed)
	replay_button.pressed.connect(_on_replay_pressed)
	random_button.pressed.connect(_on_random_pressed)
	back_button.pressed.connect(_on_nav_left)
	index_button.pressed.connect(_on_nav_right)
	
	if music_button:
		music_button.pressed.connect(GameManager.toggle_music)
	if instructions_button:
		instructions_button.pressed.connect(_on_instructions_pressed)
	if exit_button:
		exit_button.pressed.connect(_on_exit_pressed)
	
	# Clear timer — clears search bar shortly after selection
	clear_timer = Timer.new()
	clear_timer.one_shot = true
	clear_timer.wait_time = 0.8
	clear_timer.timeout.connect(_clear_search_now)
	add_child(clear_timer)
	
	# Replay timer - switches back to random after delay
	replay_timer = Timer.new()
	replay_timer.one_shot = true
	replay_timer.wait_time = replay_timeout_seconds
	replay_timer.timeout.connect(_on_replay_timeout)
	add_child(replay_timer)
	
	# GameManager nav signals
	GameManager.nav_left.connect(_on_nav_left)
	GameManager.nav_right.connect(_on_nav_right)
	
# ----------------------------
# Search Bar Input
# ----------------------------
func _on_search_bar_gui_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
		
	print("[SearchBar] keycode:", event.keycode, " ctrl:", event.ctrl_pressed)
	
	if event.ctrl_pressed:
		if event.keycode == KEY_LEFT or event.physical_keycode == KEY_LEFT:
			accept_event()
			_on_nav_left()
		elif event.keycode == KEY_RIGHT or event.physical_keycode == KEY_RIGHT:
			accept_event()
			_on_nav_right()
		return
	
	if event.keycode == KEY_UP:
		accept_event()
		_on_search_move_up()
	elif event.keycode == KEY_DOWN:
		accept_event()
		_on_search_move_down()
	elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
		accept_event()
		_on_search_confirmed()
	elif event.keycode == KEY_F1:
		accept_event()
		_on_fullscreen_key_pressed()


# ----------------------------
# Search bar text changed
# Filters item list as user types
# ----------------------------
func _on_search_changed(new_text: String) -> void:
	item_list.clear()
	current_index = -1

	if new_text.strip_edges() == "":
		item_list.visible = false
		return

	var normalized_input = GameManager.normalize(new_text)
	for move in database.moves:
		if GameManager.normalize(move.name).begins_with(normalized_input):
			item_list.add_item(move.name)

	item_list.visible = item_list.get_item_count() > 0
	
	# Auto-select exact match
	if item_list.get_item_count() > 0:
		for i in range(item_list.get_item_count()):
			if GameManager.normalize(item_list.get_item_text(i)) == normalized_input:
				current_index = i
				item_list.select(i)
				item_list.ensure_current_is_visible()
				break


# ----------------------------
# Item clicked directly in list
# ----------------------------
func _on_item_selected(index: int) -> void:
	current_index = index
	_select_item(index)


# ----------------------------
# Enter pressed on search bar
# ----------------------------
func _on_text_submitted(_text: String) -> void:
	if current_index >= 0:
		_select_item(current_index)
		
# ----------------------------
# Random term selection
# ----------------------------
# ----------------------------
# Random term selection and button visibility
# ----------------------------
func _on_random_pressed() -> void:
	if database.moves.size() == 0:
		return
	
	# Pick a random move
	var random_index = randi() % database.moves.size()
	var random_move = database.moves[random_index]
	
	# Update UI
	title_label.text = random_move.name
	definition_label.text = random_move.definition
	GameManager.selected_definition = random_move.definition
	
	# Hide random, show fullscreen
	hide_random_button()
	show_fullscreen_button()
	hide_replay_button()
	
	# Emit signal to play animation
	if random_move.animation_name.strip_edges() != "":
		emit_signal("term_selected", random_move.name, random_move.animation_name, random_move.definition)

func show_random_button() -> void:
	if random_container:
		random_container.visible = true

func hide_random_button() -> void:
	if random_container:
		random_container.visible = false
		
		
# ----------------------------
# Core selection logic
# Finds the move, updates UI, emits signal up to MainScene
# ----------------------------
func _select_item(index: int) -> void:
	if index < 0 or index >= item_list.get_item_count():
		return

	var selected_name: String = item_list.get_item_text(index)
	var move: BalletMove = database.get_move_by_name(selected_name)

	if not move:
		push_warning("[MainSceneUI] Move not found in database: " + selected_name)
		return

	# Update UI
	title_label.text = move.name
	definition_label.text = move.definition
	search_bar.text = move.name
	item_list.visible = false
	search_bar.release_focus()

	# Show fullscreen button
	fullscreen_container.visible = true

	# Start timer to clear search bar
	clear_timer.start()

	# Emit up to MainScene with all three pieces of info
	if move.animation_name.strip_edges() != "":
		emit_signal("term_selected", move.name, move.animation_name, move.definition)
	else:
		push_warning("[MainSceneUI] No animation name set for move: " + move.name)


# ----------------------------
# Restore term when arriving from index page
# Called by MainScene on _ready() if GameManager has a selected term
# ----------------------------
func restore_term(term: String, definition: String) -> void:
	title_label.text = term
	definition_label.text = definition
	fullscreen_container.visible = true


# ----------------------------
# Clear search bar after selection
# ----------------------------
func _clear_search_now() -> void:
	search_bar.text = ""
	current_index = -1
	item_list.clear()
	item_list.visible = false


# ----------------------------
# Show / hide fullscreen button
# ----------------------------
func show_fullscreen_button() -> void:
	fullscreen_container.visible = true
	print("[MainSceneUI] Fullscreen button SHOWN")

func hide_fullscreen_button() -> void:
	fullscreen_container.visible = false
	print("[MainSceneUI] Fullscreen button HIDDEN")


# ----------------------------
# Fullscreen button pressed
# ----------------------------
func _on_fullscreen_key_pressed() -> void:
	if fullscreen_container.visible:
		emit_signal("fullscreen_requested")
		
		
# ----------------------------
# Replay Button Visibility
# ----------------------------		
func show_replay_button() -> void:
	if replay_container:
		replay_container.visible = true
	hide_fullscreen_button()
	hide_random_button()
	
	# Start timer to switch back to random
	replay_timer.start()

func hide_replay_button() -> void:
	if replay_container:
		replay_container.visible = false
		
func _on_replay_timeout() -> void:
	hide_replay_button()
	show_random_button()
		
# ----------------------------
# Replay button pressed
# ----------------------------
func _on_replay_pressed() -> void:
	# Stop the timer when manually replaying
	if replay_timer:
		replay_timer.stop()
	
	emit_signal("replay_requested")
	
# ----------------------------
# Instructions
# ----------------------------
func _on_instructions_pressed() -> void:
	GameManager.previous_scene = "res://Scenes/main_scene.tscn"
	get_tree().change_scene_to_file("res://Scenes/instructions.tscn")

# ----------------------------
# Exit
# ----------------------------
func _on_exit_pressed() -> void:
	GameManager.quit_dialog.popup_centered()

# ----------------------------
# Navigation — emit signals up, never change scene directly
# ----------------------------
func _on_nav_left() -> void:
	emit_signal("back_pressed")

func _on_nav_right() -> void:
	emit_signal("index_pressed")
	


# ----------------------------
# Arrow key functions?
# ----------------------------
func _on_search_move_up() -> void:
	if current_index > 0:
		current_index -= 1
		item_list.select(current_index)
		item_list.ensure_current_is_visible()

func _on_search_move_down() -> void:
	if current_index < item_list.get_item_count() - 1:
		current_index += 1
		item_list.select(current_index)
		item_list.ensure_current_is_visible()

func _on_search_confirmed() -> void:
	if current_index >= 0:
		_select_item(current_index)
	else:
		var normalized_input = GameManager.normalize(search_bar.text)
		for i in range(item_list.get_item_count()):
			if GameManager.normalize(item_list.get_item_text(i)) == normalized_input:
				_select_item(i)
				return
				
func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	print("[MainSceneUI] _input keycode:", event.keycode, " ctrl:", event.ctrl_pressed, " is_fullscreen:", GameManager.is_fullscreen, " handled:", get_viewport().is_input_handled())

	if GameManager.is_fullscreen:
		if event.is_action("exit_fullscreen") or event.is_action("ui_focus_next"):
			get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("launch_fullscreen", false):
		get_viewport().set_input_as_handled()
		_on_fullscreen_key_pressed()
		
	if event.is_action_pressed("replay_from_main", false):
		get_viewport().set_input_as_handled()
		_on_replay_pressed()
	
	if event.is_action_pressed("music_toggle", false):
		get_viewport().set_input_as_handled()
		GameManager.toggle_music()
	
	if event.is_action_pressed("open_instructions", false):
		get_viewport().set_input_as_handled()
		_on_instructions_pressed()
	
	if event.is_action_pressed("quit_app", false):
		get_viewport().set_input_as_handled()
		_on_exit_pressed()
	
	if event.is_action_pressed("random", false):
		get_viewport().set_input_as_handled()
		_on_random_pressed()
