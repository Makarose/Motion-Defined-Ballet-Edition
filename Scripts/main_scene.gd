# ----------------------------
# main_scene.gd
# ----------------------------

extends Node2D

# ----------------------------
# Scene Nodes
# ----------------------------
@onready var main_scene_ui: Control = $MainSceneUI
@onready var sub_viewport_container: SubViewportContainer = $SubViewportContainer
@onready var dancer_viewport: SubViewport = $SubViewportContainer/DancerViewport
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

	# Connect fullscreen manager signals and assign references
	fs_manager.connect("fullscreen_started", Callable(self, "_on_fullscreen_started"))
	fs_manager.connect("fullscreen_exited", Callable(self, "_on_fullscreen_exited"))
	fs_manager.assign_fullscreen_container(main_scene_ui.get_node("CanvasLayer/Fullscreen"))
	fs_manager.assign_dancer_viewport(dancer_viewport)
	fs_manager.assign_video_controls(video_controls_instance)

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

	# Assign dancer to VideoControls
	if video_controls_instance and video_controls_instance.is_inside_tree():
		video_controls_instance.set_active_dancer(current_dancer, not is_fullscreen)
		_assign_video_controls_nodes()

	# Forward references to FullscreenManager
	if fs_manager:
		fs_manager.assign_current_dancer(current_dancer)
		fs_manager.assign_video_controls(video_controls_instance)
		fs_manager.assign_dancer_viewport(dancer_viewport)

	call_deferred("_try_play_pending_term")

# ----------------------------
# Fullscreen button handler
# ----------------------------
func _on_fullscreen_button_pressed() -> void:
	if current_dancer and fs_manager:
		fs_manager.launch_fullscreen(current_dancer)
	else:
		push_warning("Cannot launch fullscreen: no dancer selected")
			
# ----------------------------
# Fullscreen signal handlers
# ----------------------------			
func _on_fullscreen_started() -> void:
	print("[MainScene] Fullscreen started")
	is_fullscreen = true
	# Hide MainScene UI when fullscreen is active
	if main_scene_ui:
		_hide_recursive(main_scene_ui)

func _on_fullscreen_exited() -> void:
	print("[MainScene] Fullscreen exited")
	is_fullscreen = false
	# Restore MainScene UI
	if main_scene_ui:
		_show_recursive(main_scene_ui)

func _unhandled_input(event: InputEvent) -> void:
	if fs_manager:
		fs_manager.handle_input(event)

# ----------------------------
# Helpers
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
		
func _hide_recursive(node: Node) -> void:
	if node is CanvasItem:
		# Skip fullscreen container so it remains visible
		if node != main_scene_ui.get_node("CanvasLayer/Fullscreen"):
			node.visible = false
	for child in node.get_children():
		_hide_recursive(child)

func _show_recursive(node: Node) -> void:
	if node is CanvasItem:
		# Skip fullscreen container; it's controlled separately
		if node != main_scene_ui.get_node("CanvasLayer/Fullscreen"):
			node.visible = true
	for child in node.get_children():
		_show_recursive(child)
