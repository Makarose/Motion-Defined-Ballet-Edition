extends Control

@onready var search_bar = $VBoxContainer/LineEdit
@onready var term_list = $VBoxContainer/ItemList

var terms = [] # Will load from ResourceManager
var selected_term: String = "" # store the currently selected term

# ____________________________________
# Text Normalization
# ____________________________________
# Strips user input of accented characters.
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
		result += mapping.get(c, c) # replace if in mapping, else keep original
	return result
	
# Helps to normalize user inputted text.
func normalize(text: String) -> String:
	return strip_accents(text).to_lower()



func _ready():
	# Load all terms from ResourceManager
	terms = GameManager.get_terms() 
	
	# Sort accent-insensitive but still display original
	terms.sort_custom(func(a, b): return normalize(a) < normalize(b))
	
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
	var search_normalized = normalize(new_text)
	
	for t in terms:
		if search_normalized == "" or search_normalized in normalize(t):
			filtered.append(t)
	_populate_list(filtered)

func _on_term_selected(index: int):
	var selected_term = term_list.get_item_text(index)
	
	#Saves globally so GameManager knows what to do
	GameManager.selected_term = selected_term
	
	if GameManager.chosen_character == "":
		print(" !!! Warning: No character selected yet, dfault will be used")
		
	# Return to main scene, where the animation will automatically play
	get_tree().change_scene_to_file("res://Scenes/main_scene.tscn")

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/main_scene.tscn")


func _on_home_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/title_page.tscn")
