# ----------------------------
# main_scene.gd
# ----------------------------

extends Node2D

# ----------------------------
# Scene Nodes
# ----------------------------
@onready var main_scene_ui: Control = $MainSceneUI
@onready var sub_viewport_container: SubViewportContainer = $SubViewportContainer
@onready var dancer_viewport: SubViewport = $FullscreenContainer/SubViewportContainer/DancerViewport
@onready var video_controls_scene: PackedScene = preload("res://Scenes/video_controls.tscn")
@onready var fs_manager := get_node("/root/FullscreenManager")  # Fullscreen manager reference

# ----------------------------
# Runtime state
# ----------------------------
var current_dancer: Node3D = null
var video_controls_instance: Control = null
var is_fullscreen: bool = false
var prev_position: Vector2 = Vector2.ZERO
var prev_size: Vector2 = Vector2.ZERO
var pending_term: String = ""

# ----------------------------
# Ready
# ----------------------------
func _ready() -> void:
	print("[DEBUG] MainScene ready")

	# Connect GameManager navigation
	GameManager.nav_left.connect(Callable(self, "_on_nav_left"))
	GameManager.nav_right.connect(Callable(self, "_on_nav_right"))

	# Connect UI signals
	if main_scene_ui:
		main_scene_ui.connect("term_selected", Callable(self, "_on_term_selected"))
		main_scene_ui.connect("character_requested", Callable(self, "_on_character_selected"))
		main_scene_ui.connect("fullscreen_requested", Callable(self, "_on_fullscreen_button_pressed"))

	# Connect fullscreen manager signals
	fs_manager.connect("fullscreen_started", Callable(self, "_on_fullscreen_started"))
	fs_manager.connect("fullscreen_exited", Callable(self, "_on_fullscreen_exited"))

	# Spawn last selected character from GameManager
	if GameManager.chosen_character != "":
		print("[DEBUG] Spawning last selected character:", GameManager.chosen_character)
		_on_character_selected(GameManager.chosen_character, true)

	call_deferred("_try_play_pending_term")

# ----------------------------
# Character spawning
# ----------------------------
func _on_character_selected(character_scene_path: String, is_restore: bool = false) -> void:
	# Remove old dancer
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

	# Assign dancer to VideoControls if already present
	if video_controls_instance and video_controls_instance.is_inside_tree():
		video_controls_instance.set_active_dancer(current_dancer, not fs_manager.is_fullscreen)
		_assign_video_controls_nodes()

	# Assign dancer to FullscreenManager (2 args only)
	if fs_manager:
		fs_manager.set_dancer(current_dancer, dancer_viewport)

	# Try to play pending term if needed
	call_deferred("_try_play_pending_term")


# ----------------------------
# Term selection handler
# ----------------------------
func _on_term_selected(animation_name: String) -> void:
	print("[DEBUG] MainScene received term_selected:", animation_name)

	if current_dancer:
		# Play the selected animation
		current_dancer.play_animation(animation_name)

		# Show fullscreen button if it exists
		var fs_button = main_scene_ui.get_node_or_null("FullscreenButton")
		if fs_button:
			fs_button.visible = true
			# Assign dancer node to UI for fullscreen
			main_scene_ui.current_dancer_node = current_dancer
	else:
		# Store for later if dancer hasn't spawned yet
		pending_term = animation_name

# ----------------------------
# Fullscreen button handler
# ----------------------------
func _on_fullscreen_button_pressed() -> void:
	if not current_dancer:
		push_warning("Cannot launch fullscreen: no dancer selected")
		return

	if not fs_manager:
		push_warning("Cannot launch fullscreen: FullscreenManager not found")
		return

	if not is_fullscreen:
		print("[DEBUG] Launching fullscreen for dancer:", current_dancer)
		fs_manager.launch_fullscreen(self, current_dancer)
	else:
		print("[DEBUG] Fullscreen already active; exiting")
		fs_manager.exit_fullscreen(self)



# ----------------------------
# Fullscreen signal handlers
# ----------------------------
func _on_fullscreen_started(dancer: Node3D) -> void:
	print("[MainScene] Fullscreen started")
	is_fullscreen = true

func _on_fullscreen_exited() -> void:
	print("[MainScene] Fullscreen exited")
	is_fullscreen = false


# ----------------------------
# Unhandled input
# ----------------------------
func _unhandled_input(event: InputEvent) -> void:
	# Forward input to UI or handle fullscreen toggling here if needed
	pass

# ----------------------------
# Navigation handlers
# ----------------------------
func _on_nav_left() -> void:
	print("[DEBUG] _on_nav_left triggered")
	_on_back_button_pressed()  # just call back button logic

func _on_nav_right() -> void:
	print("[DEBUG] _on_nav_right triggered")
	_on_index_button_pressed()  # just call index button logic

# ----------------------------
# Actual scene navigation
# ----------------------------
func _on_back_button_pressed() -> void:
	print("[DEBUG] Back button triggered")
	GameManager.selected_term = ""
	GameManager.last_played_animation = ""
	get_tree().call_deferred(
		"change_scene_to_file",
		"res://Scenes/title_page.tscn"
	)

func _on_index_button_pressed() -> void:
	print("[DEBUG] Index button triggered")
	get_tree().call_deferred(
		"change_scene_to_file",
		"res://Scenes/index.tscn"
	)

# ----------------------------
# VideoControls helpers
# ----------------------------
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

# ----------------------------
# Helpers to hide/show UI
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
