# ----------------------------
# video_controls.gd
# ----------------------------
extends Control

# ----------------------------
# Signals emitted up to FullscreenScene
# ----------------------------
signal exit_requested
signal character_requested(scene_path: String)

# ----------------------------
# Nodes
# ----------------------------
@onready var pause_button: TextureButton = $VideoControlsButtonContainer/VContainerButtons/PauseContainer/Pause/PauseButton
@onready var play_button: TextureButton = $VideoControlsButtonContainer/VContainerButtons/PlayContainer/Play/PlayButton
@onready var replay_button: TextureButton = $VideoControlsButtonContainer/VContainerButtons/ReplayContainer/Replay/ReplayButton
@onready var loop_button: TextureButton = $VideoControlsButtonContainer/VContainerButtons/LoopContainer/Loop/LoopButton
@onready var stop_button: TextureButton = $VideoControlsButtonContainer/VContainerButtons/StopContainer/Stop/StopButton
@onready var exit_button: TextureButton = $VideoControlsButtonContainer/VContainerButtons/ExitContainer/Exit/ExitButton
@onready var male_button: Button = $CharacterButtonContainer/MaleButton/MaleButton
@onready var female_button: Button = $CharacterButtonContainer/FemaleButton/FemaleButton
@onready var scrub_slider: HSlider = $SliderContainer/ScrubSlider

# ----------------------------
# Camera tunables
# ----------------------------
@export var orbit_speed: float = 1.5
@export var vertical_speed: float = 1.5
@export var mouse_orbit_speed: float = 0.015
@export var mouse_vertical_speed: float = 0.015
@export var zoom_speed: float = 1.5
@export var mouse_zoom_step: float = 0.6
@export var zoom_min: float = 2.0
@export var zoom_max: float = 10.0
@export var vertical_min: float = -1.5
@export var vertical_max: float = 2.5
@export var default_distance: float = 5.0

# ----------------------------
# Runtime state
# ----------------------------
var camera: Camera3D = null
var dancer: Node3D = null
var distance: float = 5.0
var horizontal_angle: float = 0.0
var vertical_offset: float = 0.0
var pivot: Vector3 = Vector3.ZERO
var dragging: bool = false
var drag_axis: String = ""
var last_mouse_pos: Vector2 = Vector2.ZERO
var scrub_active: bool = false
var was_playing_before_scrub: bool = false

# Home state for camera reset
var home_distance: float = 5.0
var home_horizontal_angle: float = 0.0
var home_vertical_offset: float = 0.0

# ----------------------------
# Ready
# ----------------------------
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	focus_mode = Control.FOCUS_ALL

	# Wire up buttons
	pause_button.pressed.connect(_on_pause_pressed)
	play_button.pressed.connect(_on_play_pressed)
	replay_button.pressed.connect(_on_replay_pressed)
	loop_button.pressed.connect(_on_loop_pressed)
	stop_button.pressed.connect(_on_stop_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	male_button.pressed.connect(_on_male_pressed)
	female_button.pressed.connect(_on_female_pressed)

	# Wire up scrub slider
	scrub_slider.drag_started.connect(_on_scrub_started)
	scrub_slider.value_changed.connect(_on_scrub_changed)
	scrub_slider.drag_ended.connect(_on_scrub_ended)
	scrub_slider.min_value = 0.0
	scrub_slider.value = 0.0


# ----------------------------
# Set active dancer
# Called by FullscreenScene.set_dancer()
# ----------------------------
func set_dancer(dancer_node: Node3D) -> void:
	dancer = dancer_node

	# Find camera via known path in fullscreen scene
	camera = get_node_or_null("../SubViewportContainer/DancerViewport/Background/Camera3D")

	# Setup camera position
	_update_pivot()
	distance = default_distance
	horizontal_angle = 0.0
	vertical_offset = 0.0
	_save_home_state()
	_update_camera()

	# Setup scrub slider from current animation state
	_setup_scrub_slider()

	print("[VideoControls] Dancer set:", dancer.name)


# ----------------------------
# Setup scrub slider from dancer's current animation
# ----------------------------
func _setup_scrub_slider() -> void:
	if dancer == null:
		return

	var state: Dictionary = dancer.get_playback_state()
	var length: float = state.get("length", 0.0)

	if length > 0.0:
		scrub_slider.max_value = length
		scrub_slider.value = state.get("time", 0.0)
		print("[VideoControls] Scrub slider set, length:", length)
	else:
		scrub_slider.max_value = 1.0
		scrub_slider.value = 0.0
		print("[VideoControls] No animation length yet")


# ----------------------------
# Scrub bar handlers
# ----------------------------
func _on_scrub_started() -> void:
	scrub_active = true
	if dancer != null:
		var state = dancer.get_playback_state()
		was_playing_before_scrub = not state.get("is_paused", false)
		dancer.pause_animation()

func _on_scrub_changed(value: float) -> void:
	if dancer != null and scrub_active:
		dancer.seek_to_time(value)

func _on_scrub_ended(_value_changed: bool = false) -> void:
	scrub_active = false
	if dancer != null and was_playing_before_scrub:
		dancer.resume_animation()


# ----------------------------
# Playback button handlers
# ----------------------------
func _on_pause_pressed() -> void:
	if dancer != null:
		dancer.pause_animation()

func _on_play_pressed() -> void:
	if dancer != null:
		dancer.resume_animation()

func _on_replay_pressed() -> void:
	if dancer != null:
		dancer.replay_last_animation()
		scrub_slider.value = 0.0
		_setup_scrub_slider()

func _on_loop_pressed() -> void:
	if dancer != null:
		dancer.loop_current_animation()

func _on_stop_pressed() -> void:
	if dancer != null:
		dancer.stop_animation()
		scrub_slider.value = 0.0

func _on_exit_pressed() -> void:
	emit_signal("exit_requested")


# ----------------------------
# Character swap handlers
# ----------------------------
func _on_male_pressed() -> void:
	emit_signal("character_requested", "res://Scenes/male.tscn")

func _on_female_pressed() -> void:
	emit_signal("character_requested", "res://Scenes/female.tscn")


# ----------------------------
# Camera helpers
# ----------------------------
func _update_pivot() -> void:
	if dancer == null:
		return
	var skel: Skeleton3D = dancer.get_node_or_null("Skeleton3D")
	if skel:
		var head_idx = skel.find_bone("Head")
		if head_idx >= 0:
			pivot = skel.get_bone_global_pose(head_idx).origin
			return
	pivot = dancer.global_transform.origin

func _update_camera() -> void:
	if camera == null or dancer == null:
		return

	var cam_pos := pivot + Vector3(
		sin(horizontal_angle) * distance,
		vertical_offset + 0.5,
		cos(horizontal_angle) * distance
	)

	camera.global_transform.origin = cam_pos
	camera.look_at(Vector3(pivot.x, cam_pos.y, pivot.z), Vector3.UP)

func _save_home_state() -> void:
	home_distance = distance
	home_horizontal_angle = horizontal_angle
	home_vertical_offset = vertical_offset

func reset_camera() -> void:
	distance = home_distance
	horizontal_angle = home_horizontal_angle
	home_vertical_offset = vertical_offset
	_update_camera()


# ----------------------------
# Mouse input for camera orbit and zoom
# ----------------------------
func _gui_input(event: InputEvent) -> void:
	if camera == null or dancer == null:
		return

	# Don't orbit if mouse is over scrub slider
	if scrub_slider.get_global_rect().has_point(get_global_mouse_position()):
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed
			drag_axis = ""
			if event.pressed:
				last_mouse_pos = event.position

		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				distance = clamp(distance - mouse_zoom_step, zoom_min, zoom_max)
				_update_camera()
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				distance = clamp(distance + mouse_zoom_step, zoom_min, zoom_max)
				_update_camera()

	if event is InputEventMouseMotion and dragging:
		var delta: Vector2 = event.position - last_mouse_pos

		if drag_axis == "":
			drag_axis = "horizontal" if abs(delta.x) > abs(delta.y) else "vertical"

		if drag_axis == "horizontal":
			horizontal_angle -= delta.x * mouse_orbit_speed
		elif drag_axis == "vertical":
			vertical_offset -= delta.y * mouse_vertical_speed
			vertical_offset = clamp(vertical_offset, vertical_min, vertical_max)

		last_mouse_pos = event.position
		_update_camera()


# ----------------------------
# Keyboard input
# ----------------------------
func _input(event: InputEvent) -> void:
	if not visible:
		return

	# Consume left/right so GameManager nav doesn't fire in fullscreen
	if event.is_action("ui_left") or event.is_action("ui_right"):
		get_viewport().set_input_as_handled()

	if Input.is_action_just_pressed("camera_reset"):
		reset_camera()

	if Input.is_action_just_pressed("exit_fullscreen"):
		emit_signal("exit_requested")

	if dancer == null:
		return

	if Input.is_action_just_pressed("replay_animation"):
		dancer.replay_last_animation()
	if Input.is_action_just_pressed("pause_animation"):
		dancer.pause_animation()
	if Input.is_action_just_pressed("play_animation"):
		dancer.resume_animation()
	if Input.is_action_just_pressed("loop_animation"):
		dancer.loop_current_animation()
	if Input.is_action_just_pressed("stop_animation"):
		dancer.stop_animation()
	if Input.is_action_just_pressed("male_button"):
		_on_male_pressed()
	if Input.is_action_just_pressed("female_button"):
		_on_female_pressed()


# ----------------------------
# Process — camera controls and scrub bar update
# ----------------------------
func _process(delta: float) -> void:
	if not visible or camera == null or dancer == null:
		return

	# Keyboard camera controls
	if Input.is_action_pressed("camera_left"):
		horizontal_angle += orbit_speed * delta
	if Input.is_action_pressed("camera_right"):
		horizontal_angle -= orbit_speed * delta
	if Input.is_action_pressed("camera_up"):
		vertical_offset += vertical_speed * delta
	if Input.is_action_pressed("camera_down"):
		vertical_offset -= vertical_speed * delta
	if Input.is_action_pressed("zoom_in"):
		distance -= zoom_speed * delta
	if Input.is_action_pressed("zoom_out"):
		distance += zoom_speed * delta

	distance = clamp(distance, zoom_min, zoom_max)
	vertical_offset = clamp(vertical_offset, vertical_min, vertical_max)
	_update_camera()

	# Update scrub slider position in real time
	if not scrub_active:
		var state = dancer.get_playback_state()
		var current_time = state.get("time", 0.0)
		var length = state.get("length", 0.0)
		if length > 0.0 and scrub_slider.max_value != length:
			scrub_slider.max_value = length
		scrub_slider.value = current_time
