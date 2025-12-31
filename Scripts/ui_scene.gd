extends Control

# ----------------------------
# UI Nodes
# ----------------------------
@onready var search_bar: LineEdit = $CanvasLayer/Search/MarginContainerText/VBoxContainer/LineEdit
@onready var item_list = $CanvasLayer/Search/MarginContainerText/VBoxContainer/ItemList
@onready var definition_label: RichTextLabel = $CanvasLayer/Definitions/MarginContainerTextMain/VBoxContainer/MarginContainerText/DefinitionLabel
@onready var title_label: RichTextLabel = $CanvasLayer/Definitions/MarginContainerTextMain/VBoxContainer/MarginContainerTitle/TitleLabel
@onready var dancer_viewport: SubViewport = $"../SubViewportContainer/DancerViewport"
@onready var sub_viewport_container: SubViewportContainer = $"../SubViewportContainer"
@onready var video_controls_scene: PackedScene = preload("res://Scenes/video_controls.tscn")

# ----------------------------
# Resources
# ----------------------------
@export var database: BalletMoveDatabase
@export var skeleton_scene: PackedScene
var current_index := -1
var clear_timer: Timer
var current_dancer: Node = null
var pending_animation: String = ""

# Fullscreen management
var video_controls_instance: Control = null
var is_fullscreen: bool = false
var saved: bool = false
var prev_anchor: Rect2 = Rect2()
var prev_position: Vector2 = Vector2.ZERO
var prev_size: Vector2 = Vector2.ZERO

# ----------------------------
# Ready
# ----------------------------
func _ready() -> void:
	print("UI ready")
	if not database:
		database = load("res://Definition Resources/ballet_moves_database.tres")
		print("Database loaded")

	search_bar.text_changed.connect(_on_search_text_changed)
	search_bar.gui_input.connect(_on_search_bar_gui_input)
	search_bar.connect("text_submitted", Callable(self, "_on_search_bar_entered"))
	item_list.item_selected.connect(_on_item_selected)
	item_list.visible = false

	clear_timer = Timer.new()
	clear_timer.one_shot = true
	clear_timer.wait_time = 0.8
	clear_timer.connect("timeout", Callable(self, "_clear_search_now"))
	add_child(clear_timer)

	print("Connecting previous GameManager selections")
	if GameManager.chosen_character != "":
		_on_character_button_pressed(GameManager.chosen_character)
	if GameManager.selected_term != "":
		_select_term(GameManager.selected_term)
		GameManager.selected_term = ""

	prev_size = DisplayServer.window_get_size()
	prev_position = DisplayServer.window_get_position()
	print("Initial window size:", prev_size, "position:", prev_position)

# ----------------------------
# Global Input Handling
# ----------------------------
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F1:
			# Only toggle fullscreen if not already fullscreen
			if not is_fullscreen:
				print("F1 pressed, toggling fullscreen")
				toggle_viewport_fullscreen()
				
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R and is_fullscreen:
			if current_dancer and current_dancer.has_method("play_move") and GameManager.last_played_animation != "":
				print("R pressed — replaying last animation:", GameManager.last_played_animation)
				current_dancer.call_deferred("play_move", GameManager.last_played_animation)


	
# ----------------------------
# Character Selection
# ----------------------------
func _on_character_button_pressed(character_scene_path: String) -> void:
	print("Character button pressed:", character_scene_path)
	GameManager.chosen_character = character_scene_path

	if current_dancer and current_dancer.is_inside_tree():
		current_dancer.queue_free()
		current_dancer = null

	var char_scene: PackedScene = load(character_scene_path)
	if not char_scene:
		push_error("Character scene not found!: " + character_scene_path)
		return

	current_dancer = char_scene.instantiate()
	dancer_viewport.add_child(current_dancer)
	print("Current dancer loaded:", current_dancer.name)

	var animation_player: AnimationPlayer = current_dancer.get_node_or_null("AnimationPlayer")
	if animation_player:
		print("Animations available:", animation_player.get_animation_list())

	if pending_animation != "":
		current_dancer.call_deferred("play_move", pending_animation)
		print("Playing pending animation:", pending_animation)
		pending_animation = ""

func _on_male_button_pressed() -> void:
	_on_character_button_pressed("res://Scenes/male.tscn")

func _on_female_button_pressed() -> void:
	_on_character_button_pressed("res://Scenes/female.tscn")

# ----------------------------
# Term Selection
# ----------------------------
func _select_term(term_name: String) -> void:
	print("Selecting term:", term_name)
	var norm_term_name = normalize(term_name)
	var move_resource: BalletMove = null

	for move in database.moves:
		if normalize(move.name) == norm_term_name:
			move_resource = move
			break

	if move_resource == null:
		print("Term not found in database:", term_name)
		return

	definition_label.set_text(move_resource.definition)
	title_label.set_text(move_resource.name)
	search_bar.text = move_resource.name
	item_list.visible = false

	var animation_name = move_resource.animation_name.strip_edges()
	print("Requested animation:", animation_name)

	if current_dancer and current_dancer.has_method("play_move") and animation_name != "":
		current_dancer.call_deferred("play_move", animation_name)
		GameManager.last_played_animation = animation_name # <--- TRACK LAST ANIMATION
		print("Animation played (deferred):", animation_name)
	else:
		print("No dancer yet, queuing animation:", animation_name)
		pending_animation = animation_name


func _select_item(index: int) -> void:
	var selected_move_name = item_list.get_item_text(index)
	print("Selecting item from list:", selected_move_name)
	var move_resource: BalletMove = null
	var norm_selected = normalize(selected_move_name)

	for balletmove in database.moves:
		if normalize(balletmove.name) == norm_selected:
			move_resource = balletmove
			break

	if move_resource == null:
		print("Resources not found for move:", selected_move_name)
		return

	definition_label.set_text(move_resource.definition)
	title_label.set_text(move_resource.name)
	search_bar.text = selected_move_name
	item_list.visible = false
	search_bar.grab_focus()
	clear_timer.start()

	var animation_name = move_resource.animation_name.strip_edges()
	if current_dancer and current_dancer.has_method("play_move") and animation_name != "":
		current_dancer.call_deferred("play_move", animation_name)
		GameManager.last_played_animation = animation_name # <--- TRACK LAST ANIMATION
		print("Animation played (deferred):", animation_name)
	else:
		print("No dancer loaded or 'play_move' missing or animation empty")
		pending_animation = animation_name


# ----------------------------
# Search Bar / List
# ----------------------------
func _on_search_text_changed(new_text: String) -> void:
	print("Search text changed:", new_text)
	item_list.clear()
	current_index = -1

	if new_text == "":
		item_list.visible = false
		return

	var normalized_input = normalize(new_text)
	for balletmove in database.moves:
		if normalize(balletmove.name).begins_with(normalized_input):
			item_list.add_item(balletmove.name)

	item_list.visible = item_list.get_item_count() > 0

func _on_item_selected(index: int) -> void:
	current_index = index
	print("Item selected:", index)
	_select_item(index)

func _on_search_bar_gui_input(event: InputEvent) -> void:
	if not item_list.visible:
		return

	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_DOWN:
				if current_index < item_list.get_item_count() - 1:
					current_index += 1
					item_list.select(current_index)
					item_list.ensure_current_is_visible()
					print("Arrow down, selected index:", current_index)
			KEY_UP:
				if current_index > 0:
					current_index -= 1
					item_list.select(current_index)
					item_list.ensure_current_is_visible()
					print("Arrow up, selected index:", current_index)
			KEY_ENTER, KEY_KP_ENTER:
				if current_index >= 0 and current_index < item_list.get_item_count():
					_select_item(current_index)
					print("Enter pressed, selected:", item_list.get_item_text(current_index))
					return

func _on_search_bar_entered(new_text: String) -> void:
	print("Search bar entered:", new_text)
	if current_index >= 0 and current_index < item_list.get_item_count():
		_select_item(current_index)
		return

	var normalized_input = normalize(new_text)
	for i in range(item_list.get_item_count()):
		if normalize(item_list.get_item_text(i)) == normalized_input:
			_select_item(i)
			return
	print("Enter pressed, nothing selected")

func _clear_search_now() -> void:
	print("Clearing search bar")
	search_bar.text = ""
	current_index = -1
	item_list.clear()
	item_list.visible = false

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

# ----------------------------
# Fullscreen / Video Controls
# ----------------------------
func toggle_viewport_fullscreen() -> void:
	print("Toggling fullscreen, currently:", is_fullscreen)
	if not is_fullscreen:
		# Hide all UI layers except the viewport
		for child in get_children():
			if child is CanvasLayer:
				child.visible = false
				print("Hiding CanvasLayer:", child.name)

		# Save position & size
		prev_position = sub_viewport_container.position
		prev_size = sub_viewport_container.size
		print("Saved viewport size:", prev_size, "position:", prev_position)

		# Stretch viewport to fill window
		sub_viewport_container.position = Vector2.ZERO
		sub_viewport_container.size = DisplayServer.window_get_size()
		dancer_viewport.size = sub_viewport_container.size
		print("Viewport resized to:", sub_viewport_container.size)

		# Ensure CanvasLayer for video controls exists
		var canvas_layer := get_tree().current_scene.get_node_or_null("CanvasLayerVideoControls")
		if canvas_layer == null:
			canvas_layer = CanvasLayer.new()
			canvas_layer.name = "CanvasLayerVideoControls"
			get_tree().current_scene.add_child(canvas_layer)
			print("Created new CanvasLayerVideoControls")

		# Instantiate video controls if not already
		if video_controls_instance and video_controls_instance.is_inside_tree():
			video_controls_instance.free()
			print("Removed old video controls instance")

		video_controls_instance = video_controls_scene.instantiate()
		canvas_layer.add_child(video_controls_instance)
		video_controls_instance.owner = get_tree().current_scene
		print("Instantiated video controls:", video_controls_instance.name)

		# Stretch controls using new method
		if video_controls_instance.has_method("stretch_to_fullscreen"):
			video_controls_instance.stretch_to_fullscreen()
			print("Video controls stretched to fullscreen")

		call_deferred("_assign_video_controls_nodes")
		is_fullscreen = true
	else:
		print("Exiting fullscreen")
		# Restore UI layers
		for child in get_children():
			if child is CanvasLayer:
				child.visible = true
				print("Restoring CanvasLayer:", child.name)

		# Restore viewport size & position
		sub_viewport_container.position = prev_position
		sub_viewport_container.size = prev_size
		dancer_viewport.size = prev_size
		print("Restored viewport size:", prev_size, "position:", prev_position)

		# Remove video controls
		if video_controls_instance and video_controls_instance.is_inside_tree():
			video_controls_instance.free()
			print("Freed video controls instance")
			video_controls_instance = null

		is_fullscreen = false
		get_viewport().gui_release_focus()


func _assign_video_controls_nodes() -> void:
	if not video_controls_instance:
		push_error("Video controls instance not found!")
		return

	print("Assigning video control nodes...")
	var background_node = dancer_viewport.get_node_or_null("Background")
	if not background_node:
		push_error("Background node not found!")
		return

	var camera_node = background_node.get_node_or_null("Camera3D")
	if not camera_node:
		push_error("Camera node not found!")
		return

	# Assign camera and dancer
	video_controls_instance.set_camera(camera_node)
	video_controls_instance.set_active_dancer(current_dancer)
	print("Video controls assigned camera and dancer")
	
# ----------------------------
# Button Connections
# ----------------------------

func _on_index_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/index.tscn")

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/title_page.tscn")
	
