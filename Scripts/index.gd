# ----------------------------
# index.gd
# ----------------------------
extends Control

# ----------------------------
# Nodes
# ----------------------------
@onready var search_bar: LineEdit = $VBoxContainer/LineEdit
@onready var term_list: ItemList = $VBoxContainer/ItemList

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
	var back_button = get_node_or_null("Back/MarginContainer/BackButton")
	if back_button:
		back_button.pressed.connect(_on_back_button_pressed)
	var home_button = get_node_or_null("Home/MarginContainer/HomeButton")
	if home_button:
		home_button.pressed.connect(_on_home_button_pressed)
	
	# GameManager nav signals
	GameManager.nav_left.connect(_on_nav_left)
	GameManager.nav_right.connect(_on_nav_right)


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
