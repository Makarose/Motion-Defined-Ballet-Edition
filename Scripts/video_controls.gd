# ----------------------------
# video_controls.gd
# ----------------------------


extends Control

signal character_requested(character_scene_path: String)

@onready var scrub_slider: HSlider = $ScrubSlider

# ----------------------------
# Camera / Dancer Tunables
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
var scrub_active: bool = false
var was_playing_before_scrub: bool = false

# Mouse drag state (NEW)
var drag_axis: String = ""   # "horizontal" or "vertical"
var last_mouse_pos: Vector2

# Home state
var home_distance: float
var home_horizontal_angle: float
var home_vertical_offset: float

# ----------------------------
# Ready
# ----------------------------
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	focus_mode = Control.FOCUS_ALL
	set_process_input(true)

# ----------------------------
# Setup dancer and camera
# ----------------------------
func set_camera(cam: Camera3D) -> void:
	camera = cam

func set_active_dancer(dancer_node: Node3D) -> void:
	if dancer != null and dancer.is_inside_tree():
		dancer.queue_free()

	dancer = dancer_node
	skel = dancer.get_node_or_null("Skeleton3D") as Skeleton3D

	_update_pivot()
	distance = default_distance
	horizontal_angle = 0.0
	vertical_offset = 0.0

	_save_home_state()
	_update_camera()

	if dancer.has_method("apply_playback_state"):
		var state: Dictionary = {
			"animation": DancerState.current_animation,
			"time": DancerState.animation_time,
			"is_paused": not DancerState.is_playing,
			"is_looping": DancerState.is_looping
		}
		dancer.call_deferred("apply_playback_state", state)

	_setup_scrub_slider()

# ----------------------------
# Scrub slider
# ----------------------------
func _setup_scrub_slider() -> void:
	if dancer != null and dancer.has_method("get_playback_state"):
		var state: Dictionary = dancer.get_playback_state()
		if state.has("length") and state["length"] > 0.0:
			scrub_slider.min_value = 0
			scrub_slider.max_value = state["length"]
			scrub_slider.value = state["time"]

func _on_scrub_started() -> void:
	scrub_active = true
	if dancer != null:
		was_playing_before_scrub = DancerState.is_playing
		DancerState.scrub_active = true

func _on_scrub_changed(value: float) -> void:
	if dancer != null and scrub_active and dancer.has_method("seek_to_time"):
		dancer.seek_to_time(value)

func _on_scrub_ended() -> void:
	scrub_active = false
	if dancer != null:
		DancerState.scrub_active = false
		if was_playing_before_scrub and dancer.has_method("resume_from_scrub"):
			dancer.resume_from_scrub()

# ----------------------------
# Camera helpers
# ----------------------------
func _update_pivot() -> void:
	if skel == null:
		return
	var head_bone_idx = skel.find_bone(head_bone_name)
	if head_bone_idx >= 0:
		pivot = skel.global_transform.origin
	else:
		pivot = skel.global_transform.origin

func _update_camera() -> void:
	if camera == null:
		return

	var cam_position := pivot + Vector3(
		sin(horizontal_angle) * distance,
		vertical_offset,
		cos(horizontal_angle) * distance
	)

	camera.global_transform.origin = cam_position

	# Look at dancer horizontally ONLY (no vertical pivot)
	var look_target := Vector3(
		pivot.x,
		cam_position.y,
		pivot.z
	)

	camera.look_at(look_target, Vector3.UP)



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
# Input
# ----------------------------
func _gui_input(event: InputEvent) -> void:
	if camera == null or dancer == null or scrub_active:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = true
				drag_axis = ""
				last_mouse_pos = event.position
			else:
				dragging = false
				drag_axis = ""

		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				distance = clamp(distance - mouse_zoom_step, zoom_min, zoom_max)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				distance = clamp(distance + mouse_zoom_step, zoom_min, zoom_max)

	if event is InputEventMouseMotion and dragging:
		var delta: Vector2 = event.position - last_mouse_pos

		# Decide dominant axis once per drag
		if drag_axis == "":
			if abs(delta.x) > abs(delta.y):
				drag_axis = "horizontal"
			elif abs(delta.y) > abs(delta.x):
				drag_axis = "vertical"

		if drag_axis == "horizontal":
			horizontal_angle -= delta.x * mouse_orbit_speed

		elif drag_axis == "vertical":
			vertical_offset -= delta.y * mouse_vertical_speed
			vertical_offset = clamp(vertical_offset, vertical_min, vertical_max)

		last_mouse_pos = event.position
		_update_camera()

func _input(event: InputEvent) -> void:
	if dancer == null or not dancer.is_inside_tree():
		return

	if Input.is_action_just_pressed("exit_fullscreen"):
		_on_exit_button_pressed()

	if Input.is_action_just_pressed("replay_animation") and dancer.has_method("replay_last_animation"):
		dancer.replay_last_animation()

	if Input.is_action_just_pressed("pause_animation") and dancer.has_method("pause_animation"):
		dancer.pause_animation()
		grab_focus()

	if Input.is_action_just_pressed("play_animation") and dancer.has_method("resume_animation"):
		dancer.resume_animation()
		grab_focus()

	if Input.is_action_just_pressed("loop_animation") and dancer.has_method("loop_current_animation"):
		dancer.loop_current_animation()
		grab_focus()

	if Input.is_action_just_pressed("stop_animation") and dancer.has_method("stop_animation"):
		dancer.stop_animation()
		grab_focus()

# ----------------------------
# Button handlers
# ----------------------------
func _on_pause_button_pressed() -> void:
	if dancer != null and dancer.has_method("pause_animation"):
		dancer.pause_animation()

func _on_replay_button_pressed() -> void:
	if dancer != null and dancer.has_method("replay_last_animation"):
		dancer.replay_last_animation()

func _on_play_button_pressed() -> void:
	if dancer != null and dancer.has_method("resume_animation"):
		dancer.resume_animation()

func _on_loop_button_pressed() -> void:
	if dancer != null and dancer.has_method("loop_current_animation"):
		dancer.loop_current_animation()

func _on_stop_button_pressed() -> void:
	if dancer != null and dancer.has_method("stop_animation"):
		dancer.stop_animation()

func _on_exit_button_pressed() -> void:
	if get_tree().current_scene != null:
		get_tree().current_scene.free()
	get_tree().change_scene_to_file("res://Scenes/main_scene.tscn")

func _on_music_button_pressed() -> void:
	pass

func _on_male_button_pressed() -> void:
	pass

func _on_female_button_pressed() -> void:
	pass

# ----------------------------
# Main loop
# ----------------------------
func _process(delta: float) -> void:
	if camera == null or dancer == null:
		return

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
