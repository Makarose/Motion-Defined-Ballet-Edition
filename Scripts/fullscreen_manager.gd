# ----------------------------
# fullscreen_manager.gd
# ----------------------------
extends Node

signal fullscreen_started
signal fullscreen_exited

# ----------------------------
# References from MainScene
# ----------------------------
var fullscreen_container: Control = null      # MarginContainer in MainSceneUI
var dancer_viewport: SubViewport = null
var video_controls: Node = null
var current_dancer: Node3D = null

# ----------------------------
# Fullscreen state
# ----------------------------
var is_fullscreen: bool = false
var prev_viewport_size: Vector2 = Vector2.ZERO
var prev_viewport_position: Vector2 = Vector2.ZERO

# ----------------------------
# Assign references
# ----------------------------
func assign_fullscreen_container(container: Control) -> void:
	fullscreen_container = container

func assign_dancer_viewport(viewport: SubViewport) -> void:
	dancer_viewport = viewport

func assign_video_controls(vc: Node) -> void:
	video_controls = vc

func assign_current_dancer(dancer: Node3D) -> void:
	current_dancer = dancer

# ----------------------------
# Launch fullscreen
# ----------------------------
func launch_fullscreen(dancer: Node3D) -> void:
	if not dancer_viewport or not video_controls or not fullscreen_container:
		push_warning("Cannot enter fullscreen: missing references")
		return

	if is_fullscreen:
		return  # Already fullscreen

	current_dancer = dancer

	# Save previous viewport state
	prev_viewport_size = dancer_viewport.size
	prev_viewport_position = dancer_viewport.position

	# Show container
	fullscreen_container.visible = true

	# Resize viewport to fullscreen
	var screen_size = get_viewport().size
	dancer_viewport.position = Vector2.ZERO
	dancer_viewport.size = screen_size

	# Update VideoControls camera if needed
	if video_controls and video_controls.has_method("_update_camera"):
		video_controls._update_camera()

	is_fullscreen = true
	emit_signal("fullscreen_started")
	print("[FullscreenManager] Fullscreen started")

# ----------------------------
# Exit fullscreen
# ----------------------------
func exit_fullscreen() -> void:
	if not is_fullscreen or not dancer_viewport or not fullscreen_container:
		return

	# Restore viewport
	dancer_viewport.size = prev_viewport_size
	dancer_viewport.position = prev_viewport_position

	# Hide container
	fullscreen_container.visible = false

	is_fullscreen = false
	emit_signal("fullscreen_exited")
	print("[FullscreenManager] Fullscreen exited")

# ----------------------------
# Input handling
# ----------------------------
func handle_input(event: InputEvent) -> void:
	# Forward all events to VideoControls first
	if video_controls and video_controls.is_inside_tree() and video_controls.has_method("_input"):
		video_controls._input(event)

	# Hotkeys
	if event is InputEventKey and event.pressed:
		# Exit fullscreen hotkey
		if Input.is_action_just_pressed("exit_fullscreen"):
			exit_fullscreen()
			return

		# Dancer hotkeys
		if current_dancer and current_dancer.is_inside_tree():
			if current_dancer.has_method("replay_last_animation") and Input.is_action_just_pressed("replay_animation"):
				current_dancer.replay_last_animation()
			if current_dancer.has_method("pause_animation") and Input.is_action_just_pressed("pause_animation"):
				current_dancer.pause_animation()
			if current_dancer.has_method("resume_animation") and Input.is_action_just_pressed("play_animation"):
				current_dancer.resume_animation()
			if current_dancer.has_method("loop_current_animation") and Input.is_action_just_pressed("loop_animation"):
				current_dancer.loop_current_animation()
			if current_dancer.has_method("stop_animation") and Input.is_action_just_pressed("stop_animation"):
				current_dancer.stop_animation()
