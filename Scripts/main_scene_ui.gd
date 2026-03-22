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
@onready var back_button: TextureButton = $MarginContainer/HBoxContainer/BackContainer/VBoxContaine/BackButton
@onready var index_button: TextureButton = $MarginContainer/HBoxContainer/IndexContainer/VBoxContainer/IndexButton
@onready var replay_container: MarginContainer = $CanvasLayer/ReplayContainer
@onready var replay_button: TextureButton = $CanvasLayer/ReplayContainer/HBoxContainer/ReplayButton
@onready var fullscreen_container: MarginContainer = $CanvasLayer/FullscreenContainer
@onready var fullscreen_button: TextureButton = $CanvasLayer/FullscreenContainer/HBoxContainer/FullscreenButton
@onready var music_button: TextureButton = $MarginContainer/HBoxContainer/MusicContainer/VBoxContaine/MusicButton
@onready var instructions_button: TextureButton = $MarginContainer/HBoxContainer/InstructionsContainer/VBoxContainer/InstructionsButton
@onready var exit_button: TextureButton = $MarginContainer/HBoxContainer/ExitContainer/VBoxContainer/ExitButton
@onready var random_button: TextureButton = $CanvasLayer/RandomContainer/HBoxContainer/RandomButton
@onready var random_container: MarginContainer = $CanvasLayer/RandomContainer

@onready var replay_label: Label = $CanvasLayer/ReplayContainer/HBoxContainer/ReplayLabel
@onready var fullscreen_label: Label = $CanvasLayer/FullscreenContainer/HBoxContainer/FullscreenLabel
@onready var random_label: Label = $CanvasLayer/RandomContainer/HBoxContainer/RandomLabel
@onready var back_label: Label = $MarginContainer/HBoxContainer/BackContainer/VBoxContaine/BackLabel
@onready var instructions_label: Label = $MarginContainer/HBoxContainer/InstructionsContainer/VBoxContainer/InstructionsLabel
@onready var index_label: Label = $MarginContainer/HBoxContainer/IndexContainer/VBoxContainer/IndexLabel
@onready var music_label: Label = $MarginContainer/HBoxContainer/MusicContainer/VBoxContaine/MusicLabel
@onready var exit_label: Label = $MarginContainer/HBoxContainer/ExitContainer/VBoxContainer/ExitLabel

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
# Button state enum
# ----------------------------
enum ButtonState { RANDOM, FULLSCREEN, REPLAY }

# ----------------------------
# Single source of truth for button visibility
# ----------------------------
func set_button_state(state: ButtonState) -> void:
	# Always hide all first
	random_container.visible = false
	fullscreen_container.visible = false
	replay_container.visible = false

	match state:
		ButtonState.RANDOM:
			random_container.visible = true
			if replay_timer:
				replay_timer.stop()
		ButtonState.FULLSCREEN:
			fullscreen_container.visible = true
			if replay_timer:
				replay_timer.stop()
		ButtonState.REPLAY:
			replay_container.visible = true
			if replay_timer:
				replay_timer.start()

# ----------------------------
# Ready
# ----------------------------
func _ready() -> void:
	# Hide all buttons immediately to prevent flicker
	fullscreen_container.visible = false
	replay_container.visible = false
	random_container.visible = false

	print("[MainSceneUI] Ready")

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

	# Clear timer
	clear_timer = Timer.new()
	clear_timer.one_shot = true
	clear_timer.wait_time = 0.8
	clear_timer.timeout.connect(_clear_search_now)
	add_child(clear_timer)

	# Replay timer
	replay_timer = Timer.new()
	replay_timer.one_shot = true
	replay_timer.wait_time = replay_timeout_seconds
	replay_timer.timeout.connect(_on_replay_timeout)
	add_child(replay_timer)

	# GameManager nav signals
	GameManager.nav_left.connect(_on_nav_left)
	GameManager.nav_right.connect(_on_nav_right)

	# Shortcut labels
	replay_label.text = "REPLAY [" + GameManager.get_shortcut_text("replay_from_main") + "]"
	fullscreen_label.text = "FULLSCREEN [" + GameManager.get_shortcut_text("launch_fullscreen") + "]"
	random_label.text = "RANDOM [" + GameManager.get_shortcut_text("random") + "]"
	back_label.text = "BACK\n[" + GameManager.get_shortcut_text("nav_left") + "]"
	instructions_label.text = "INSTRUCTIONS\n[" + GameManager.get_shortcut_text("open_instructions") + "]"
	index_label.text = "INDEX\n[" + GameManager.get_shortcut_text("nav_right") + "]"
	music_label.text = "MUSIC ON/OFF\n[" + GameManager.get_shortcut_text("music_toggle") + "]"
	exit_label.text = "EXIT\n[" + GameManager.get_shortcut_text("quit_app") + "]"

	# Font sizes
	back_label.add_theme_font_size_override("font_size", 18)
	music_label.add_theme_font_size_override("font_size", 18)
	instructions_label.add_theme_font_size_override("font_size", 18)
	exit_label.add_theme_font_size_override("font_size", 18)
	index_label.add_theme_font_size_override("font_size", 18)
	replay_label.add_theme_font_size_override("font_size", 18)
	fullscreen_label.add_theme_font_size_override("font_size", 18)
	random_label.add_theme_font_size_override("font_size", 18)

	# HBox spacing
	var hbox = $MarginContainer/HBoxContainer
	if hbox:
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		if GameManager.is_macos():
			hbox.add_theme_constant_override("separation", 350)
		else:
			hbox.add_theme_constant_override("separation", 400)

	# Show correct buttons immediately
	if GameManager.selected_term == "":
		set_button_state(ButtonState.RANDOM)
	else:
		set_button_state(ButtonState.FULLSCREEN)

	# Wait for layout to settle for focus only
	if OS.get_name() == "macOS":
		await get_tree().create_timer(0.2).timeout
	else:
		await get_tree().process_frame
		await get_tree().process_frame

	search_bar.grab_focus()
	print("[MainSceneUI] Focus owner after ready:", get_viewport().gui_get_focus_owner())
	
	
# ----------------------------
# Search Bar Input
# ----------------------------
func _on_search_bar_gui_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return

	print("[SearchBar] keycode:", event.keycode, " ctrl:", event.ctrl_pressed, " shift:", event.shift_pressed)

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
func _on_random_pressed() -> void:
	if database.moves.size() == 0:
		return

	var random_index = randi() % database.moves.size()
	var random_move = database.moves[random_index]

	title_label.text = random_move.name
	definition_label.text = random_move.definition
	GameManager.selected_definition = random_move.definition

	set_button_state(ButtonState.FULLSCREEN)

	if random_move.animation_name.strip_edges() != "":
		emit_signal("term_selected", random_move.name, random_move.animation_name, random_move.definition)


# ----------------------------
# Convenience wrappers — all route through set_button_state
# ----------------------------
func show_random_button() -> void:
	set_button_state(ButtonState.RANDOM)

func hide_random_button() -> void:
	random_container.visible = false

func show_fullscreen_button() -> void:
	set_button_state(ButtonState.FULLSCREEN)

func hide_fullscreen_button() -> void:
	fullscreen_container.visible = false

func show_replay_button() -> void:
	set_button_state(ButtonState.REPLAY)

func hide_replay_button() -> void:
	replay_container.visible = false
	if replay_timer:
		replay_timer.stop()


# ----------------------------
# Core selection logic
# ----------------------------
func _select_item(index: int) -> void:
	if index < 0 or index >= item_list.get_item_count():
		return

	var selected_name: String = item_list.get_item_text(index)
	var move: BalletMove = database.get_move_by_name(selected_name)

	if not move:
		push_warning("[MainSceneUI] Move not found in database: " + selected_name)
		return

	title_label.text = move.name
	definition_label.text = move.definition
	search_bar.text = move.name
	item_list.visible = false

	set_button_state(ButtonState.FULLSCREEN)

	clear_timer.start()

	if move.animation_name.strip_edges() != "":
		emit_signal("term_selected", move.name, move.animation_name, move.definition)
	else:
		push_warning("[MainSceneUI] No animation name set for move: " + move.name)


# ----------------------------
# Restore term when arriving from index page
# ----------------------------
func restore_term(term: String, definition: String) -> void:
	title_label.text = term
	definition_label.text = definition
	set_button_state(ButtonState.FULLSCREEN)


# ----------------------------
# Clear search bar after selection
# ----------------------------
func _clear_search_now() -> void:
	search_bar.text = ""
	current_index = -1
	item_list.clear()
	item_list.visible = false


# ----------------------------
# Fullscreen button pressed
# ----------------------------
func _on_fullscreen_key_pressed() -> void:
	if fullscreen_container.visible:
		emit_signal("fullscreen_requested")


# ----------------------------
# Replay timeout — switch back to random
# ----------------------------
func _on_replay_timeout() -> void:
	set_button_state(ButtonState.RANDOM)


# ----------------------------
# Replay button pressed
# ----------------------------
func _on_replay_pressed() -> void:
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
# Navigation
# ----------------------------
func _on_nav_left() -> void:
	if replay_timer:
		replay_timer.stop()
	emit_signal("back_pressed")

func _on_nav_right() -> void:
	emit_signal("index_pressed")


# ----------------------------
# Search movement
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


# ----------------------------
# Input
# ----------------------------
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
