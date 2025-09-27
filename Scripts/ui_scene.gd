extends Control

@onready var search_bar: LineEdit = $CanvasLayer/Search/MarginContainerText/VBoxContainer/LineEdit
@onready var item_list = $CanvasLayer/Search/MarginContainerText/VBoxContainer/ItemList
@onready var definition_label: RichTextLabel = $CanvasLayer/Definitions/MarginContainerTextMain/VBoxContainer/MarginContainerText/DefinitionLabel
@onready var title_label: RichTextLabel = $CanvasLayer/Definitions/MarginContainerTextMain/VBoxContainer/MarginContainerTitle/TitleLabel
@onready var dancer_viewport: SubViewport = $"../SubViewportContainer/DancerViewport"
@onready var sub_viewport_container: SubViewportContainer = $"../SubViewportContainer"

#----------------------------------
# Resources
#----------------------------------
@export var database: BalletMoveDatabase
@export var skeleton_scene: PackedScene
var current_index := -1 # Tracks which suggestion is highlighted.
var clear_timer: Timer
var current_dancer: Node = null
var pending_animation: String = ""
var normal_size: Vector2
var normal_pos: Vector2
var is_fullscreen := false

#----------------------------------
# Setup
#----------------------------------
func _ready() -> void:
	# Load the database
	if not database:
		database = load("res://Definition Resources/ballet_moves_database.tres")
	
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
	
	# Spawn previous character if one selected
	if GameManager.chosen_character != "":
		_on_character_button_pressed(GameManager.chosen_character)
	else:
		print("No character chosen yet")
		
	# Queue term from index if exists
	if GameManager.selected_term != "":
		print("Queued term from index:", GameManager.selected_term)
		_select_term(GameManager.selected_term)
		GameManager.selected_term = ""

	# Store initial size and position of viewport
	normal_size = sub_viewport_container.size
	normal_pos = sub_viewport_container.position
	
	 # Save initial panel size/position
	normal_size = sub_viewport_container.size
	normal_pos = sub_viewport_container.position

	# Ensure viewport matches container initially
	_update_viewport_size()

	# Auto-update viewport when container is resized
	sub_viewport_container.resized.connect(Callable(self, "_update_viewport_size"))
	
func _update_viewport_size() -> void:
	dancer_viewport.size = sub_viewport_container.size
	dancer_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS


#----------------------------------------
# Character Selection (from buttons)
# ---------------------------------------
func _on_character_button_pressed(character_scene_path: String) -> void:
	# Save for later so character can be reloaded
	GameManager.chosen_character = character_scene_path
	
	# Remove previous dancer
	if current_dancer and current_dancer.is_inside_tree():
		current_dancer.queue_free()
		current_dancer = null

	# Load and instance the new character scene
	var char_scene: PackedScene = load(character_scene_path)
	if not char_scene:
		push_error("Character scene not found!: "+ character_scene_path)
		return
	
	current_dancer = char_scene.instantiate()
	dancer_viewport.add_child(current_dancer)
	print ("Current dancer loaded:", current_dancer.name)
	
	# Debug animation list if the character has an AnimationPlayer
	var animation_player: AnimationPlayer = current_dancer.get_node_or_null("AnimationPlayer")
	if animation_player:
		print("Animations available:", animation_player.get_animation_list())

	 # Play any pending animation queued from index or previous selection
	if pending_animation != "":
		print("▶ Queued animation detected:", pending_animation)
		# Ensure it runs after the node is fully added to the scene tree
		current_dancer.call_deferred("play_move", pending_animation)
		pending_animation = ""

# -----------------------------
# Connect buttons
# -----------------------------
func _on_male_button_pressed() -> void:
	_on_character_button_pressed("res://Scenes/male.tscn")

func _on_female_button_pressed() -> void:
	_on_character_button_pressed("res://Scenes/female.tscn")	


# _____________________________________
# Term Selection
# _____________________________________
func _select_term(term_name: String) -> void:
	# Normalize the incoming term
	var norm_term_name = normalize(term_name)
	
	# Find the move in the database using normalized comparison
	var move_resource: BalletMove = null
	for move in database.moves:
		if normalize(move.name) == norm_term_name:
			move_resource = move
			break
			
	if move_resource == null:
		print("Term not found in database:", term_name)
		return

	# Update UI
	definition_label.set_text(move_resource.definition)
	title_label.set_text(move_resource.name)
	search_bar.text = move_resource.name
	item_list.visible = false

	# Determine animation to play
	var animation_name = move_resource.animation_name.strip_edges()
	print("Requested animation:", animation_name)
	
	if current_dancer and current_dancer.has_method("play_move"):
		current_dancer.call_deferred("play_move", move_resource.animation_name.strip_edges())
	else:
		print("!!! No dancer yet, queuing animation:", animation_name)
		pending_animation = animation_name


func _select_item(index: int) -> void:
	var selected_move_name = item_list.get_item_text(index)
	print("Selecting move:", selected_move_name)
	
	#Find corresponding resource in database
	var move_resource: BalletMove = null
	
# Normalize the selected name for comparision
	var norm_selected = normalize(selected_move_name)
	
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
	
	
	# Show selection briefly before clearing
	search_bar.text = selected_move_name
	
	# Hide dropdown
	item_list.visible = false
	search_bar.grab_focus()
	
	# Start timer to clear search bar shortly after selection
	clear_timer.start()
	
	# Play animation on current dancer
	if current_dancer and current_dancer.has_method("play_move"):
		if move_resource.animation_name != "":
			print("About to play animation:", move_resource.animation_name)
			current_dancer.play_move(move_resource.animation_name)
			print("Requested animation:", move_resource.animation_name)
		else:
			print("Warning: move_resource has no animation_name set")
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


# -----------------------------------------
# Fullscreen / Viewport Resizing
# -----------------------------------------
func go_fullscreen():
	normal_size = sub_viewport_container.size
	normal_pos = sub_viewport_container.position
	sub_viewport_container.position = Vector2.ZERO
	sub_viewport_container.size = get_viewport().get_visible_rect().size
	is_fullscreen = true

func exit_fullscreen():
	sub_viewport_container.position = normal_pos
	sub_viewport_container.size = normal_size
	is_fullscreen = false

func toggle_fullscreen() -> void:
	if is_fullscreen:
		# Restore panel size/position
		sub_viewport_container.size = normal_size
		sub_viewport_container.position = normal_pos
	else:
		# Save current size/position
		normal_size = sub_viewport_container.size
		normal_pos = sub_viewport_container.position
		# Expand to fullscreen
		sub_viewport_container.size = get_viewport().get_visible_rect().size
		sub_viewport_container.position = Vector2.ZERO

	# Keep viewport in sync
	_update_viewport_size()
	is_fullscreen = !is_fullscreen

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F:
		toggle_fullscreen()


# ------------------------------------------
# Scene Navigation
# -----------------------------------------
func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/title_page.tscn")

func _on_index_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/index.tscn")
