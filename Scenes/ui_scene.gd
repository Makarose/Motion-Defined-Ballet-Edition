extends Control

@onready var search_bar: LineEdit = $CanvasLayer/Search/MarginContainerText/VBoxContainer/LineEdit
@onready var item_list = $CanvasLayer/Search/MarginContainerText/VBoxContainer/ItemList
@onready var selected_label: RichTextLabel = $CanvasLayer/Search/MarginContainerText/VBoxContainer/SelectedMove
@onready var definition_label: RichTextLabel = $CanvasLayer/Definitions/MarginContainerTextMain/VBoxContainer/MarginContainerText/DefinitionLabel
@onready var title_label: RichTextLabel = $CanvasLayer/Definitions/MarginContainerTextMain/VBoxContainer/MarginContainerTitle/TitleLabel

var database: BalletMoveDatabase

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Load the database
	database = load("res://Definition Resources/ballet_moves_database.tres")
	print("Database loaded:", database)
	print("Moves:", database.moves)
	
	# Connect signals
	search_bar.text_changed.connect(_on_search_text_changed)
	item_list.item_selected.connect(_on_item_selected)
	
	# Initially hide ItemList until typing starts
	item_list.visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

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

# Called whenever the search bar text changes
func _on_search_text_changed(new_text: String) -> void:
	item_list.clear()
	selected_label.set_text("") #clear by default
	
	if new_text == "":
		item_list.visible = false
		return
		
	var normalized_input = normalize(new_text)
	
	for balletmove in database.moves:
		var move_name = balletmove.name
		if normalize(move_name).begins_with(normalized_input):
			item_list.add_item(move_name)
			# show first match as text above search bar
			if selected_label.get_text() == "":
				selected_label.set_text(move_name)
			
	# Show list only if we have a match
	item_list.visible = item_list.get_item_count() > 0
	
# Called when the user selects an item from the list
func _on_item_selected(index: int) -> void:
	var selected_move = item_list.get_item_text(index)
	search_bar.text = selected_move
	selected_label.set_text(selected_move) # update label
	item_list.visible = false	
	
	# Find definition with normalized comparison. 
	var norm_selected = normalize(selected_move)
	
	# find it's definition from the database
	for balletmove in database.moves:
		if normalize(balletmove.name) == norm_selected:
			definition_label.set_text(balletmove.definition)
			title_label.set_text(balletmove.name) #keep accents for display text.
			break
	
	# Optional: do something with the selected move
	print("Selected move:", selected_move)
