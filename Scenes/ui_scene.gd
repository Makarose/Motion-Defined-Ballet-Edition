extends Control

@onready var search_bar: LineEdit = $CanvasLayer/Search/MarginContainerText/VBoxContainer/LineEdit
@onready var item_list = $CanvasLayer/Search/MarginContainerText/VBoxContainer/ItemList
@onready var selected_label: RichTextLabel = $CanvasLayer/Search/MarginContainerText/VBoxContainer/SelectedMove
@onready var definition_label: RichTextLabel = $CanvasLayer/Definitions/MarginContainerTextMain/VBoxContainer/MarginContainerText/DefinitionLabel

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

# Called whenever the search bar text changes
func _on_search_text_changed(new_text: String) -> void:
	item_list.clear()
	selected_label.set_text("") #clear by default
	
	if new_text == "":
		item_list.visible = false
		return
	
	for balletmove in database.moves:
		var move_name = balletmove.name
		if move_name.to_lower().begins_with(new_text.to_lower()):
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
	
	# find it's definition from the database
	for balletmove in database.moves:
		if balletmove.name == selected_move:
			definition_label.set_text(balletmove.definition)
			break
	
	# Optional: do something with the selected move
	print("Selected move:", selected_move)
