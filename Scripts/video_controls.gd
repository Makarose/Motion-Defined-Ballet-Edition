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
	# Button connections (safe, Godot 4 syntax)
	# ----------------------------
	var pause_btn = $VideoControls/VContainerButtons/PauseContainer/Pause/PauseButton
	if pause_btn != null:
		var pause_callable := Callable(self, "_on_pause_button_pressed")
		if not pause_btn.is_connected("pressed", pause_callable):
			pause_btn.pressed.connect(pause_callable)

	var replay_btn = $VideoControls/VContainerButtons/ReplayContainer/Replay/ReplayButton
	if replay_btn != null:
		print("Replay button found, connecting...")
		var replay_callable := Callable(self, "_on_replay_button_pressed")
		if not replay_btn.is_connected("pressed", replay_callable):
			replay_btn.pressed.connect(replay_callable)


	var male_btn = $VBoxContainer/MaleButton/MaleButton
	if male_btn != null:
		var male_callable := Callable(self, "_on_male_button_pressed")
		if not male_btn.is_connected("pressed", male_callable):
			male_btn.pressed.connect(male_callable)

	var female_btn = $VBoxContainer/FemaleButton/FemaleButton
	if female_btn != null:
		var female_callable := Callable(self, "_on_female_button_pressed")
		if not female_btn.is_connected("pressed", female_callable):
			female_btn.pressed.connect(female_callable)

	var stop_btn = $VideoControls/VContainerButtons/StopContainer/Stop/StopButton
	if stop_btn != null:
		var stop_callable := Callable(self, "_on_stop_button_pressed")
		if not stop_btn.is_connected("pressed", stop_callable):
			stop_btn.pressed.connect(stop_callable)

	# ----------------------------
	# Scrub slider connections (guarded)
	# ----------------------------
	if scrub_slider != null:
		if not scrub_slider.is_connected("value_changed", Callable(self, "_on_scrub_changed")):
			scrub_slider.value_changed.connect(_on_scrub_changed)
		if not scrub_slider.is_connected("drag_started", Callable(self, "_on_scrub_started")):
			scrub_slider.drag_started.connect(_on_scrub_started)
		if not scrub_slider.is_connected("drag_ended", Callable(self, "_on_scrub_ended")):
			scrub_slider.drag_ended.connect(_on_scrub_ended)

# ----------------------------
# Setup
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
		dancer.call_deferred("apply_playback_state", {
			"animation": DancerState.current_animation,
			"time": DancerState.animation_time,
			"is_paused": not DancerState.is_playing
		})

	# TBS: setup slider to match animation
	_setup_scrub_slider()

# ----------------------------
# Setup scrub slider (TBS)
# ----------------------------
func _setup_scrub_slider():
	if dancer != null and dancer.has_method("get_playback_state"):
		var state = dancer.get_playback_state()
		if state.has("length") and state.length > 0.0:
			scrub_slider.min_value = 0
			scrub_slider.max_value = state.length
			scrub_slider.value = state.time

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
	if camera == null or dancer == null or scrub_active:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				distance = clamp(distance - mouse_zoom_step, zoom_min, zoom_max)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				distance = clamp(distance + mouse_zoom_step, zoom_min, zoom_max)

	if event is InputEventMouseMotion and dragging:
		var dx: float = abs(event.relative.x)
		var dy: float = abs(event.relative.y)

		if dx > dy:
			horizontal_angle -= event.relative.x * mouse_orbit_speed
		else:
			vertical_offset += -event.relative.y * mouse_vertical_speed
			vertical_offset = clamp(vertical_offset, vertical_min, vertical_max)

# ----------------------------
# Keyboard Input
# ----------------------------
func _input(event: InputEvent) -> void:
	if dancer == null or not dancer.is_inside_tree():
		return

	if Input.is_action_just_pressed("exit_fullscreen"):
		_on_exit_button_pressed()

	if Input.is_action_just_pressed("replay_animation") and dancer.has_method("replay_last_animation"):
		print("Keyboard: replay_animation pressed")
		dancer.replay_last_animation()

	if Input.is_action_just_pressed("pause_animation") and dancer.has_method("toggle_pause_or_resume"):
		print("Keyboard: pause_animation pressed")
		dancer.toggle_pause_or_resume()
		grab_focus()

	if Input.is_action_just_pressed("play_animation") and dancer.has_method("resume_from_scrub"):
		print("Keyboard: play_animation pressed")
		dancer.resume_from_scrub()
		grab_focus()

	if Input.is_action_just_pressed("stop_animation") and dancer.has_method("stop_animation"):
		print("Keyboard: stop_animation pressed")
		dancer.stop_animation()
		grab_focus()

# ----------------------------
# Update loop (TBS: clean slider handling)
# ----------------------------
func _process(delta: float) -> void:
	if camera == null or dancer == null:
		return

	# Camera controls
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

	if scrub_slider != null and not scrub_active and dancer.has_method("get_playback_state"):
		var state: Dictionary = dancer.get_playback_state()
		if state.has("length") and state.length > 0.0:
			# Just update the slider value
			scrub_slider.value = state.time
			#print("Slider updated to ", state.time)  # optional debug

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
# Character buttons
# ----------------------------
func _on_male_button_pressed() -> void:
	emit_signal("character_requested", "res://Scenes/male.tscn")

func _on_female_button_pressed() -> void:
	emit_signal("character_requested", "res://Scenes/female.tscn")
	
# ----------------------------
# Video buttons with debug
# ----------------------------	
func _on_pause_button_pressed() -> void:
	print("Pause button pressed")
	if dancer != null:
		print("Dancer exists")
		if dancer.has_method("pause_animation"):
			print("Calling pause_animation")
			dancer.pause_animation()
		else:
			print("Dancer missing pause_animation method")
	else:
		print("No dancer assigned")

func _on_play_button_pressed() -> void:
	print("Play button pressed")
	if dancer != null:
		print("Dancer exists")
		if dancer.has_method("resume_from_scrub"):
			print("Calling resume_from_scrub")
			dancer.resume_from_scrub()
		else:
			print("Dancer missing resume_from_scrub method")
	else:
		print("No dancer assigned")

func _on_replay_button_pressed() -> void:
	print("Replay button pressed")
	if dancer != null and dancer.has_method("replay_last_animation"):
		dancer.replay_last_animation()


func _on_loop_button_pressed() -> void:
	print("Loop button pressed")
	if dancer == null:
		print("Dancer missing")
		return
	if dancer.has_method("loop_current_animation"):
		print("Calling loop_current_animation")
		dancer.loop_current_animation()
	else:
		print("Dancer missing loop_current_animation method")


func _on_stop_button_pressed() -> void:
	print("Stop button pressed")
	if dancer != null:
		print("Dancer exists")
		if dancer.has_method("stop_animation"):
			print("Calling stop_animation")
			dancer.stop_animation()
		else:
			print("Dancer missing stop_animation method")
	else:
		print("No dancer assigned")

# ----------------------------
# Scrub slider
# ----------------------------
func _on_scrub_started() -> void:
	scrub_active = true
	DancerState.scrub_active = true
	was_playing_before_scrub = DancerState.is_playing

	print("Scrub started at ", DancerState.animation_time)




func _on_scrub_changed(value: float) -> void:
	if dancer != null and dancer.has_method("seek_to_time"):
		dancer.seek_to_time(value)
		#print("Slider moved to ", value)  # optional debug

func _on_scrub_ended(_value_changed: bool) -> void:
	scrub_active = false
	DancerState.scrub_active = false

	if dancer == null:
		print("Scrub ended, dancer missing")
		return

	if was_playing_before_scrub:
		print("Resuming from scrub")
		dancer.resume_from_scrub()
	else:
		print("Scrub ended, staying paused")



# ----------------------------
# Exit
# ----------------------------
func _on_exit_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/main_scene.tscn")
