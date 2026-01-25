extends Control

# ----------------------------
# UI Nodes
# ----------------------------
@onready var search_bar: LineEdit = $VBoxContainer/LineEdit
@onready var term_list: ItemList = $VBoxContainer/ItemList

# ----------------------------
# Runtime state
# ----------------------------
var terms: Array = []         # All ballet moves from GameManager
var current_index := -1       # Tracks highlighted item for keyboard nav

# ----------------------------
# Setup
# ----------------------------
func _ready() -> void:
	print("\t[DEBUG] Index scene ready")
	
	# Load and sort terms from GameManager
	terms = GameManager.get_terms()
	terms.sort_custom(func(a, b): return GameManager.normalize(a) < GameManager.normalize(b))
	_populate_list(terms)

	# Connect local UI signals
	search_bar.text_changed.connect(_on_search_changed)
	search_bar.gui_input.connect(_on_search_bar_gui_input)
	search_bar.grab_focus()
	term_list.item_activated.connect(_on_term_selected)

	# Connect global navigation signals from GameManager
	GameManager.nav_left.connect(Callable(self, "_on_nav_left"))
	GameManager.nav_right.connect(Callable(self, "_on_nav_right"))

# ----------------------------
# Populate List
# ----------------------------
func _populate_list(term_array: Array) -> void:
	print("\t[DEBUG] Populating list, count=", term_array.size())
	term_list.clear()
	current_index = -1
	for t in term_array:
		var idx = term_list.add_item(t)
		term_list.set_item_tooltip(idx, "")

# ----------------------------
# Search
# ----------------------------
func _on_search_changed(new_text: String) -> void:
	var filtered: Array = []
	var search_normalized = GameManager.normalize(new_text)
	for t in terms:
		if search_normalized == "" or search_normalized in GameManager.normalize(t):
			filtered.append(t)
	_populate_list(filtered)

# ----------------------------
# Term Selection
# ----------------------------
func _on_term_selected(index: int) -> void:
	var selected = term_list.get_item_text(index)
	print("\t[DEBUG] Term selected:", selected)
	GameManager.selected_term = selected
	if GameManager.chosen_character == "":
		print("\t !!! Warning: No character selected yet, default will be used")
	get_tree().change_scene_to_file("res://Scenes/main_scene.tscn")

# ----------------------------
# Keyboard Navigation for search list
# ----------------------------
func _on_search_bar_gui_input(event: InputEvent) -> void:
	print("\t[DEBUG] _on_search_bar_gui_input:", event)

	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_DOWN:
				if current_index < term_list.get_item_count() - 1:
					current_index += 1
					term_list.select(current_index)
					term_list.ensure_current_is_visible()
					print("\t\t[DEBUG] KEY_DOWN, current_index=", current_index)
			KEY_UP:
				if current_index > 0:
					current_index -= 1
					term_list.select(current_index)
					term_list.ensure_current_is_visible()
					print("\t\t[DEBUG] KEY_UP, current_index=", current_index)
			KEY_ENTER, KEY_KP_ENTER:
				if current_index >= 0 and current_index < term_list.get_item_count():
					print("\t\t[DEBUG] ENTER pressed, selecting item at index=", current_index)
					_on_term_selected(current_index)
				else:
					var normalized_input = GameManager.normalize(search_bar.text)
					for i in range(term_list.get_item_count()):
						if GameManager.normalize(term_list.get_item_text(i)) == normalized_input:
							_on_term_selected(i)
							return
			KEY_LEFT:
				print("\t\t[DEBUG] LEFT pressed, forwarding nav_left")
				_on_nav_left()
			KEY_RIGHT:
				print("\t\t[DEBUG] RIGHT pressed, forwarding nav_right")
				_on_nav_right()

# ----------------------------
# Scene-specific handlers for GameManager signals
# ----------------------------
func _on_nav_left() -> void:
	print("\t[DEBUG] _on_nav_left called")
	_on_back_button_pressed()  # Left arrow goes back

func _on_nav_right() -> void:
	print("\t[DEBUG] _on_nav_right called")
	_on_home_button_pressed()  # Right arrow goes home

# ----------------------------
# Scene Navigation
# ----------------------------
func _on_back_button_pressed() -> void:
	print("\t[DEBUG] Back button pressed")
	get_tree().call_deferred(
	"change_scene_to_file",
	"res://Scenes/main_scene.tscn"
)

func _on_home_button_pressed() -> void:
	print("\t[DEBUG] Home button pressed")
	get_tree().call_deferred(
	"change_scene_to_file",
	"res://Scenes/title_page.tscn"
)
