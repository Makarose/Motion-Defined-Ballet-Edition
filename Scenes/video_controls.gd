extends Control

# -----------------------------------------
# Nodes
# -----------------------------------------
@onready var camera: Camera3D = null
@onready var dancer: Node3D = null
@onready var zoom_slider: Slider = $ZoomSlider

# -----------------------------------------
# Settings
# -----------------------------------------
@export var zoom_min: float = 2.0
@export var zoom_max: float = 15.0
@export var zoom_default: float = 5.0
@export var zoom_smooth_speed: float = 5.0  # Higher = faster smoothing
@export var zoom_step: float = 0.5          # Step per mouse wheel tick

var current_distance: float = 5.0
var target_distance: float = 5.0

# -----------------------------------------
# Bone tracking
# -----------------------------------------
var target_bone_name: String = ""
var target_bone_index: int = -1
var target_bone_node: Node3D = null
var skel: Skeleton3D = null

# -----------------------------------------
# Ready
# -----------------------------------------
func _ready() -> void:
	print("[VC] _ready called")
	
	if zoom_slider:
		zoom_slider.min_value = zoom_min
		zoom_slider.max_value = zoom_max
		zoom_slider.value = zoom_default
		current_distance = zoom_default
		target_distance = zoom_default
		zoom_slider.value_changed.connect(_on_zoom_slider_value_changed)
		print("[VC] Zoom slider connected, initial value:", zoom_default)
	else:
		print("[VC] Zoom slider NOT found")
	
	# Make sure this Control receives input
	focus_mode = Control.FOCUS_ALL

# -----------------------------------------
# Assign bone by name
# -----------------------------------------
func set_target_bone(bone_name: String) -> void:
	if not dancer:
		print("[VC] No dancer assigned yet!")
		return
	
	skel = dancer.get_node_or_null("Skeleton3D")
	if not skel:
		print("[VC] Skeleton3D node not found in dancer!")
		return
	
	target_bone_name = bone_name
	target_bone_index = skel.find_bone(bone_name)
	if target_bone_index == -1:
		print("[VC] Bone not found in skeleton:", bone_name)
		target_bone_node = null
	else:
		target_bone_node = dancer
		print("[VC] Target bone set:", bone_name, "index:", target_bone_index)

# -----------------------------------------
# Central zoom setter
# -----------------------------------------
func set_zoom(distance: float) -> void:
	target_distance = clamp(distance, zoom_min, zoom_max)
	
	if zoom_slider:
		zoom_slider.value = target_distance
	print("[VC] Target zoom set to:", target_distance)

# -----------------------------------------
# Focus & zoom camera on bone
# -----------------------------------------
func focus_and_zoom_on_bone(bone_name: String, distance: float) -> void:
	if not skel:
		print("[VC] Skeleton not assigned yet, cannot focus.")
		return
	
	var idx = skel.find_bone(bone_name)
	if idx == -1:
		print("[VC] Bone not found:", bone_name)
		return
	
	target_bone_index = idx
	target_bone_name = bone_name
	target_bone_node = dancer
	set_zoom(distance)

# -----------------------------------------
# Slider callback
# -----------------------------------------
func _on_zoom_slider_value_changed(value: float) -> void:
	set_zoom(value)

# -----------------------------------------
# Reset zoom
# -----------------------------------------
func reset_zoom() -> void:
	set_zoom(zoom_default)
	print("[VC] Zoom reset to default:", zoom_default)

# -----------------------------------------
# Process: smooth zoom interpolation
# -----------------------------------------
func _process(delta: float) -> void:
	if skel and target_bone_index != -1 and camera:
		# Smoothly move current distance toward target distance
		current_distance = lerp(current_distance, target_distance, zoom_smooth_speed * delta)
		
		var bone_pos: Vector3 = skel.get_bone_global_pose(target_bone_index).origin
		var dir: Vector3 = (camera.global_transform.origin - bone_pos).normalized()
		camera.global_transform.origin = bone_pos + dir * current_distance
		camera.look_at(bone_pos, Vector3.UP)

# -----------------------------------------
# Mouse wheel zoom input
# -----------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and zoom_slider:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			set_zoom(zoom_slider.value - zoom_step)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			set_zoom(zoom_slider.value + zoom_step)
