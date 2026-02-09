# ----------------------------
# fullscreen_manager.gd
# ----------------------------
extends Node

# ----------------------------
# Signals
# ----------------------------
signal fullscreen_started(dancer: Node3D)
signal fullscreen_exited

# ----------------------------
# State
# ----------------------------
var is_fullscreen: bool = false
var current_dancer: Node3D = null
var dancer_viewport: SubViewport = null
var video_controls_instance: Control = null
var video_controls_scene: PackedScene = preload("res://Scenes/video_controls.tscn")

# ----------------------------
# Assign dancer & viewport
# ----------------------------
func set_dancer(dancer: Node3D, viewport: SubViewport) -> void:
	current_dancer = dancer
	dancer_viewport = viewport
	print("[FullscreenManager] Dancer assigned:", current_dancer)

# ----------------------------
# Recursive UI hide/show for CanvasLayer children
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

# ----------------------------
# Launch fullscreen
# ----------------------------
func launch_fullscreen(main_scene_root: Node, dancer: Node3D) -> void:
	if is_fullscreen or not dancer:
		push_warning("[FullscreenManager] Cannot launch fullscreen")
		return

	# Assign dancer and SubViewport
	var subviewport = main_scene_root.get_node("FullscreenContainer/SubViewportContainer/SubViewport")
	set_dancer(dancer, subviewport)

	# Hide MainSceneUI (CanvasLayer included)
	var main_ui = main_scene_root.get_node("MainSceneUI")
	if main_ui:
		_hide_recursive(main_ui)

	# Instantiate video controls if needed
	if not video_controls_instance:
		video_controls_instance = video_controls_scene.instantiate()
		main_scene_root.add_child(video_controls_instance)
	video_controls_instance.visible = true

	# Set OS fullscreen
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

	# Update state & emit signal
	is_fullscreen = true
	emit_signal("fullscreen_started", current_dancer)
	print("[FullscreenManager] Fullscreen started for:", current_dancer)

# ----------------------------
# Exit fullscreen
# ----------------------------
func exit_fullscreen(main_scene_root: Node) -> void:
	if not is_fullscreen:
		return

	# Show MainSceneUI (CanvasLayer included)
	var main_ui = main_scene_root.get_node("MainSceneUI")
	if main_ui:
		_show_recursive(main_ui)

	# Hide video controls
	if video_controls_instance:
		video_controls_instance.visible = false

	# Exit OS fullscreen
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

	# Reset state
	current_dancer = null
	is_fullscreen = false
	emit_signal("fullscreen_exited")
	print("[FullscreenManager] Fullscreen exited")
