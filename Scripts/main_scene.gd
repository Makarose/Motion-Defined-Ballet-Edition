# ----------------------------
# main_scene.gd
# ----------------------------

extends Node2D

# ----------------------------
# Scene Nodes
# ----------------------------
@onready var ui: Control = $UI
@onready var sub_viewport_container: SubViewportContainer = $SubViewportContainer
@onready var dancer_viewport: SubViewport = $SubViewportContainer/DancerViewport
@onready var video_controls_scene: PackedScene = preload("res://Scenes/video_controls.tscn")

# ----------------------------
# Runtime state
# ----------------------------
var current_dancer: Node3D = null
var video_controls_instance: Control = null
var is_fullscreen: bool = false
var prev_position: Vector2 = Vector2.ZERO
var prev_size: Vector2 = Vector2.ZERO
var last_fullscreen_character_scene_path: String = ""
var last_main_scene_character_scene_path: String = ""
var last_selected_character_scene_path: String = ""

# ----------------------------
# Ready
# ----------------------------
func _ready() -> void:
	print("[DEBUG] MainScene ready")

	# Connect GameManager navigation
	GameManager.nav_left.connect(Callable(self, "_on_nav_left"))
	GameManager.nav_right.connect(Callable(self, "_on_nav_right"))

	# Connect UI signals
	if ui:
		ui.connect("term_selected", Callable(self, "_on_term_selected"))
		ui.connect("character_requested", Callable(self, "_on_character_selected"))
		ui.connect("fullscreen_requested", Callable(self, "_on_fullscreen_button_pressed"))

	# Spawn chosen character from GameManager
	if GameManager.chosen_character != "":
		print("[DEBUG] Spawning chosen character:", GameManager.chosen_character)
		_on_character_selected(GameManager.chosen_character)

# ----------------------------
# Navigation handlers
# ----------------------------
func _on_nav_left() -> void:
	print("[DEBUG] LEFT pressed")
	if not is_fullscreen:
		_on_back_button_pressed()

func _on_nav_right() -> void:
	print("[DEBUG] RIGHT pressed")
	if not is_fullscreen:
		_on_home_button_pressed()

# ----------------------------
# Character spawning
# ----------------------------
func _on_character_selected(character_scene_path: String, is_restore: bool = false) -> void:
	print("[DEBUG] Character selected:", character_scene_path, "is_restore:", is_restore)

	if is_fullscreen and not is_restore:
		last_fullscreen_character_scene_path = character_scene_path
	if not is_restore:
		last_selected_character_scene_path = character_scene_path

	# Remove previous dancer
	if current_dancer and current_dancer.is_inside_tree():
		current_dancer.queue_free()
		current_dancer = null

	# Instantiate new dancer
	var char_scene: PackedScene = load(character_scene_path)
	if not char_scene:
		push_error("Character scene not found!: " + character_scene_path)
		return

	current_dancer = char_scene.instantiate()
	dancer_viewport.add_child(current_dancer)

	call_deferred("_assign_video_controls_nodes")
	call_deferred("_try_play_pending_term")

# ----------------------------
# Term selection
# ----------------------------
func _on_term_selected(animation_name: String) -> void:
	print("[DEBUG] Term selected:", animation_name)
	if not current_dancer or not current_dancer.has_method("play_animation"):
		print("[DEBUG] No dancer or missing play_animation")
		return
	current_dancer.call_deferred("play_animation", animation_name)
	GameManager.last_played_animation = animation_name
	_on_playback_started()

func _on_playback_started() -> void:
	print("[DEBUG] Playback started")
	if ui and ui.has_method("show_fullscreen_button"):
		ui.call_deferred("show_fullscreen_button")

# ----------------------------
# Fullscreen toggle
# ----------------------------
func _on_fullscreen_button_pressed() -> void:
	print("[DEBUG] Fullscreen requested")
	toggle_viewport_fullscreen()

func toggle_viewport_fullscreen() -> void:
	if not is_fullscreen:
		_enter_fullscreen()
	else:
		_exit_fullscreen()

func _enter_fullscreen() -> void:
	print("[DEBUG] Entering fullscreen")
	if ui:
		_hide_recursive(ui)

	# Hide other CanvasLayers except video controls
	for child in get_children():
		if child is CanvasLayer and child.name != "CanvasLayerVideoControls":
			child.visible = false

	last_main_scene_character_scene_path = last_selected_character_scene_path

	prev_position = sub_viewport_container.position
	prev_size = sub_viewport_container.size
	sub_viewport_container.position = Vector2.ZERO
	sub_viewport_container.size = DisplayServer.window_get_size()
	dancer_viewport.size = sub_viewport_container.size

	# Video controls
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
	canvas_layer.layer = 100

	# Connect signals
	if video_controls_instance.has_signal("character_requested"):
		var target = Callable(self, "_on_character_selected")
		if not video_controls_instance.is_connected("character_requested", target):
			video_controls_instance.character_requested.connect(target)

	_assign_video_controls_nodes()
	is_fullscreen = true

func _exit_fullscreen() -> void:
	print("[DEBUG] Exiting fullscreen")
	if ui:
		_show_recursive(ui)

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
		call_deferred("_on_character_selected", restore_scene_path, true)

	last_fullscreen_character_scene_path = ""

# ----------------------------
# Helpers
# ----------------------------
func _hide_recursive(node: Node) -> void:
	if node is CanvasItem:
		node.visible = false
	for child in node.get_children():
		_hide_recursive(child)

func _show_recursive(node: Node) -> void:
	if node is CanvasItem:
		node.visible = true
	for child in node.get_children():
		_show_recursive(child)

func _assign_video_controls_nodes() -> void:
	if not video_controls_instance or not video_controls_instance.is_inside_tree():
		return
	if not dancer_viewport or not dancer_viewport.is_inside_tree():
		return

	var background_node = dancer_viewport.get_node_or_null("Background")
	if not background_node:
		push_warning("Background node not found")
		return

	var camera_node = background_node.get_node_or_null("Camera3D")
	if not camera_node:
		push_warning("Camera3D node not found under Background")
		return

	if video_controls_instance.has_method("set_camera"):
		video_controls_instance.set_camera(camera_node)

	if current_dancer and current_dancer.is_inside_tree() and video_controls_instance.has_method("set_active_dancer"):
		video_controls_instance.set_active_dancer(current_dancer)

func _try_play_pending_term() -> void:
	if GameManager.selected_term == "" or not current_dancer or not current_dancer.has_method("play_animation"):
		return
	_on_term_selected(GameManager.selected_term)
	GameManager.selected_term = ""

# ----------------------------
# Back/Home helpers
# ----------------------------
func _on_back_button_pressed() -> void:
	GameManager.selected_term = ""
	GameManager.last_played_animation = ""
	get_tree().change_scene_to_file("res://Scenes/title_page.tscn")

func _on_home_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/index.tscn")
