# ----------------------------
# index.gd
# ----------------------------



extends Control

@onready var search_bar = $VBoxContainer/LineEdit
@onready var term_list = $VBoxContainer/ItemList

var terms = []          # Will load from GameManager
var current_index := -1 # Tracks highlighted item for keyboard nav

# ____________________________________
# Text Normalization
# ____________________________________
func strip_accents(text: String) -> String:
	var mapping = {
		"á":"a","à":"a","ä":"a","â":"a","ã":"a","å":"a","Á":"A","À":"A","Â":"A","Ä":"A","Ã":"A","Å":"A",
		"é":"e","è":"e","ë":"e","ê":"e","É":"E","È":"E","Ê":"E","Ë":"E",
		"í":"i","ì":"i","ï":"i","î":"i","Í":"I","Ì":"I","Ï":"I","Î":"I",
		"ó":"o","ò":"o","ö":"o","ô":"o","õ":"o","Ó":"O","Ò":"O","Ö":"O","Ô":"O","Õ":"O",
		"ú":"u","ù":"u","ü":"u","û":"u","Ú":"U","Ù":"U","Û":"U","Ü":"U",
		"ñ":"n","Ñ":"N","ç":"c","Ç":"C"
	}
	var result := ""
	for c in text:
		result += mapping.get(c, c)
	return result

func normalize(text: String) -> String:
	return strip_accents(text).to_lower()


# ____________________________________
# Setup
# ____________________________________
func _ready():
	terms = GameManager.get_terms()
	terms.sort_custom(func(a, b): return normalize(a) < normalize(b))
	_populate_list(terms)

	# Connect signals
	search_bar.text_changed.connect(_on_search_changed)
	search_bar.gui_input.connect(_on_search_bar_gui_input)
	term_list.item_activated.connect(_on_term_selected)


# ____________________________________
# Populate List
# ____________________________________	
func _populate_list(term_array: Array):
	term_list.clear()
	current_index = -1
	for t in term_array:
		var idx = term_list.add_item(t)
		term_list.set_item_tooltip(idx, "")


# ____________________________________
# Search
# ____________________________________
func _on_search_changed(new_text: String):
	var filtered = []
	var search_normalized = normalize(new_text)
	for t in terms:
		if search_normalized == "" or search_normalized in normalize(t):
			filtered.append(t)
	_populate_list(filtered)


# ____________________________________
# Term Selection
# ____________________________________
func _on_term_selected(index: int):
	GameManager.selected_term = term_list.get_item_text(index)
	if GameManager.chosen_character == "":
		print(" !!! Warning: No character selected yet, default will be used")
	get_tree().change_scene_to_file("res://Scenes/main_scene.tscn")


# ____________________________________
# Keyboard Navigation (keep exactly as-is)
# ____________________________________
func _on_search_bar_gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
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
				if current_index >= 0 and current_index < term_list.get_item_count():
					_on_term_selected(current_index)
				else:
					# fallback: exact match with typed text
					var normalized_input = normalize(search_bar.text)
					for i in range(term_list.get_item_count()):
						if normalize(term_list.get_item_text(i)) == normalized_input:
							_on_term_selected(i)
							return


# ____________________________________
# Scene Navigation
# ____________________________________
func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/main_scene.tscn")

func _on_home_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/title_page.tscn")
