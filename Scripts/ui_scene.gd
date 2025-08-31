extends Control

@onready var search_bar: LineEdit = $CanvasLayer/Search/MarginContainerText/VBoxContainer/LineEdit
@onready var item_list = $CanvasLayer/Search/MarginContainerText/VBoxContainer/ItemList
@onready var definition_label: RichTextLabel = $CanvasLayer/Definitions/MarginContainerTextMain/VBoxContainer/MarginContainerText/DefinitionLabel
@onready var title_label: RichTextLabel = $CanvasLayer/Definitions/MarginContainerTextMain/VBoxContainer/MarginContainerTitle/TitleLabel
@onready var dancer_viewport: SubViewport = $"../DancerViewport"

@export var database: BalletMoveDatabase


var current_index := -1 # Tracks which suggestion is highlighted.
var clear_timer: Timer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Load the database
	if not database:
		database = load("res://Definition Resources/ballet_moves_database.tres")
	print("Database loaded:", database)
	print("Moves:", database.moves)
	
	# Connect signals
	search_bar.text_changed.connect(_on_search_text_changed)
	item_list.item_selected.connect(_on_item_selected)
	search_bar.gui_input.connect(_on_search_bar_gui_input)
	search_bar.connect("text_submitted", Callable(self, "_on_search_bar_entered"))
	
	# Initially hide ItemList until typing starts
	item_list.visible = false
	
# Create and configure the timer
	clear_timer = Timer.new()
	clear_timer.one_shot = true
	clear_timer.wait_time = 0.8  # show selection for 0.8 seconds
	clear_timer.connect("timeout", Callable(self, "_clear_search_now"))
	add_child(clear_timer)

func _on_animation_started(anim_name: String) -> void:
	print("Animation started:", anim_name)
	
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
	current_index = -1
	
	if new_text == "":
		item_list.visible = false
		return
		
	var normalized_input = normalize(new_text)
	for balletmove in database.moves:
		var move_name = balletmove.name
		if normalize(move_name).begins_with(normalized_input):
			item_list.add_item(move_name)
			
	# Show list only if we have a match
	item_list.visible = item_list.get_item_count() > 0
	
# Called when the user clicks a suggestion.
func _on_item_selected(index: int) -> void:
	current_index = index
	_select_item(index)
	
# Handles keyboard navigation
func _on_search_bar_gui_input(event: InputEvent) -> void:
	if not item_list.visible:
		return
			
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_DOWN:
				# Move focus to ItemList if nothing is slected
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
				if current_index >= 0 and current_index < item_list.get_item_count():
					_select_item(current_index)
					print("Enter pressed, selected:", item_list.get_item_text(current_index))
					return
					
# Called when user presses Enter in the search bar
func _on_search_bar_entered(new_text: String) -> void:
	if current_index >= 0 and current_index < item_list.get_item_count():
		_select_item(current_index)
		print("Enter pressed, dropdown or highlighted item selected:", item_list.get_item_text(current_index))
		return
	
	# Only pick exact match if nothing is highlighted
	var normalized_input = normalize(new_text)
	for i in range(item_list.get_item_count()):
		if normalize(item_list.get_item_text(i)) == normalized_input:
			_select_item(i)
			print("Enter pressed, exact match selected:", item_list.get_item_text(i))
			return
			
	print("Enter pressed, nothing selected")
			
	# Select item and update UI
func _select_item(index: int) -> void:
	
	var selected_move_name = item_list.get_item_text(index)
	
	# Show selection briefly before clearing
	search_bar.text = selected_move_name
	
	# Hide dropdown
	item_list.visible = false
	search_bar.grab_focus()
	
	# Start timer to clear search bar shortly after selection
	clear_timer.start()
	
#Normalize the selected name for comparision
	var norm_selected = normalize(selected_move_name)
	
# Find resource with normalized comparison. 
	var move_resource: BalletMove = null
	
	# find it's resource from the database
	for balletmove in database.moves:
		if normalize(balletmove.name) == norm_selected:
			move_resource = balletmove
			break
			
	if move_resource == null:
		print("Resources not found for move:", selected_move_name)
		return
		
	# Update UI with the resources definition and name (keeps accents)
	definition_label.set_text(move_resource.definition)
	title_label.set_text(move_resource.name)
	
	# Play animation in SubViewport
	if dancer_viewport.get_child_count() > 0:
		var dancer_node = dancer_viewport.get_child(0)
		if dancer_node.has_method("play_move"):
			dancer_node.play_move(move_resource.name)
			print("Requested animation:", move_resource.animation_name)
		else:
			print("SubViewport child does not have 'play_move' method!")
	else:
		print("Subviewport is empty; cannot play animation")
	
	
# Timer callback to clear the search bar.
func _clear_search_now() -> void:
	search_bar.text = ""
	current_index = -1
	item_list.clear()
	item_list.visible = false
	
func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/title_page.tscn")


func _on_glossary_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/index.tscn")
