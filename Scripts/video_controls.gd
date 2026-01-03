extends Control

# ----------------------------
# Tunables
# ----------------------------
@export var zoom_speed: float = 3.0
@export var zoom_min: float = 2.0
@export var zoom_max: float = 10.0

@export var orbit_speed_mouse: float = 0.01
@export var orbit_speed_keyboard: float = 1.8

@export var vertical_speed_mouse: float = 0.015
@export var vertical_speed_keyboard: float = 2.0
@export var vertical_min: float = -1.5
@export var vertical_max: float = 2.5

@export var default_distance: float = 5.0
@export var head_bone_name: String = "Head"

# ----------------------------
# Runtime state
# ----------------------------
var camera: Camera3D
var dancer: Node3D
var skel: Skeleton3D

var distance: float
var horizontal_angle: float
var vertical_offset: float
var pivot: Vector3

var dragging := false

# Home state
var home_distance: float
var home_horizontal_angle: float
var home_vertical_offset: float

# ----------------------------
# Ready
# ----------------------------
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	focus_mode = Control.FOCUS_ALL # ensures keyboard input always works
	set_process_input(true)

	$VideoControls/HContainerButtons/PauseContainer/Pause/PauseButton.pressed.connect(_on_pause_button_pressed)
	$VideoControls/HContainerButtons/ReplayContainer/Replay/ReplayButton.pressed.connect(replay_animation)

# ----------------------------
# Setup
# ----------------------------
func set_camera(cam: Camera3D) -> void:
	camera = cam

func set_active_dancer(dancer_node: Node3D) -> void:
	dancer = dancer_node
	skel = dancer.get_node_or_null("Skeleton3D") as Skeleton3D

	_update_pivot()

	distance = default_distance
	horizontal_angle = 0.0
	vertical_offset = 0.0

	_save_home_state()
	_update_camera()

# ----------------------------
# Home / Reset
# ----------------------------
func reset_camera() -> void:
	distance = home_distance
	horizontal_angle = home_horizontal_angle
	vertical_offset = home_vertical_offset
	_update_camera()

func _save_home_state() -> void:
	home_distance = distance
	home_horizontal_angle = horizontal_angle
	home_vertical_offset = vertical_offset

# ----------------------------
# Mouse input
# ----------------------------
func _gui_input(event: InputEvent) -> void:
	if camera == null or dancer == null:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			distance = clamp(distance - zoom_speed, zoom_min, zoom_max)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			distance = clamp(distance + zoom_speed, zoom_min, zoom_max)

	if event is InputEventMouseMotion and dragging:
		var dx: float = abs(event.relative.x)
		var dy: float = abs(event.relative.y)

		if dx >= dy:
			horizontal_angle -= event.relative.x * orbit_speed_mouse
		else:
			vertical_offset += -event.relative.y * vertical_speed_mouse
			vertical_offset = clamp(vertical_offset, vertical_min, vertical_max)

# ----------------------------
# Keyboard input
# ----------------------------
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		# Exit fullscreen
		if Input.is_action_pressed("exit_fullscreen"):
			_on_exit_button_pressed()

		# Replay last animation
		if Input.is_action_pressed("replay_animation") and dancer and dancer.has_method("replay_last_animation"):
			dancer.replay_last_animation()

		# Reset camera
		if Input.is_action_pressed("camera_reset"):
			reset_camera()
			
		# Pause animation with P key
		if Input.is_action_pressed("pause_animation") and dancer and dancer.has_method("toggle_pause_or_resume"):
			dancer.toggle_pause_or_resume()
			grab_focus() # make sure keyboard input keeps working

# ----------------------------
# Update loop
# ----------------------------
func _process(delta: float) -> void:
	if camera == null or dancer == null:
		return

	# Keyboard movement (continuous)
	if Input.is_action_pressed("camera_left"):
		horizontal_angle += orbit_speed_keyboard * delta
	if Input.is_action_pressed("camera_right"):
		horizontal_angle -= orbit_speed_keyboard * delta
	if Input.is_action_pressed("camera_up"):
		vertical_offset += vertical_speed_keyboard * delta
	if Input.is_action_pressed("camera_down"):
		vertical_offset -= vertical_speed_keyboard * delta
	if Input.is_action_pressed("zoom_in"):
		distance -= zoom_speed * delta
	if Input.is_action_pressed("zoom_out"):
		distance += zoom_speed * delta

	distance = clamp(distance, zoom_min, zoom_max)
	vertical_offset = clamp(vertical_offset, vertical_min, vertical_max)

	_update_camera()

# ----------------------------
# Camera math
# ----------------------------
func _update_pivot() -> void:
	if skel != null and skel.has_bone(head_bone_name):
		var idx := skel.find_bone(head_bone_name)
		pivot = skel.get_bone_global_pose(idx).origin
	else:
		pivot = dancer.global_position + Vector3(0.0, 1.6, 0.0)

func _update_camera() -> void:
	_update_pivot()
	var horizontal_offset := Vector3(0.0, 0.0, distance).rotated(Vector3.UP, horizontal_angle)
	camera.global_position = pivot + horizontal_offset + Vector3(0.0, vertical_offset, 0.0)
	camera.look_at(Vector3(pivot.x, camera.global_position.y, pivot.z), Vector3.UP)

# ----------------------------
# Replay
# ----------------------------
func replay_animation() -> void:
	if dancer == null or not dancer.has_method("replay_last_animation"):
		push_warning("No active dancer or dancer cannot replay animation.")
		return

	dancer.replay_last_animation()
	grab_focus() # restore keyboard focus

# ----------------------------
# Pause
# ----------------------------
func _on_pause_button_pressed() -> void:
	if dancer and dancer.has_method("toggle_pause_or_resume"):
		dancer.toggle_pause_or_resume()
		grab_focus() # restore keyboard focus

# ----------------------------
# Exit
# ----------------------------
func _on_exit_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/main_scene.tscn")
