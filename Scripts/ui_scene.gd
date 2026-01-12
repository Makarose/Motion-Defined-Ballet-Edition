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
@onready var fullscreen_controls_container: MarginContainer = $CanvasLayer/Fullscreen

# ----------------------------
# Resources
# ----------------------------
@export var database: BalletMoveDatabase
@export var skeleton_scene: PackedScene
var current_index := -1
var clear_timer: Timer
var current_dancer: Node = null
var active_dancer: Node3D = null

# Fullscreen management
var video_controls_instance: Control = null
var is_fullscreen: bool = false
var prev_position: Vector2 = Vector2.ZERO
var prev_size: Vector2 = Vector2.ZERO

# ----------------------------
# Runtime state
# ----------------------------
var dancer: Node3D
var skel: Skeleton3D
var has_selected_term: bool = false

var selected_character_scene_path: String = ""  # store last chosen character temporarily
var last_fullscreen_character_scene_path: String = ""  # store last selected character while in fullscreen
var last_main_scene_character_scene_path: String = ""  # main viewport dancer before fullscreen
var last_selected_character_scene_path: String = ""  # main viewport dancer selection

# ----------------------------
# Ready
# ----------------------------
func _ready() -> void:
	print("UI READY")

	has_selected_term = false
	_show_fullscreen_controls(false)

	var video_control = get_node_or_null("VideoControl")
	if video_control:
		var target_callable = Callable(self, "_on_character_button_pressed")
		if not video_control.is_connected("character_requested", target_callable):
			video_control.character_requested.connect(target_callable)
	else:
		push_warning("VideoControl node not found! Skipping initial connections.")

	if not database:
		database = load("res://Definition Resources/ballet_moves_database.tres")

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

	if GameManager.chosen_character != "":
		_on_character_button_pressed(GameManager.chosen_character)

	if GameManager.selected_term != "":
		call_deferred("_select_term", GameManager.selected_term)
		GameManager.selected_term = ""

# ----------------------------
# Global Input Handling
# ----------------------------
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F1:
				if has_selected_term:
					toggle_viewport_fullscreen()
			KEY_R:
				if is_fullscreen and current_dancer and current_dancer.has_method("play_move") and GameManager.last_played_animation != "":
					current_dancer.call_deferred("play_move", GameManager.last_played_animation)

# ----------------------------
# Character Selection
# ----------------------------
func _on_character_button_pressed(character_scene_path: String, is_restore: bool = false) -> void:
	print("[DEBUG] _on_character_button_pressed called with:", character_scene_path)

	if is_fullscreen and not is_restore:
		last_fullscreen_character_scene_path = character_scene_path

	if not is_restore:
		last_selected_character_scene_path = character_scene_path

	# Free previous dancer safely
	if current_dancer and current_dancer.is_inside_tree():
		current_dancer.queue_free()
		current_dancer = null
		print("[DEBUG] Freed previous dancer")

	# Instantiate new dancer
	var char_scene: PackedScene = load(character_scene_path)
	if not char_scene:
		push_error("Character scene not found!: " + character_scene_path)
		return

	var new_dancer = char_scene.instantiate()
	dancer_viewport.add_child(new_dancer)
	current_dancer = new_dancer
	print("[DEBUG] Instantiated new dancer:", current_dancer)

	# Bulletproof playback state handling
	if current_dancer.has_method("get_playback_state") and current_dancer.has_method("apply_playback_state"):
		var saved_state = current_dancer.get_playback_state()
		# Ensure AnimationPlayer exists
		if saved_state.has("animation") and saved_state.animation != "":
			current_dancer.call_deferred("apply_playback_state", saved_state)
			print("[DEBUG] Applied saved playback state")
		else:
			print("[DEBUG] No animation to apply, skipping playback state")

	# Safety: assign video controls
	_assign_video_controls_nodes()

# ----------------------------
# Term Selection
# ----------------------------
func _select_term(term_name: String) -> void:
	var norm_term_name = normalize(term_name)
	var move_resource: BalletMove = null

	for move in database.moves:
		if normalize(move.name) == norm_term_name:
			move_resource = move
			break

	if move_resource == null:
		return

	title_label.set_text(move_resource.name)
	definition_label.set_text(move_resource.definition)
	search_bar.text = move_resource.name
	item_list.visible = false

	has_selected_term = true
	_show_fullscreen_controls(true)

	var animation_name = move_resource.animation_name.strip_edges()
	if animation_name == "":
		DancerState.current_animation = ""
		DancerState.is_playing = false
		GameManager.last_played_animation = ""
		return

	DancerState.current_animation = animation_name
	DancerState.animation_time = 0.0
	DancerState.is_playing = true
	GameManager.last_played_animation = animation_name

	if current_dancer and current_dancer.has_method("play_move"):
		current_dancer.call_deferred("play_move", animation_name)

func _select_item(index: int) -> void:
	var selected_move_name = item_list.get_item_text(index)
	var move_resource: BalletMove = null
	var norm_selected = normalize(selected_move_name)

	for balletmove in database.moves:
		if normalize(balletmove.name) == norm_selected:
			move_resource = balletmove
			break

	if move_resource == null:
		return

	title_label.set_text(move_resource.name)
	definition_label.set_text(move_resource.definition)
	search_bar.text = selected_move_name
	item_list.visible = false
	search_bar.grab_focus()
	clear_timer.start()

	has_selected_term = true
	_show_fullscreen_controls(true)

	var animation_name = move_resource.animation_name.strip_edges()
	if animation_name == "":
		DancerState.current_animation = ""
		DancerState.is_playing = false
		GameManager.last_played_animation = ""
		return

	if DancerState.current_animation != animation_name:
		DancerState.current_animation = animation_name
		DancerState.animation_time = 0.0
		DancerState.is_playing = true
		GameManager.last_played_animation = animation_name
		if current_dancer and current_dancer.has_method("play_move"):
			current_dancer.call_deferred("play_move", animation_name)

# ----------------------------
# Search Bar / List
# ----------------------------
func _on_search_text_changed(new_text: String) -> void:
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
			KEY_UP:
				if current_index > 0:
					current_index -= 1
					item_list.select(current_index)
					item_list.ensure_current_is_visible()
			KEY_ENTER, KEY_KP_ENTER:
				if current_index >= 0 and current_index < item_list.get_item_count():
					_select_item(current_index)

func _on_search_bar_entered(new_text: String) -> void:
	if current_index >= 0 and current_index < item_list.get_item_count():
		_select_item(current_index)
		return

	var normalized_input = normalize(new_text)
	for i in range(item_list.get_item_count()):
		if normalize(item_list.get_item_text(i)) == normalized_input:
			_select_item(i)
			return

func _clear_search_now() -> void:
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
func _show_fullscreen_controls(visible: bool) -> void:
	if fullscreen_controls_container and fullscreen_controls_container.is_inside_tree():
		fullscreen_controls_container.visible = visible

func toggle_viewport_fullscreen() -> void:
	if not is_fullscreen:
		print("[DEBUG] --- Entering fullscreen ---")

		for child in get_children():
			if child is CanvasLayer and child.name != "CanvasLayerVideoControls":
				child.visible = false

		last_main_scene_character_scene_path = last_selected_character_scene_path
		print("[DEBUG] Stored main scene dancer before fullscreen:", last_main_scene_character_scene_path)

		prev_position = sub_viewport_container.position
		prev_size = sub_viewport_container.size

		sub_viewport_container.position = Vector2.ZERO
		sub_viewport_container.size = DisplayServer.window_get_size()
		dancer_viewport.size = sub_viewport_container.size

		var canvas_layer := get_tree().current_scene.get_node_or_null("CanvasLayerVideoControls")
		if canvas_layer == null:
			canvas_layer = CanvasLayer.new()
			canvas_layer.name = "CanvasLayerVideoControls"
			get_tree().current_scene.add_child(canvas_layer)

		if video_controls_instance and video_controls_instance.is_inside_tree():
			video_controls_instance.free()

		video_controls_instance = video_controls_scene.instantiate()
		canvas_layer.add_child(video_controls_instance)
		video_controls_instance.owner = get_tree().current_scene

		_assign_video_controls_nodes()
		is_fullscreen = true

	else:
		print("[DEBUG] --- Exiting fullscreen ---")

		for child in get_children():
			if child is CanvasLayer:
				child.visible = true

		sub_viewport_container.position = prev_position
		sub_viewport_container.size = prev_size
		dancer_viewport.size = prev_size

		if video_controls_instance and video_controls_instance.is_inside_tree():
			video_controls_instance.free()
			video_controls_instance = null

		is_fullscreen = false
		get_viewport().gui_release_focus()

		var restore_scene_path = last_fullscreen_character_scene_path
		if restore_scene_path == "":
			restore_scene_path = last_main_scene_character_scene_path

		if restore_scene_path != "":
			print("[DEBUG] Restoring main dancer to:", restore_scene_path)
			call_deferred("_on_character_button_pressed", restore_scene_path, true)

		last_fullscreen_character_scene_path = ""

# ----------------------------
# Video Control Helper
# ----------------------------
func _assign_video_controls_nodes() -> void:
	if not video_controls_instance or not video_controls_instance.is_inside_tree():
		return
	if not dancer_viewport or not dancer_viewport.is_inside_tree():
		return

	var background_node = dancer_viewport.get_node_or_null("Background")
	if not background_node:
		push_warning("Background node not found in dancer_viewport.")
		return

	var camera_node = background_node.get_node_or_null("Camera3D")
	if not camera_node:
		push_warning("Camera3D node not found under Background.")
		return

	if video_controls_instance.has_method("set_camera"):
		video_controls_instance.set_camera(camera_node)

	if current_dancer and current_dancer.is_inside_tree() and video_controls_instance.has_method("set_active_dancer"):
		video_controls_instance.set_active_dancer(current_dancer)
		print("[DEBUG] Video controls assigned active dancer:", current_dancer)
	else:
		print("[DEBUG] No active dancer to assign or method missing in video controls.")

# ----------------------------
# Button Connections
# ----------------------------
func _on_index_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/index.tscn")

func _on_back_button_pressed() -> void:
	GameManager.selected_term = ""
	GameManager.last_played_animation = ""
	get_tree().change_scene_to_file("res://Scenes/title_page.tscn")

func _on_fullscreen_button_pressed() -> void:
	if has_selected_term:
		toggle_viewport_fullscreen()
