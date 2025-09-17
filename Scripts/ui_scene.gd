extends Control

@onready var search_bar: LineEdit = $CanvasLayer/Search/MarginContainerText/VBoxContainer/LineEdit
@onready var item_list = $CanvasLayer/Search/MarginContainerText/VBoxContainer/ItemList
@onready var definition_label: RichTextLabel = $CanvasLayer/Definitions/MarginContainerTextMain/VBoxContainer/MarginContainerText/DefinitionLabel
@onready var title_label: RichTextLabel = $CanvasLayer/Definitions/MarginContainerTextMain/VBoxContainer/MarginContainerTitle/TitleLabel
@onready var dancer_viewport: SubViewport = $"../DancerViewport"


#----------------------------------
# Resources
#----------------------------------
@export var database: BalletMoveDatabase
@export var skeleton_scene: PackedScene
var current_index := -1 # Tracks which suggestion is highlighted.
var clear_timer: Timer
var current_dancer: Node = null


#----------------------------------
# Setup
#----------------------------------
func _ready() -> void:
	# Load the database
	if not database:
		database = load("res://Definition Resources/ballet_moves_database.tres")
	print("Database loaded:", database)
	print("Moves:", database.moves)

	# Load chosen character automatically
	if GameManager.chosen_character != "":
		print("Spawning dancer:", GameManager.chosen_character)
		_on_character_button_pressed(GameManager.chosen_character)
		GameManager.chosen_character = ""  # reset so it doesn’t double-spawn
	else:
		print("No character chosen yet")

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


#----------------------------------------
# Character Selection (from buttons)
# ---------------------------------------
func _on_character_button_pressed(character_scene_path: String) -> void:
	# Remove previous dancer
	if current_dancer and current_dancer.is_inside_tree():
		current_dancer.queue_free()
		current_dancer = null

	# Instance skeleton scene (master skeleton with animations)
	var skeleton_scene_instance: PackedScene = load("res://Scenes/skeleton.tscn")
	current_dancer = skeleton_scene_instance.instantiate()
	dancer_viewport.add_child(current_dancer)
	print("Current dancer created:", current_dancer)

	# Find Skeleton3D node in the master scene
	var skeleton_node: Skeleton3D = current_dancer.get_node_or_null("Skeleton3D")
	if not skeleton_node:
		push_warning("Skeleton3D not found in skeleton scene!")
		return

	# Instance character mesh scene (male, female, clothes, etc.)
	var mesh_scene: PackedScene = load(character_scene_path)
	var mesh_root = mesh_scene.instantiate()
	dancer_viewport.add_child(mesh_root)

	# Find the MeshInstance3D recursively
	var mesh_instance: MeshInstance3D = _find_mesh_instance(mesh_root)
	if not mesh_instance:
		push_warning("MeshInstance3D not found in mesh scene!")
		mesh_root.queue_free()
		return

	# Reset mesh transform
	mesh_instance.transform = Transform3D()

	# Bind the Skin resource to the master skeleton
	if mesh_instance.skin:
		mesh_instance.skin.skeleton = skeleton_node
		print("Mesh skin bound to skeleton:", mesh_instance)
	else:
		push_warning("Mesh has no Skin assigned: " + str(mesh_instance))

	# Debug: print AnimationPlayer animations
	var anim_player: AnimationPlayer = current_dancer.get_node_or_null("AnimationPlayer")
	if anim_player:
		print("Animations available:", anim_player.get_animation_list())
	else:
		push_warning("AnimationPlayer not found in skeleton scene!")


# Helper function to recursively find the first MeshInstance3D under a node
func _find_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var result = _find_mesh_instance(child)
		if result:
			return result
	return null


# -----------------------------
# Connect buttons
# -----------------------------
func _on_male_button_pressed() -> void:
	_on_character_button_pressed("res://Scenes/male.tscn")

func _on_female_button_pressed() -> void:
	_on_character_button_pressed("res://Scenes/female.tscn")	


# _____________________________________
# Animation Selection
# _____________________________________
func _select_item(index: int) -> void:
	var selected_move_name = item_list.get_item_text(index)
	print("Selecting move:", selected_move_name)
	
	if current_dancer:
		print("Current dancer exists:", current_dancer)
		print("Has method 'play_move':", current_dancer.has_method("play_move"))
	else:
		print("No dancer loaded")
	# Show selection briefly before clearing
	search_bar.text = selected_move_name
	
	# Hide dropdown
	item_list.visible = false
	search_bar.grab_focus()
	
	# Start timer to clear search bar shortly after selection
	clear_timer.start()
	
# Normalize the selected name for comparision
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
	
	# Play animation on current dancer
	if current_dancer and current_dancer.has_method("play_move"):
		current_dancer.play_move(move_resource.name)
		print("Requested animation:", move_resource.animation_name)
	else:
		print("No dancer loaded or 'play_move' missing")


#______________________________________
# Search Bar / List
# _____________________________________
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
	
	# Timer callback to clear the search bar.
func _clear_search_now() -> void:
	search_bar.text = ""
	current_index = -1
	item_list.clear()
	item_list.visible = false
	
	
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


# ------------------------------------------
# Scene Navigation
# -----------------------------------------
func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/title_page.tscn")

func _on_index_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/index.tscn")
