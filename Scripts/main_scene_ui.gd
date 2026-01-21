# ----------------------------
# main_scene_ui.gd
# ----------------------------

extends Control

# ----------------------------
# Signals
# ----------------------------
signal term_selected(animation_name: String)
signal character_requested(character_scene_path: String)
signal fullscreen_requested()

# ----------------------------
# UI Nodes
# ----------------------------
@onready var search_bar: LineEdit = $CanvasLayer/Search/MarginContainerText/VBoxContainer/LineEdit
@onready var item_list: ItemList = $CanvasLayer/Search/MarginContainerText/VBoxContainer/ItemList
@onready var definition_label: RichTextLabel = $CanvasLayer/Definitions/MarginContainerTextMain/VBoxContainer/MarginContainerText/DefinitionLabel
@onready var title_label: RichTextLabel = $CanvasLayer/Definitions/MarginContainerTextMain/VBoxContainer/MarginContainerTitle/TitleLabel

@onready var fullscreen_container: MarginContainer = $CanvasLayer/Fullscreen
@onready var fullscreen_button: TextureButton = $CanvasLayer/Fullscreen/HBoxContainer/FullscreenButton
@onready var male_button: Button = $CanvasLayer/Fullscreen/MaleButton
@onready var female_button: Button = $CanvasLayer/Fullscreen/FemaleButton

# ----------------------------
# Resources
# ----------------------------
@export var database: BalletMoveDatabase

# ----------------------------
# Runtime state
# ----------------------------
var current_index := -1
var clear_timer: Timer
var has_selected_term := false

# ----------------------------
# Ready
# ----------------------------
func _ready() -> void:
	_show_fullscreen_controls(false)

	search_bar.text_changed.connect(_on_search_text_changed)
	search_bar.gui_input.connect(_on_search_bar_gui_input)
	search_bar.text_submitted.connect(_on_search_bar_entered)
	search_bar.grab_focus()

	item_list.item_selected.connect(_on_item_selected)
	item_list.visible = false

	clear_timer = Timer.new()
	clear_timer.one_shot = true
	clear_timer.wait_time = 0.8
	clear_timer.timeout.connect(_clear_search_now)
	add_child(clear_timer)

	# Connect buttons
	if fullscreen_button:
		fullscreen_button.pressed.connect(_on_fullscreen_pressed)
	if male_button:
		male_button.pressed.connect(_on_male_pressed)
	if female_button:
		female_button.pressed.connect(_on_female_pressed)

	if not database:
		database = load("res://Definition Resources/ballet_moves_database.tres")

# ----------------------------
# Input handling
# ----------------------------
func _input(event: InputEvent) -> void:
	# If the fullscreen button is currently pressed, skip scene navigation
	if $CanvasLayer/Fullscreen/HBoxContainer/FullscreenButton.pressed:
		return

	if event is InputEventKey and event.pressed:
		if Input.is_action_just_pressed("ui_left"):
			_on_back_button_pressed()
		elif Input.is_action_just_pressed("ui_right"):
			_on_index_button_pressed()


# ----------------------------
# Search / Item List
# ----------------------------
func _on_search_text_changed(new_text: String) -> void:
	item_list.clear()
	current_index = -1

	if new_text == "":
		item_list.visible = false
		return

	var normalized_input = GameManager.normalize(new_text)
	for balletmove in database.moves:
		if GameManager.normalize(balletmove.name).begins_with(normalized_input):
			item_list.add_item(balletmove.name)

	item_list.visible = item_list.get_item_count() > 0

func _on_item_selected(index: int) -> void:
	current_index = index
	_select_item(index)

func _on_search_bar_gui_input(event: InputEvent) -> void:
	if not item_list.visible:
		return

	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_DOWN:
				if current_index < item_list.get_item_count() - 1:
					current_index += 1
					item_list.select(current_index)
					item_list.ensure_current_is_visible()
			KEY_UP:
				if current_index > 0:
					current_index -= 1
					item_list.select(current_index)
					item_list.ensure_current_is_visible()
			KEY_ENTER, KEY_KP_ENTER:
				if current_index >= 0:
					_select_item(current_index)

func _on_search_bar_entered(_text: String) -> void:
	if current_index >= 0:
		_select_item(current_index)

func _select_item(index: int) -> void:
	if index < 0 or index >= item_list.get_item_count():
		return

	var selected_name = item_list.get_item_text(index)
	var move: BalletMove = null

	for balletmove in database.moves:
		if GameManager.normalize(balletmove.name) == GameManager.normalize(selected_name):
			move = balletmove
			break

	if not move:
		return

	title_label.text = move.name
	definition_label.text = move.definition

	search_bar.text = selected_name
	item_list.visible = false
	search_bar.grab_focus()
	clear_timer.start()

	has_selected_term = true

	if move.animation_name.strip_edges() != "":
		emit_signal("term_selected", move.animation_name)

# ----------------------------
# Clear search
# ----------------------------
func _clear_search_now() -> void:
	search_bar.text = ""
	current_index = -1
	item_list.clear()
	item_list.visible = false

# ----------------------------
# Fullscreen & Character Controls
# ----------------------------
func show_fullscreen_button() -> void:
	print("SHOW FULLSCREEN BUTTON CALLED")
	_show_fullscreen_controls(true)

func hide_fullscreen_button() -> void:
	_show_fullscreen_controls(false)

func _show_fullscreen_controls(show: bool) -> void:
	if not fullscreen_container:
		push_error("Fullscreen container is NULL")
		return
	fullscreen_container.visible = show

func _on_fullscreen_pressed() -> void:
	emit_signal("fullscreen_requested")

func _on_male_pressed() -> void:
	emit_signal("character_requested", "res://Scenes/male.tscn")

func _on_female_pressed() -> void:
	emit_signal("character_requested", "res://Scenes/female.tscn")

# ----------------------------
# F1 keyboard trigger for fullscreen
# ----------------------------
func _unhandled_input(event: InputEvent) -> void:
	if fullscreen_container.visible and event is InputEventKey and event.pressed:
		if Input.is_action_just_pressed("launch_fullscreen"):
			print("launch_fullscreen action detected!")
			_on_fullscreen_pressed()

# ----------------------------
# Navigation
# ----------------------------
func _on_back_button_pressed() -> void:
	GameManager.selected_term = ""
	GameManager.last_played_animation = ""
	get_tree().change_scene_to_file("res://Scenes/title_page.tscn")

func _on_index_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/index.tscn")
