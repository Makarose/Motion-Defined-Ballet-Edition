extends Control

@onready var search_bar = $VBoxContainer/LineEdit
@onready var term_list = $VBoxContainer/ItemList

var terms = [] # Will load from ResourceManager

func _ready():
	# Load all terms from ResourceManager
	terms = GameManager.get_terms() 
	terms.sort()
	
	# Fill List
	_populate_list(terms)
	
	# Connect Signals
	search_bar.text_changed.connect(_on_search_changed)
	term_list.item_activated.connect(_on_term_selected) # Double click or enter
	
func _populate_list(term_array: Array):
	term_list.clear()
	for t in term_array:
		term_list.add_item(t)

func _on_search_changed(new_text: String):
	var filtered = []
	for t in terms:
		if new_text == "" or new_text.to_lower() in t.to_lower():
			filtered.append(t)
	_populate_list(filtered)

func _on_term_selected(index: int):
	var selected_term = term_list.get_item_text(index)
	# Save selected term globally
	GameManager.selected_term = selected_term
	
	# Go ack to main menu
	if is_inside_tree():
		get_tree().change_scene_to_file("res://Scenes/main_scene.tscn")
	else:
		print("Node not in tree, cannot change scene!")

func _on_back_button_pressed() -> void:
	if is_inside_tree():
		get_tree().change_scene_to_file("res://Scenes/main_scene.tscn")


func _on_home_button_pressed() -> void:
	if is_inside_tree():
		get_tree().change_scene_to_file("res://Scenes/title_page.tscn")
